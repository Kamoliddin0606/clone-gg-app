// =============================================================================
// PermissionGate
// =============================================================================
//
// Blocking gate that wraps the entire app. Until the device has:
//   1) Location permission (whileInUse or always)
//   2) Background location permission (locationAlways) — Android 10+
//   3) GPS / location services enabled
//   4) Notification permission
// granted, the user sees a full-screen "permissions required" page and the
// real app is not rendered. Re-checks on every `AppLifecycleState.resumed`
// so revoking a permission via system settings re-blocks the app the moment
// the user comes back.
//
// Android 10+ contract: foreground (whileInUse) and background (always)
// location permissions MUST be requested separately, with whileInUse
// granted FIRST. The OS rejects an `Always` request unless `WhenInUse` is
// already granted — and on Android 11+ the user can only grant `Always`
// from the system settings page, not from an in-app dialog.
//
// Performance contract:
//   * The three checks run in parallel via `Future.wait` — each is a single
//     native call (sub-millisecond on warm cache).
//   * Once `_allGranted` is true, `build()` returns `widget.child` directly
//     with no decorating widgets, so steady-state overhead is zero.
//   * There is NO polling, NO periodic timer, NO listener fan-out. Re-checks
//     happen only on init and on resume.
//   * A `_isRechecking` mutex prevents overlapping checks if multiple resume
//     events fire in quick succession (e.g. the OS permission dialog flow).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

/// Logical identity of each gate requirement. Used to drive the
/// list-tile rows in the blocking UI without string comparisons.
enum _ReqId { location, backgroundLocation, gps, notification }

/// Snapshot of one requirement at a point in time.
class _ReqStatus {
  final _ReqId id;
  final bool granted;
  final bool permanentlyDenied;
  const _ReqStatus(this.id,
      {this.granted = false, this.permanentlyDenied = false});
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  // Initial-check sentinel — kept false until the first parallel check
  // completes, so we don't flash the blocking UI before knowing the
  // real state of permissions.
  bool _ready = false;
  bool _allGranted = false;

  // Reentrancy guard — Geolocator's permission dialog flips the app to
  // `inactive` and then `resumed`, which would otherwise re-enter
  // _recheck while it's still running.
  bool _isRechecking = false;

  // True once we've auto-triggered the OS request flow after the very
  // first check. Subsequent resumes only re-check; they don't re-pop
  // dialogs. The user can always retry via the on-screen button.
  bool _autoTriggered = false;

  _ReqStatus _location = const _ReqStatus(_ReqId.location);
  _ReqStatus _backgroundLocation =
      const _ReqStatus(_ReqId.backgroundLocation);
  _ReqStatus _gps = const _ReqStatus(_ReqId.gps);
  _ReqStatus _notification = const _ReqStatus(_ReqId.notification);

  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer to post-frame so first paint is not blocked by native calls.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recheckAndMaybePrompt());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only `resumed` matters — a user returning from system settings
    // could have just granted or revoked a permission. We re-check
    // silently (no auto-prompt) and let the gate update its visible
    // state.
    if (state == AppLifecycleState.resumed) {
      _recheck();
    }
  }

  // ---------------------------------------------------------------------------
  // CHECK PIPELINE
  // ---------------------------------------------------------------------------

  Future<void> _recheckAndMaybePrompt() async {
    await _recheck();
    if (!mounted) return;
    // First time we see the gate with anything missing, kick off the
    // OS request flow automatically. From then on the user drives
    // retries via the "Ruxsat berish" button.
    if (!_allGranted && !_autoTriggered) {
      _autoTriggered = true;
      // Run without awaiting — `_requestAll` will trigger its own
      // re-check at the end.
      // ignore: unawaited_futures
      _requestAll();
    }
  }

  Future<void> _recheck() async {
    if (_isRechecking) return;
    _isRechecking = true;
    try {
      // Hard timeout so a misbehaving platform channel cannot freeze
      // the gate. 1.5 s is *very* generous — real checks return in
      // single-digit ms. If we time out, we keep the prior cached
      // state (e.g. previously granted) rather than flipping to
      // "missing", because flipping based on a transient platform
      // hiccup would unnecessarily block the user with the gate
      // screen.
      final results = await Future.wait<_ReqStatus>([
        _checkLocation(),
        _checkBackgroundLocation(),
        _checkGps(),
        _checkNotification(),
      ]).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () =>
            [_location, _backgroundLocation, _gps, _notification],
      );

      if (!mounted) return;

      final nextLocation = results[0];
      final nextBackgroundLocation = results[1];
      final nextGps = results[2];
      final nextNotification = results[3];
      final nextAllGranted = nextLocation.granted &&
          nextBackgroundLocation.granted &&
          nextGps.granted &&
          nextNotification.granted;

      // Diff-based setState: if absolutely nothing changed since the
      // last check, skip the rebuild. Resume → recheck → same state
      // → no-op fires for the common case (user just briefly
      // backgrounded the app). Saves an entire rebuild of the route
      // tree.
      final unchanged = _ready &&
          nextAllGranted == _allGranted &&
          nextLocation.granted == _location.granted &&
          nextLocation.permanentlyDenied == _location.permanentlyDenied &&
          nextBackgroundLocation.granted == _backgroundLocation.granted &&
          nextBackgroundLocation.permanentlyDenied ==
              _backgroundLocation.permanentlyDenied &&
          nextGps.granted == _gps.granted &&
          nextNotification.granted == _notification.granted &&
          nextNotification.permanentlyDenied == _notification.permanentlyDenied;
      if (unchanged) return;

      setState(() {
        _location = nextLocation;
        _backgroundLocation = nextBackgroundLocation;
        _gps = nextGps;
        _notification = nextNotification;
        _allGranted = nextAllGranted;
        _ready = true;
      });
    } finally {
      _isRechecking = false;
    }
  }

  Future<_ReqStatus> _checkLocation() async {
    try {
      final p = await Geolocator.checkPermission();
      return _ReqStatus(
        _ReqId.location,
        granted: p == LocationPermission.always ||
            p == LocationPermission.whileInUse,
        permanentlyDenied: p == LocationPermission.deniedForever,
      );
    } catch (_) {
      return const _ReqStatus(_ReqId.location);
    }
  }

  /// Background ("Always") location permission check.
  ///
  /// On Android 10+ this is a separate runtime permission
  /// (`ACCESS_BACKGROUND_LOCATION`). Without it, location updates
  /// stop when the app is no longer in the foreground — even if
  /// `whileInUse` is granted. On iOS this maps to the "Always" tier
  /// of the location prompt.
  ///
  /// We intentionally do NOT block on this for Android < 10 where
  /// `whileInUse` already covers background access; in that case
  /// the permission API returns granted automatically.
  Future<_ReqStatus> _checkBackgroundLocation() async {
    try {
      final status = await Permission.locationAlways.status;
      return _ReqStatus(
        _ReqId.backgroundLocation,
        granted: status.isGranted,
        permanentlyDenied: status.isPermanentlyDenied,
      );
    } catch (_) {
      return const _ReqStatus(_ReqId.backgroundLocation);
    }
  }

  Future<_ReqStatus> _checkGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      return _ReqStatus(_ReqId.gps, granted: enabled);
    } catch (_) {
      return const _ReqStatus(_ReqId.gps);
    }
  }

  Future<_ReqStatus> _checkNotification() async {
    try {
      final status = await Permission.notification.status;
      return _ReqStatus(
        _ReqId.notification,
        granted: status.isGranted || status.isLimited,
        permanentlyDenied: status.isPermanentlyDenied,
      );
    } catch (_) {
      return const _ReqStatus(_ReqId.notification);
    }
  }

  // ---------------------------------------------------------------------------
  // REQUEST PIPELINE
  // ---------------------------------------------------------------------------

  /// Three-pass grant strategy:
  ///
  ///   Pass 1 — try the in-app OS dialogs for any permission that is
  ///   in `denied` state (never been asked, or denied without
  ///   "permanent"). Foreground location is requested before
  ///   background, because Android refuses an `Always` request unless
  ///   `WhenInUse` has already been granted in this app session.
  ///
  ///   Pass 2 — background ("Always") location escalation.
  ///   On Android 11+ this can only be granted from the system
  ///   settings page ("Allow all the time"). We open the app
  ///   settings page so the user can switch the toggle, then return —
  ///   the lifecycle observer re-checks on resume.
  ///
  ///   Pass 3 — anything else still missing (permanently denied,
  ///   restricted, or — on iOS — silently re-denied without a dialog)
  ///   is escalated to the system settings page. We open one settings
  ///   page and bail out; opening multiple settings pages in sequence
  ///   is unsupported on every platform.
  ///
  /// This guarantees a single button tap always produces a visible
  /// action — either an OS dialog or a settings page.
  Future<void> _requestAll() async {
    if (_requesting) return;
    if (mounted) setState(() => _requesting = true);

    try {
      // ---------- PASS 1: in-app OS dialogs ----------

      if (!_location.granted && !_location.permanentlyDenied) {
        await Geolocator.requestPermission();
        await _recheck();
      }

      // Background location MUST come after whileInUse — the OS
      // silently denies an `Always` request otherwise. On Android 10
      // a dialog still appears; on Android 11+ this call returns
      // `denied` and the user must visit settings (handled in pass 2).
      if (mounted &&
          _location.granted &&
          !_backgroundLocation.granted &&
          !_backgroundLocation.permanentlyDenied) {
        await Permission.locationAlways.request();
        await _recheck();
      }

      if (mounted &&
          !_notification.granted &&
          !_notification.permanentlyDenied) {
        await Permission.notification.request();
        await _recheck();
      }

      if (!mounted) return;
      if (_allGranted) return;

      // ---------- PASS 2/3: escalate to system settings ----------
      //
      // Order matters: foreground location, then background location,
      // then GPS, then notification. Each redirect leaves the app, so
      // we open exactly one and return — the resume observer will
      // re-run _recheck and the user can tap the button again to
      // chain to the next missing item.

      if (!_location.granted) {
        await openAppSettings();
        return;
      }
      if (!_backgroundLocation.granted) {
        // Android 11+: only the settings page exposes the
        // "Allow all the time" radio. permission_handler routes us
        // straight to the app permissions screen.
        await openAppSettings();
        return;
      }
      if (!_gps.granted) {
        await Geolocator.openLocationSettings();
        return;
      }
      if (!_notification.granted) {
        await openAppSettings();
        return;
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Optimistic render: while the very first check is still in
    // flight (or every subsequent check has confirmed all-granted),
    // we hand the child through unchanged. This keeps cold-start
    // and resume *pixel-identical* to the no-gate case — no splash
    // frame, no flicker, no perceived "stuck white screen". The
    // checks complete in milliseconds; if anything turns out to be
    // missing the blocking screen swaps in on the very next frame.
    if (!_ready || _allGranted) {
      return widget.child;
    }

    // Blocking screen. `PopScope(canPop: false)` blocks the Android
    // back gesture; there is no AppBar / close button to begin with.
    //
    // When everything missing is `permanentlyDenied` or restricted,
    // the only useful action is opening settings — we surface that
    // intent on the primary button so the label matches what's
    // about to happen.
    final needsOnlySettings =
        (_location.permanentlyDenied || _location.granted) &&
            (_backgroundLocation.permanentlyDenied ||
                _backgroundLocation.granted) &&
            (_notification.permanentlyDenied || _notification.granted) &&
            !_allGranted;

    return PopScope(
      canPop: false,
      child: _BlockingScreen(
        location: _location,
        backgroundLocation: _backgroundLocation,
        gps: _gps,
        notification: _notification,
        requesting: _requesting,
        primaryActionIsSettings: needsOnlySettings,
        onGrant: _requestAll,
        onOpenSettings: () async {
          // Direct user-driven escape hatch — straight to app
          // settings, no in-app dialog attempt. Useful if the OS
          // dialog has been silently suppressed by repeated denials.
          final opened = await openAppSettings();
          await _recheck();
          return opened;
        },
      ),
    );
  }
}

// =============================================================================
// VISUAL LAYER
// =============================================================================

class _BlockingScreen extends StatelessWidget {
  final _ReqStatus location;
  final _ReqStatus backgroundLocation;
  final _ReqStatus gps;
  final _ReqStatus notification;
  final bool requesting;
  final bool primaryActionIsSettings;
  final Future<void> Function() onGrant;
  final Future<bool> Function() onOpenSettings;

  const _BlockingScreen({
    required this.location,
    required this.backgroundLocation,
    required this.gps,
    required this.notification,
    required this.requesting,
    required this.primaryActionIsSettings,
    required this.onGrant,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // AppLocalizations may not yet be available on the *very* first
    // frame after a locale change (delegate still resolving). Fall
    // back to English literals in that narrow window so the gate
    // doesn't crash; the next frame will resolve correctly.
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(cs: cs),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.permissionGate_title ?? 'Permissions required',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n?.permissionGate_subtitle ??
                          'The app requires the following to work. If any '
                              'of them is denied, the app cannot continue.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _RequirementTile(
                      icon: Icons.location_on_outlined,
                      title: l10n?.permissionGate_locationTitle ??
                          'Location permission',
                      subtitle: l10n?.permissionGate_locationSubtitle ??
                          'To track customer visits and routes',
                      status: location,
                    ),
                    const SizedBox(height: 10),
                    _RequirementTile(
                      icon: Icons.my_location_outlined,
                      title: l10n?.permissionGate_backgroundLocationTitle ??
                          'Background location ("Allow all the time")',
                      subtitle: l10n?.permissionGate_backgroundLocationSubtitle ??
                          'Required so the app keeps reporting your location while in the background',
                      status: backgroundLocation,
                    ),
                    const SizedBox(height: 10),
                    _RequirementTile(
                      icon: Icons.gps_fixed,
                      title: l10n?.permissionGate_gpsTitle ??
                          'GPS must be enabled',
                      subtitle: l10n?.permissionGate_gpsSubtitle ??
                          'To determine precise location',
                      status: gps,
                    ),
                    const SizedBox(height: 10),
                    _RequirementTile(
                      icon: Icons.notifications_active_outlined,
                      title: l10n?.permissionGate_notificationTitle ??
                          'Notifications',
                      subtitle: l10n?.permissionGate_notificationSubtitle ??
                          'To receive alerts about new orders and tasks',
                      status: notification,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: requesting ? null : onGrant,
                        icon: requesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Icon(primaryActionIsSettings
                                ? Icons.settings_outlined
                                : Icons.check_circle_outline),
                        label: Text(
                          requesting
                              ? (l10n?.permissionGate_busy ??
                                  'Please wait...')
                              : (primaryActionIsSettings
                                  ? (l10n?.permissionGate_openSettingsCta ??
                                      'Open settings')
                                  : (l10n?.permissionGate_grantCta ??
                                      'Grant permission')),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    // Always-available escape hatch: if the OS dialog
                    // has been silently suppressed (iOS after repeated
                    // denials), this button jumps straight to the app
                    // settings page. Hidden when the primary button
                    // already routes there to avoid two buttons doing
                    // the same thing.
                    if (!primaryActionIsSettings) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed:
                              requesting ? null : () => onOpenSettings(),
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(l10n?.permissionGate_openSettingsCta ??
                              'Open settings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ColorScheme cs;
  const _Hero({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.shield_outlined,
          color: cs.onPrimary,
          size: 48,
        ),
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _ReqStatus status;

  const _RequirementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final Color accent;
    final IconData rightIcon;
    final String rightText;
    if (status.granted) {
      accent = Colors.green;
      rightIcon = Icons.check_circle;
      rightText = l10n?.permissionGate_statusGranted ?? 'Granted';
    } else if (status.permanentlyDenied) {
      accent = Colors.red;
      rightIcon = Icons.error;
      rightText = l10n?.permissionGate_statusFromSettings ?? 'From settings';
    } else {
      accent = cs.error;
      rightIcon = Icons.radio_button_unchecked;
      rightText = l10n?.permissionGate_statusRequired ?? 'Required';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(status.granted ? 0.4 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(rightIcon, size: 14, color: accent),
                const SizedBox(width: 4),
                Text(
                  rightText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
