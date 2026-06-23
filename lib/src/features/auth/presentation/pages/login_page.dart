import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/health_check_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/core/network/organization_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/models/api_organization.dart';
import 'package:gloria_marketing_flutter/src/core/network/models/api_project.dart';

import '../../../../core/network/server_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  late AnimationController _animationController;

  /// Controls the slide/fade reveal of the org+project selection area.
  late AnimationController _selectionAreaController;
  late Animation<double> _selectionAreaAnimation;

  /// Auto-close timer: hides the selection area 20s after it opens.
  Timer? _selectionAutoCloseTimer;

  // ── Organization / Project selection (dynamic) ──
  List<ApiOrganization>? _organizations;
  ApiOrganization? _selectedOrganization;
  ApiProject? _selectedProject;
  bool _isLoadingOrganizations = true;
  String? _orgLoadError;

  /// `true` when the API failed and we fell back to the legacy [ServerEnv]
  /// enum picker. The user can still log in but with the hardcoded list.
  bool _useLegacyPicker = false;

  /// Localization key supplied via `Navigator.pushNamed(... arguments: ...)`
  /// when a session-end handler routes the user back to login. Shown once
  /// in [didChangeDependencies] then cleared so re-builds do not repeat
  /// the banner.
  String? _pendingBannerKey;
  bool _bannerShown = false;

  // (Saqladim — lekin pastda Theme.of(context) ranglari ishlatiladi)
  static const Color primaryColor = Color(0xFF50AAEA);
  static const Color primaryColorText = Color(0xFF0D7DD8);
  static const Color successColor = Color(0xFF3EBD84);
  static const Color accentColor = Color(0xFFFFE8A3);

  // ── Legacy server picker (fallback) ──
  Future<void> _pickServer(BuildContext context) async {
    final service = sl<ServerService>();
    final selected = await showModalBottomSheet<ServerEnv>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView(
          children: ServerEnv.values.map((e) {
            final isSel = e == service.current.value;
            return ListTile(
              leading: Icon(Icons.cloud_outlined,
                  color: isSel ? Theme.of(ctx).colorScheme.primary : null),
              title: Text(e.label),
              subtitle: Text(e.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: isSel ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, e),
            );
          }).toList(),
        );
      },
    );
    if (selected != null) {
      await service.set(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.label} ${AppLocalizations.of(context)?.serverSelected ?? "server selected"}')),
      );
    }
  }

  // ── Organization picker ──
  Future<void> _pickOrganization(BuildContext context) async {
    final orgs = _organizations;
    if (orgs == null || orgs.isEmpty) return;

    final selected = await showModalBottomSheet<ApiOrganization>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return ListView(
          children: orgs.map((org) {
            final isSel = org.id == _selectedOrganization?.id;
            return ListTile(
              leading: Icon(Icons.business_outlined,
                  color: isSel ? theme.colorScheme.primary : null),
              title: Text(org.name),
              subtitle: Text(
                '${org.projects.length} ${org.projects.length == 1 ? "loyiha" : "loyiha"}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: isSel ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, org),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedOrganization = selected;
        // Auto-select the first (or only) project
        if (selected.projects.length == 1) {
          _selectedProject = selected.projects.first;
        } else {
          _selectedProject = null;
        }
      });
    }
  }

  // ── Project picker ──
  Future<void> _pickProject(BuildContext context) async {
    final org = _selectedOrganization;
    if (org == null || org.projects.isEmpty) return;

    final selected = await showModalBottomSheet<ApiProject>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return ListView(
          children: org.projects.map((proj) {
            final isSel = proj.id == _selectedProject?.id;
            return ListTile(
              leading: Icon(Icons.folder_outlined,
                  color: isSel ? theme.colorScheme.primary : null),
              title: Text(proj.name),
              trailing: isSel ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, proj),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedProject = selected;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _selectionAreaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _selectionAreaAnimation = CurvedAnimation(
      parent: _selectionAreaController,
      curve: Curves.easeInOutCubic,
    );

    _selectionAreaController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startAutoCloseTimer();
      } else if (status == AnimationStatus.reverse ||
                 status == AnimationStatus.dismissed) {
        _cancelAutoCloseTimer();
      }
    });

    _loadSavedCredentials();
    _fetchOrganizations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick up a session-end banner key passed by `handleSessionEnded`
    // through `Navigator.pushNamedAndRemoveUntil(..., arguments: ...)`.
    if (_bannerShown) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _pendingBannerKey = args;
    }
    if (_pendingBannerKey != null) {
      _bannerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final localized =
            _localizeMessageKey(context, _pendingBannerKey!) ?? _pendingBannerKey!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localized),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _cancelAutoCloseTimer();
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _selectionAreaController.dispose();
    super.dispose();
  }

  void _showSelectionArea() {
    _selectionAreaController.forward();
  }

  void _hideSelectionArea() {
    _selectionAreaController.reverse();
  }

  void _startAutoCloseTimer() {
    _cancelAutoCloseTimer();
    _selectionAutoCloseTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _selectionAreaController.isCompleted) {
        _hideSelectionArea();
      }
    });
  }

  void _cancelAutoCloseTimer() {
    _selectionAutoCloseTimer?.cancel();
    _selectionAutoCloseTimer = null;
  }

  // ── Fetch organizations from backend ──
  Future<void> _fetchOrganizations() async {
    setState(() {
      _isLoadingOrganizations = true;
      _orgLoadError = null;
    });

    try {
      final service = sl<OrganizationApiService>();
      final orgs = await service.fetchOrganizations();

      if (!mounted) return;

      if (orgs.isEmpty) {
        // No orgs from API — try cache, then fall back to legacy
        final cached = service.loadCachedOrganizations();
        if (cached.isNotEmpty) {
          _applyOrganizations(cached);
        } else {
          setState(() {
            _useLegacyPicker = true;
            _isLoadingOrganizations = false;
          });
        }
        return;
      }

      _applyOrganizations(orgs);
      _showSelectionArea();
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) print('[LoginPage] Org fetch failed: $e');

      // Try cached data
      try {
        final cached = sl<OrganizationApiService>().loadCachedOrganizations();
        if (cached.isNotEmpty) {
          _applyOrganizations(cached);
          return;
        }
      } catch (_) {}

      // Fall back to legacy picker
      setState(() {
        _orgLoadError = e.toString();
        _useLegacyPicker = true;
        _isLoadingOrganizations = false;
      });
    }
  }

  /// Applies the loaded organizations and tries to restore the previously
  /// selected org/project from SharedPreferences.
  void _applyOrganizations(List<ApiOrganization> orgs) {
    final prefs = sl<SharedPreferencesService>();
    final savedOrgId = prefs.getDynamicOrgId();
    final savedProjectId = prefs.getDynamicProjectId();

    ApiOrganization? restoredOrg;
    ApiProject? restoredProject;

    if (savedOrgId != null) {
      for (final org in orgs) {
        if (org.id == savedOrgId) {
          restoredOrg = org;
          if (savedProjectId != null) {
            for (final proj in org.projects) {
              if (proj.id == savedProjectId) {
                restoredProject = proj;
                break;
              }
            }
          }
          break;
        }
      }
    }

    setState(() {
      _organizations = orgs;
      _selectedOrganization = restoredOrg;
      _selectedProject = restoredProject;
      _useLegacyPicker = false;
      _isLoadingOrganizations = false;
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      if(prefs.isRememberMeEnabled()) {
        final username = prefs.getSavedUsername();
        final password = prefs.getSavedPassword();
        if (username != null && password != null) {
          setState(() {
            _usernameController.text = username;
            _passwordController.text = password;
            _rememberMe = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _rememberMe = false);
    }
  }

  Future<void> _saveUserData(AuthSuccess state) async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      await prefs.saveUserData(
        userCode: state.user.code,
        userName: state.user.name,
        warehouseCode: state.user.warehouseCode,
        codeProject: state.user.codeProject,
        telegramID: state.user.telegramID,
        chatID: state.user.chatID,
        topicID: state.user.topicID,
      );
    } catch (_) {}
  }

  void _onLoginButtonPressed() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      await prefs.saveCredentials(
        _usernameController.text,
        _passwordController.text,
        _rememberMe,
      );
    } catch (_) {}

    // Persist the dynamic org/project selection to ServerService
    if (!_useLegacyPicker && _selectedProject != null && _selectedOrganization != null) {
      try {
        await sl<ServerService>().setDynamic(
          servicePath: _selectedProject!.servicePath,
          organizationId: _selectedOrganization!.id,
          organizationName: _selectedOrganization!.name,
          projectId: _selectedProject!.id,
          projectName: _selectedProject!.name,
        );
      } catch (e) {
        if (kDebugMode) print('Error saving dynamic server: $e');
      }
    } else if (_useLegacyPicker) {
      // Ensure legacy server is saved
      try {
        final serverService = sl<ServerService>();
        await serverService.set(serverService.current.value);
      } catch (e) {
        if (kDebugMode) print('Error saving default server: $e');
      }
    }

    // First try online authentication
    if (!mounted) return;
    context.read<AuthBloc>().add(LoginButtonPressed(
      username: _usernameController.text,
      password: _passwordController.text,
    ));
  }

  Future<void> _tryOfflineLogin(String username, String password) async {
    try {
      final prefs = sl<SharedPreferencesService>();
      final dbHelper = sl<DatabaseHelper>();

      // Get username and code from preferences
      final prefsUsername = prefs.getSavedUsername();
      final prefsUserCode = prefs.getUserCode();

      if (prefsUsername == null || prefsUserCode == null) {
        // No saved user data in preferences
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.noInternetNoSavedUser ?? 'No internet and no saved user data found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if entered username matches preferences username
      if (username != prefsUsername) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.noInternetLoginMismatch ?? 'No internet and entered login does not match saved login'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get user from database by code
      final userData = await dbHelper.getUserByCode(prefsUserCode);
      if(userData?['base_url'] != sl<ServerService>().baseUrl) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.savedUserServerMismatch ?? 'Saved user data does not match current server. Please change server.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (userData != null && userData['username'] == prefsUsername && userData['code'] == prefsUserCode) {
        // User found in database with matching username and code, offer offline mode
        final shouldUseOffline = await _showOfflineModeDialog(userData);
        if (shouldUseOffline && mounted) {
          await _loginOffline(userData);
        }
      } else {
        // User not found in database or data doesn't match
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.noInternetUserNotInDb ?? 'No internet and user data not found in database or does not match'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.offlineLoginError ?? "Offline login error"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showOfflineModeDialog(Map<String, dynamic> userData) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.noInternetAvailable ?? 'No internet available'),
        content: Text(
          '${userData['name']} (${userData['username']}) ${AppLocalizations.of(context)?.offlineModeQuestion ?? "Do you want to enter offline mode as"}\n\n'
          '${AppLocalizations.of(context)?.offlineModeDescription ?? "In offline mode you can work with existing data, but cannot load new data."}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)?.offlineLogin ?? 'Offline login'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _loginOffline(Map<String, dynamic> userData) async {
    try {
      // Set offline mode in preferences
      final prefs = sl<SharedPreferencesService>();
      await prefs.setOfflineMode(true);

      // Save user data to preferences
      await prefs.saveUserData(
        userCode: userData['code'],
        userName: userData['name'],
        warehouseCode: userData['warehouse_code'],
        codeProject: userData['code_project'],
        telegramID: userData['telegram_id'] ?? '',
        chatID: userData['chat_id'] ?? '',
        topicID: userData['topic_id'] ?? '',
      );

      // Navigate to home page
      if (mounted) {
        final role = userData['role'] ?? 'Agent';
        switch (role) {
          case 'Agent':
          case 'Supervisor':
            Navigator.pushReplacementNamed(context, AppRouter.agentHomeRoute);
            break;
          case 'Boss':
            Navigator.pushReplacementNamed(context, AppRouter.bossHomeRoute);
            break;
          case 'Collector':
            Navigator.pushReplacementNamed(context, AppRouter.collectorHomeRoute);
            break;
          case 'Forwarder':
            Navigator.pushReplacementNamed(context, AppRouter.forwarderHomeRoute);
            break;
          case 'Packer':
            Navigator.pushReplacementNamed(context, AppRouter.packerHomeRoute);
            break;
          case 'WarehouseManager':
            Navigator.pushReplacementNamed(context, AppRouter.warehouseManagerHomeRoute);
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)?.unknownUserRole ?? "Unknown user role"}: $role')),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.offlineLoginError ?? "Offline login error"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleOnlineLoginSuccess(AuthSuccess state) async {
    try {
      // Clear offline mode (since we're online)
      final prefs = sl<SharedPreferencesService>();
      await prefs.setOfflineMode(false);

      // Check if user data in database matches current user
      final dbHelper = sl<DatabaseHelper>();
      final dbUser = await dbHelper.getUserByCode(state.user.code);

      if (kDebugMode) {
        if (dbUser == null) {
          print('No user found in database, will sync all data');
        } else {
          // Check if user data matches
          final userMatches = dbUser['code'] == state.user.code &&
              dbUser['name'] == state.user.name &&
              dbUser['warehouse_code'] == state.user.warehouseCode &&
              dbUser['code_project'] == state.user.codeProject &&
              dbUser['base_url'] == state.user.baseUrl;

          if (!userMatches) {
            print('User data mismatch, will sync all data');
          } else {
            print('User data matches, no sync needed');
          }
        }
      }

      // Save user data to preferences
      await _saveUserData(state);

      // Save user to database for future offline use
      try {
        await dbHelper.saveUser({
          'code': state.user.code,
          'username': state.user.username,
          'password': '', // Don't store password in database for security
          'name': state.user.name,
          'role': state.user.role,
          'warehouse_code': state.user.warehouseCode,
          'code_project': state.user.codeProject,
          'base_url': state.user.baseUrl,
          'telegram_id': state.user.telegramID,
          'chat_id': state.user.chatID,
          'topic_id': state.user.topicID,
        });
        if (kDebugMode) print('User saved to database for offline use');
      } catch (e) {
        // Don't fail login if offline save fails - it's non-critical
        if (kDebugMode) print('Error saving user for offline use: $e');
      }

      // Always show sync prompt on every login
      await prefs.setSyncNeeded(true);
      await prefs.setIsFirstTimeSync(dbUser == null);

      // Initialise active project tracking for customer_scope=project
      // tenants. Org-scope tenants get a no-op.
      try {
        await sl<ProjectContext>().bootstrap(state.user);
      } catch (e) {
        if (kDebugMode) print('ProjectContext bootstrap failed: $e');
      }

      // Warm the customer-balance status cache so the trading-points
      // list/grid render with the right tint + indicator on first frame
      // instead of flickering through the unknown state. Best-effort —
      // failure leaves the cache lazy and the first card mount triggers
      // bootstrap on its own. M12 P1.3.
      try {
        if (sl.isRegistered<CustomerBalanceStatusCache>()) {
          // ignore: discarded_futures
          sl<CustomerBalanceStatusCache>().bootstrap();
        }
      } catch (e) {
        if (kDebugMode) print('CustomerBalanceStatusCache bootstrap failed: $e');
      }

      // Show success message and navigate
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.loginSuccessful ?? 'Login Successful!')));

        // Project-scope tenant with no active project? Force picker first.
        final projectContext = sl<ProjectContext>();
        if (projectContext.requiresProjectHeader &&
            (projectContext.activeProjectHeaderValue == null ||
                projectContext.activeProjectHeaderValue!.isEmpty)) {
          await Navigator.of(context).pushNamed(
            AppRouter.projectPickerRoute,
            arguments: <String, dynamic>{'mandatory': true},
          );
        }
        if (mounted) {
          _navigateToHomePage(state.user.role);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.onlineLoginError ?? "Online login processing error"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _navigateToHomePage(String role) {
    switch (role) {
      case 'Agent':
      case 'Supervisor':
        Navigator.pushReplacementNamed(context, AppRouter.agentHomeRoute);
        break;
      case 'Boss':
        Navigator.pushReplacementNamed(context, AppRouter.bossHomeRoute);
        break;
      case 'Collector':
        Navigator.pushReplacementNamed(context, AppRouter.collectorHomeRoute);
        break;
      case 'Forwarder':
        Navigator.pushReplacementNamed(context, AppRouter.forwarderHomeRoute);
        break;
      case 'Packer':
        Navigator.pushReplacementNamed(context, AppRouter.packerHomeRoute);
        break;
      case 'WarehouseManager':
        Navigator.pushReplacementNamed(context, AppRouter.warehouseManagerHomeRoute);
        break;
      default:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)?.unknownUserRole ?? "Unknown user role"}: $role')));
    }
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        // CHANGED: AgentHome'dagi kabi gradient fon va markaziy Card
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(.10),
                theme.colorScheme.primaryContainer.withOpacity(.08),
              ],
            ),
          ),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailureState) {
                if (kDebugMode) print('Auth failure: ${state.message}, type: ${state.errorType}');
                final failure = state.failure;
                if (failure is NetworkFailure || state.errorType == AuthErrorType.connectivity) {
                  _tryOfflineLogin(_usernameController.text, _passwordController.text);
                } else {
                  if (mounted) {
                    final localized = failure == null
                        ? state.message
                        : _localizeAuthFailure(context, failure) ?? state.message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localized),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
              if (state is AuthSuccess) {
                _handleOnlineLoginSuccess(state);
              }
            },
            child: SafeArea(
              child: Center(
                child: RefreshIndicator(
                  onRefresh: _fetchOrganizations,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 420,
                          minHeight: MediaQuery.of(context).size.height - 120,
                        ),
                        child: Center(
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              child: _buildForm(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// Map a typed [AuthFailure] to its localized message via [AppLocalizations].
  String? _localizeAuthFailure(BuildContext context, AuthFailure failure) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;
    switch (failure) {
      case InvalidCredentialsFailure():
        return l10n.invalidCredentials;
      case UserInactiveFailure():
        return l10n.userInactive;
      case UserOutsideActiveWindowFailure(:final activeStart, :final activeEnd):
        return l10n.userOutsideActiveWindow(
          activeStart?.toIso8601String() ?? '—',
          activeEnd?.toIso8601String() ?? '—',
        );
      case LicenseMissingFailure():
        return l10n.licenseMissing;
      case LicenseExpiredFailure():
        return l10n.licenseExpired;
      case LicenseSeatExceededFailure(:final userRank, :final seatCount):
        return l10n.licenseSeatExceeded(userRank, seatCount);
      case NetworkFailure():
        return l10n.networkError;
      case UnknownAuthFailure():
        return l10n.serverError;
      case MobileDeviceBoundToOtherUserFailure():
        return l10n.mobileDeviceBoundToOtherUser;
      case MobileUserBoundToOtherDeviceFailure():
        return l10n.mobileUserBoundToOtherDevice;
      case DeviceBindingInvalidFailure():
        return l10n.deviceBindingInvalid;
      case SessionRevokedFailure():
        return l10n.sessionRevoked;
      case OneCUserNotFoundFailure():
        return l10n.oneCUserNotFound;
    }
  }

  String? _localizeMessageKey(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;
    switch (key) {
      case 'invalidCredentials':
        return l10n.invalidCredentials;
      case 'userInactive':
        return l10n.userInactive;
      case 'licenseMissing':
        return l10n.licenseMissing;
      case 'licenseExpired':
        return l10n.licenseExpired;
      case 'networkError':
        return l10n.networkError;
      case 'mobileDeviceBoundToOtherUser':
        return l10n.mobileDeviceBoundToOtherUser;
      case 'mobileUserBoundToOtherDevice':
        return l10n.mobileUserBoundToOtherDevice;
      case 'deviceBindingInvalid':
        return l10n.deviceBindingInvalid;
      case 'sessionRevoked':
        return l10n.sessionRevoked;
      case 'oneCUserNotFound':
        return l10n.oneCUserNotFound;
      default:
        return null;
    }
  }

  Widget _debugBackendFooter(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.debugBackendUrl(TokenService.v2BaseUrl),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _testBackendConnection(context),
            icon: const Icon(Icons.network_check, size: 18),
            label: Text(l10n.debugTestConnection),
          ),
        ],
      ),
    );
  }

  Future<void> _testBackendConnection(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await sl<HealthCheckService>().pingV2();
    if (!mounted) return;
    final text = result.ok
        ? l10n.debugConnectionOk(result.latency?.inMilliseconds ?? 0)
        : l10n.debugConnectionFailed(result.errorMessage ?? '?');
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: result.ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ── Legacy server chip (fallback) ──
  Widget _serverChip() {
    final server = sl<ServerService>();
    return ValueListenableBuilder<ServerEnv>(
      valueListenable: server.current,
      builder: (context, env, _) {
        final color = switch (env) {
          ServerEnv.Evyap    => const Color.fromRGBO(0, 54, 152, 1.0),
          ServerEnv.Garnier  => const Color.fromRGBO(34, 50, 46, 1.0),
          ServerEnv.PPD      => const Color.fromRGBO(0, 0, 0, 1.0),
          ServerEnv.Avon     => const Color.fromRGBO(218, 0, 73, 1.0),
          ServerEnv.AvonTest => const Color.fromRGBO(80, 209, 248, 1.0),
          ServerEnv.ProWash  => const Color.fromRGBO(0, 150, 136, 1.0),
        };
        return ActionChip(
          label: Text(env.label),
          avatar: CircleAvatar(radius: 6, backgroundColor: color),
          onPressed: () => _pickServer(context),
        );
      },
    );
  }

  // ── Selection tile: tappable row with icon, label and value ──
  Widget _selectionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value ?? 'Tanlang',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  // ── Server / org+project selection area ──
  Widget _buildSelectionArea(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingOrganizations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(
          height: 24, width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }

    if (_useLegacyPicker) {
      return Row(
        children: [
          Expanded(child: _serverChip()),
          if (_orgLoadError != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: _isLoadingOrganizations ? null : _fetchOrganizations,
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: 'Qayta yuklash',
                icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              ),
            ),
        ],
      );
    }

    // Dynamic org + project pickers
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with refresh button in top-right
        Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: _isLoadingOrganizations ? null : _fetchOrganizations,
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: 'Yangilash',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _selectionTile(
          context: context,
          icon: Icons.business_rounded,
          label: 'Tashkilot',
          value: _selectedOrganization?.name,
          onTap: () => _pickOrganization(context),
        ),
        const SizedBox(height: 8),
        _selectionTile(
          context: context,
          icon: Icons.folder_rounded,
          label: 'Loyiha',
          value: _selectedProject?.name,
          onTap: _selectedOrganization != null
              ? () => _pickProject(context)
              : null,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Login button disabled when no project selected (dynamic mode)
    final bool canLogin = _useLegacyPicker || _selectedProject != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizeTransition(
          sizeFactor: _selectionAreaAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _selectionAreaAnimation,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -100) _hideSelectionArea();
              },
              child: Column(
                children: [
                  _buildSelectionArea(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            if (_selectionAreaController.isDismissed ||
                _selectionAreaController.status == AnimationStatus.reverse) {
              _showSelectionArea();
            } else {
              _hideSelectionArea();
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.lock_outline, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.welcome,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterCredentials,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
        ),
        const SizedBox(height: 20),

        _M3Input(
          controller: _usernameController,
          label: l10n.username,
          prefix: const Icon(Icons.person_outline),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {},
        ),
        const SizedBox(height: 12),
        _M3Input(
          controller: _passwordController,
          label: l10n.password,
          prefix: const Icon(Icons.lock_outline),
          obscureText: !_isPasswordVisible,
          suffix: IconButton(
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          ),
          onSubmitted: (_) => _onLoginButtonPressed(),
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: theme.colorScheme.primary,
              onChanged: (v) => setState(() => _rememberMe = v ?? false),
            ),
            Expanded(
              child: Text(
                l10n.rememberMe,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {}, // kerak bo'lsa: parolni unutdingizmi
              child: Text(l10n.forgotPassword),
            ),
          ],
        ),
        const SizedBox(height: 16),

        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final loading = state is AuthLoading;
            return SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: (loading || !canLogin) ? null : _onLoginButtonPressed,
                child: loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3))
                    : Text(l10n.login),
              ),
            );
          },
        ),
        _debugBackendFooter(context),
      ],
    );
  }
}

/// Material 3 friendly input (AgentHome palitrasiga mos)
class _M3Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _M3Input({
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? '${AppLocalizations.of(context)?.enterField ?? "Please enter"} $label' : null,
      ),
    );
  }
}
