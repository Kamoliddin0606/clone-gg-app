import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/auth/permission_codenames.dart';
import 'package:gloria_marketing_flutter/src/core/providers/locale_provider.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_toggle.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings/data_sync_tab.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings/projects_tab.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/backend_permissions_section.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/permission_group_card.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/project_debt_limits_section.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _initialTabIndex = 0;

  /// Monotonic counter driven by [DataSyncOrchestrator] notifications.
  /// Stamped into every tab's [ValueKey] so each completed sync forces
  /// Flutter to throw away the children's State objects and rebuild
  /// them from scratch — effectively a "full reload" of the settings
  /// surface without losing the [TabController] state or the user's
  /// current tab selection.
  int _reloadCounter = 0;
  DataSyncOrchestrator? _orchestrator;

  // Sync emits notifyListeners() many times per operation (start / progress /
  // done for each table, plus refreshRecordCounts). Coalesce those into a
  // single tab rebuild once the burst has settled, so the user sees one
  // reload at the end instead of dozens mid-sync.
  Timer? _reloadDebounce;
  static const Duration _reloadDebounceDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _initialTabIndex,
    ); // 5 tabs: Permissions, Maps, DataSync, Interface, Projects
    _orchestrator = sl<DataSyncOrchestrator>();
    _orchestrator!.addListener(_onSyncEvent);
  }

  void _onSyncEvent() {
    if (!mounted) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(_reloadDebounceDuration, () {
      if (!mounted) return;
      setState(() => _reloadCounter++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should navigate to DataSyncTab
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['openDataSyncTab'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(2); // DataSyncTab is at index 2
        }
      });
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _orchestrator?.removeListener(_onSyncEvent);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // User Profile Section
          const UserProfileSection(),

          // Tab Bar
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              tabs: [
                Tab(text: l10n.permissions),
                Tab(text: l10n.maps),
                Tab(text: l10n.dataSync),
                Tab(text: l10n.interfaceSettings),
                Tab(text: l10n.projectsTab_title),
              ],
            ),
          ),

          // Tab Bar View — every tab is keyed by `_reloadCounter` so
          // a sync notification from the orchestrator forces Flutter
          // to discard the current State objects and rebuild each
          // tab from scratch. UserProfileSection, the AppBar and the
          // TabController stay alive (live above this widget), so the
          // user keeps their tab selection across the reload.
          Expanded(
            // Inheritable bridge so deeply-nested settings widgets
            // (e.g. the "Pick a project" CTA on DataSyncTab's
            // no-active-project banner) can switch tabs without
            // knowing about the TabController. Indices match the
            // children list below.
            child: SettingsTabSwitcher(
              animateTo: _tabController.animateTo,
              projectsIndex: 4,
              child: TabBarView(
                controller: _tabController,
                children: [
                  PermissionsTab(key: ValueKey('perm-$_reloadCounter')),
                  MapsTab(key: ValueKey('maps-$_reloadCounter')),
                  DataSyncTab(key: ValueKey('sync-$_reloadCounter')),
                  InterfaceSettingsTab(
                    key: ValueKey('iface-$_reloadCounter'),
                  ),
                  ProjectsTab(key: ValueKey('projects-$_reloadCounter')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({super.key});

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _isLoading = true;
  String? _errorMessage;

  // User data from SharedPreferences
  String? _userName;
  String? _userCode;
  String? _telegramID;
  String? _chatID;
  String? _topicID;
  String? _warehouseCode;
  String? _codeProject;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = context.read<SharedPreferencesService>();
      _userName = prefs.getUserName();
      _userCode = prefs.getUserCode();
      _telegramID = prefs.getTelegramID();
      _chatID = prefs.getChatID();
      _topicID = prefs.getTopicID();
      _warehouseCode = prefs.getWarehouseCode();
      _codeProject = prefs.getCodeProject();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Foydalanuvchi ma\'lumotlarini yuklashda xatolik: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUserData, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary,
                child: Text(
                  _userName?.isNotEmpty == true
                      ? _userName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'Noma\'lum foydalanuvchi',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agent ID: ${_userCode ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_warehouseCode != null && _warehouseCode!.isNotEmpty)
                      Text(
                        'Sklad: $_warehouseCode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleEdit,
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isEditing
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: l10n.name,
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(text: _userName),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Telegram ID',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(
                              text: _telegramID,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Chat ID',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(text: _chatID),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Topic ID',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(text: _topicID),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class PermissionsTab extends StatefulWidget {
  const PermissionsTab({super.key});

  @override
  State<PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  SalesReqPermissions? _permissions;
  bool _isLoading = true;
  String? _errorMessage;
  late final BackendPermissionStore _backendStore;

  @override
  void initState() {
    super.initState();
    // Sync-driven refresh is handled by `_SettingsPageState` which
    // rotates this tab's [ValueKey] on every `DataSyncOrchestrator`
    // notification. That recreates this State object and re-runs
    // initState, so a per-tab listener here would just double the
    // work.
    _backendStore = sl<BackendPermissionStore>();
    _backendStore.addListener(_onBackendStoreChanged);
    _loadPermissions();
  }

  @override
  void dispose() {
    _backendStore.removeListener(_onBackendStoreChanged);
    super.dispose();
  }

  void _onBackendStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get user code from shared preferences
      final prefs = context.read<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      if (kDebugMode)
        print('__________Setting permisionsda User code: $userCode');
      if (userCode == null) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.userCodeNotFound;
          _isLoading = false;
        });
        return;
      }

      // Get permissions from data sync service
      final dataSyncService = context.read<DataSyncService>();
      final permissions = await dataSyncService.getCachedSalesReqPermissions(
        userCode,
      );

      setState(() {
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            '${AppLocalizations.of(context)!.errorLoadingPermissions}: $e';
        _isLoading = false;
      });
    }
  }

  String _getPermissionLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'skipTINduplicateCheck':
        return l10n.skipTINDuplicateCheck;
      case 'allowCreationWithoutTIN':
        return l10n.allowCreationWithoutTIN;
      case 'allowCreatingPointOfSale':
        return l10n.allowCreatingPointOfSale;
      case 'visit':
        return l10n.visit;
      case 'strictSequence':
        return l10n.strictSequence;
      case 'unplannedOrder':
        return l10n.unplannedOrder;
      case 'plannedRoute':
        return l10n.plannedRoute;
      case 'editClientCoordinates':
        return l10n.editClientCoordinates;
      default:
        return key;
    }
  }

  IconData _getPermissionIcon(String key) {
    switch (key) {
      case 'skipTINduplicateCheck':
        return Icons.check_circle_outline;
      case 'allowCreationWithoutTIN':
        return Icons.add_circle_outline;
      case 'allowCreatingPointOfSale':
        return Icons.store;
      case 'visit':
        return Icons.location_on;
      case 'strictSequence':
        return Icons.timeline;
      case 'unplannedOrder':
        return Icons.add_shopping_cart;
      case 'plannedRoute':
        return Icons.route;
      case 'editClientCoordinates':
        return Icons.edit_location;
      default:
        return Icons.settings;
    }
  }

  bool _getPermissionValue(String key) {
    // V2 codename-backed row (`customers.add_customer`) — value comes
    // from `BackendPermissionStore`, not from SOAP `_permissions`. We
    // check this before the SOAP null-guard so the row stays accurate
    // even while SOAP permissions are still loading.
    if (key == 'allowCreatingPointOfSale') {
      return _backendStore.has(PermissionCodenames.customerAdd);
    }
    if (_permissions == null) return false;

    switch (key) {
      case 'skipTINduplicateCheck':
        return _permissions!.skipTINduplicateCheck;
      case 'allowCreationWithoutTIN':
        return _permissions!.allowCreationWithoutTIN;
      case 'visit':
        return _permissions!.visit;
      case 'strictSequence':
        return _permissions!.strictSequence;
      case 'unplannedOrder':
        return _permissions!.unplannedOrder;
      case 'plannedRoute':
        return _permissions!.plannedRoute;
      case 'editClientCoordinates':
        return _permissions!.editClientCoordinates;
      default:
        return false;
    }
  }

  /// Return the override label for a SOAP key whose authority has
  /// migrated to a V2 backend codename. `null` for keys that are
  /// still SOAP-only.
  ///
  /// Listed pairs:
  ///   * `allowCreatingPointOfSale`  ↔ `customers.add_customer`
  ///     (already routed through [BackendPermissionStore] in
  ///     [_getPermissionValue], hence the visible state mirrors the
  ///     backend value — the badge just makes the relationship
  ///     explicit).
  ///   * `editClientCoordinates`     ↔ `customers.change_coordinates`
  ///     (the FAB / edit affordance is gated by the backend; the
  ///     SOAP value is now informational only, so we strike it out).
  String? _soapOverrideLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'allowCreatingPointOfSale':
      case 'editClientCoordinates':
        return l10n.permissionsTab_overrideBadge;
      default:
        return null;
    }
  }

  /// Stable, color-coded category descriptor used by both the hero
  /// header (for the global granted/total chip) and the collapsible
  /// SOAP permission cards. Keeping this in one place avoids
  /// drifting between the count chip and the cards.
  List<_SoapCategoryData> _buildSoapCategories(
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    final categories = <_SoapCategoryData>[
      _SoapCategoryData(
        id: 'dataValidation',
        title: l10n.dataValidation,
        icon: Icons.verified_user_outlined,
        color: cs.primary,
        keys: const [
          'skipTINduplicateCheck',
          'allowCreationWithoutTIN',
          'allowCreatingPointOfSale',
        ],
      ),
      _SoapCategoryData(
        id: 'visitManagement',
        title: l10n.visitManagement,
        icon: Icons.route_outlined,
        color: cs.secondary,
        keys: const ['visit', 'strictSequence', 'unplannedOrder', 'plannedRoute'],
      ),
      _SoapCategoryData(
        id: 'editInformation',
        title: l10n.editInformation,
        icon: Icons.edit_note_outlined,
        color: cs.tertiary,
        keys: const ['editClientCoordinates'],
      ),
    ];
    return categories;
  }

  /// Build a collapsible card showing this user's visit-step plan.
  /// Steps aren't permissions per se, but they share the same
  /// collapsible language as everything else in the tab, so the user
  /// has a single mental model.
  Widget? _buildVisitStepsCard(AppLocalizations l10n, ColorScheme cs) {
    if (_permissions == null || _permissions!.visitSteps.isEmpty) {
      return null;
    }
    final steps = _permissions!.visitSteps;
    final required = steps.where((s) => s.stepRequired).length;
    final color = cs.primary;

    return PermissionGroupCard(
      title: l10n.visitSteps,
      icon: Icons.list_alt_rounded,
      color: color,
      granted: required,
      total: steps.length,
      initiallyExpanded: false,
      children: [
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepCode}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.stepName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.stepRequired
                            ? l10n.mandatoryExecution
                            : l10n.optional,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: step.stepRequired
                                  ? cs.error
                                  : cs.onSurfaceVariant,
                              fontWeight: step.stepRequired
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (step.stepRequired ? cs.error : cs.outline)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    step.stepRequired
                        ? Icons.priority_high_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: step.stepRequired ? cs.error : cs.outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPermissions,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_permissions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.permissionsDataNotAvailable,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final soapCategories = _buildSoapCategories(l10n, colorScheme);

    // Pre-compute granted counts once per build so the hero header and
    // the cards never disagree on the same render.
    final soapGranted = soapCategories.fold<int>(
      0,
      (sum, c) => sum + c.keys.where(_getPermissionValue).length,
    );
    final soapTotal = soapCategories.fold<int>(
      0,
      (sum, c) => sum + c.keys.length,
    );
    final visitStepsCard = _buildVisitStepsCard(l10n, colorScheme);

    return RefreshIndicator(
      onRefresh: _loadPermissions,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Hero header — gradient summary card matching the Data
          // Sync tab's "Sync All" header so the two tabs feel like
          // siblings.
          SliverToBoxAdapter(
            child: _PermissionsHero(
              title: l10n.agentPermissions,
              subtitle: l10n.userPermissionsAndVisitSteps,
              granted: soapGranted,
              total: soapTotal,
            ),
          ),

          // V2 Backend permissions — section header + collapsible
          // category cards.
          const SliverToBoxAdapter(child: BackendPermissionsSection()),

          // Per-project debt limits — independent widget, kept as-is.
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ProjectDebtLimitsSection(),
            ),
          ),

          // SOAP permissions — section header + collapsible cards.
          // Subtitle calls out the relationship with the backend
          // gates above; rows that are wholly superseded by a V2
          // codename are rendered with a strikethrough + "Backend
          // rule" badge so the user sees the SOAP value at a glance
          // but understands it's no longer authoritative.
          SliverToBoxAdapter(
            child: _InlineSectionHeader(
              icon: Icons.security_outlined,
              title: l10n.permissions,
              color: colorScheme.primary,
              trailingCount: '$soapGranted/$soapTotal',
              subtitle: l10n.permissionsTab_soapSectionSubtitle,
            ),
          ),
          for (int i = 0; i < soapCategories.length; i++)
            SliverToBoxAdapter(
              child: PermissionGroupCard(
                title: soapCategories[i].title,
                icon: soapCategories[i].icon,
                color: soapCategories[i].color,
                granted: soapCategories[i]
                    .keys
                    .where(_getPermissionValue)
                    .length,
                total: soapCategories[i].keys.length,
                initiallyExpanded: i == 0,
                children: [
                  for (final key in soapCategories[i].keys)
                    PermissionRow(
                      icon: _getPermissionIcon(key),
                      title: _getPermissionLabel(key, l10n),
                      granted: _getPermissionValue(key),
                      accent: soapCategories[i].color,
                      overriddenBy: _soapOverrideLabel(key, l10n),
                    ),
                ],
              ),
            ),

          // Visit steps — collapsible, hidden when no steps exist.
          if (visitStepsCard != null) ...[
            SliverToBoxAdapter(
              child: _InlineSectionHeader(
                icon: Icons.list_alt_rounded,
                title: l10n.visitSteps,
                color: colorScheme.primary,
              ),
            ),
            SliverToBoxAdapter(child: visitStepsCard),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Inherited bridge that lets descendants of [SettingsPage] switch tabs
/// without holding a reference to the [TabController]. Mounted by
/// [_SettingsPageState.build] around the [TabBarView]; consumed e.g.
/// by the "Pick a project" CTA on the no-active-project banner inside
/// [DataSyncTab].
class SettingsTabSwitcher extends InheritedWidget {
  /// Forwards to `TabController.animateTo`.
  final void Function(int index) animateTo;

  /// Index of the Projects tab in the [TabBarView]. Surfaced as a
  /// named field so callers don't hard-code the magic number.
  final int projectsIndex;

  const SettingsTabSwitcher({
    super.key,
    required this.animateTo,
    required this.projectsIndex,
    required super.child,
  });

  static SettingsTabSwitcher? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsTabSwitcher>();

  /// Convenience helper — `null`-safe call to switch to the Projects tab.
  static void goToProjects(BuildContext context) {
    final switcher = maybeOf(context);
    switcher?.animateTo(switcher.projectsIndex);
  }

  @override
  bool updateShouldNotify(SettingsTabSwitcher old) =>
      animateTo != old.animateTo || projectsIndex != old.projectsIndex;
}

/// Internal descriptor of one SOAP-permission category. Holds the
/// localised title, a Material icon, the accent color, and the list
/// of permission keys that belong to it.
class _SoapCategoryData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> keys;

  const _SoapCategoryData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.keys,
  });
}

/// Gradient hero card pinned at the top of the Permissions tab. Same
/// visual treatment as the Data Sync tab's "Sync All" card so the
/// settings tabs feel like a coherent family.
class _PermissionsHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final int granted;
  final int total;

  const _PermissionsHero({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = total == 0 ? 0.0 : (granted / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_outlined,
                    color: cs.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$granted / $total',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar — a quick visual on how many permissions the
          // user actually has. Skipped when total is zero.
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: cs.onPrimaryContainer.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Flat, in-list section header. Used between collapsible groups so
/// the user has a visual divider without another card competing with
/// the hero.
class _InlineSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? trailingCount;
  final String? subtitle;

  const _InlineSectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailingCount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (trailingCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    trailingCount!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SecurityBadge({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class InterfaceSettingsTab extends StatefulWidget {
  const InterfaceSettingsTab({super.key});

  @override
  State<InterfaceSettingsTab> createState() => _InterfaceSettingsTabState();
}

class _InterfaceSettingsTabState extends State<InterfaceSettingsTab> {
  String _selectedLanguage = 'uz'; // Default to Uzbek

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      setState(() {
        _selectedLanguage = localeProvider.currentLanguageCode;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading current language: $e');
      setState(() {
        _selectedLanguage = 'uz'; // Fallback
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLanguageChange),
        content: Text(l10n.languageChangeWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update locale through provider
        final localeProvider = context.read<LocaleProvider>();
        await localeProvider.setLocaleByCode(languageCode);

        setState(() {
          _selectedLanguage = languageCode;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.languageChanged),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) print('Error changing language: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.languageChangeError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final isAutoDetected = localeProvider.isAutoDetected;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Settings Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.interfaceSettings,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Current Language Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.currentLanguage,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _getLanguageName(_selectedLanguage, l10n),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            // Auto-detection indicator
                            if (isAutoDetected) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.languageAutoDetected,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.secondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Available Languages
                      Text(
                        l10n.availableLanguages,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Language Options
                      _LanguageOption(
                        languageCode: 'uz',
                        languageName: l10n.uzbek,
                        isSelected: _selectedLanguage == 'uz',
                        onTap: () => _changeLanguage('uz'),
                      ),
                      const SizedBox(height: 8),
                      _LanguageOption(
                        languageCode: 'ru',
                        languageName: l10n.russian,
                        isSelected: _selectedLanguage == 'ru',
                        onTap: () => _changeLanguage('ru'),
                      ),
                      const SizedBox(height: 8),
                      _LanguageOption(
                        languageCode: 'en',
                        languageName: l10n.english,
                        isSelected: _selectedLanguage == 'en',
                        onTap: () => _changeLanguage('en'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional Interface Settings
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appearance,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Theme Toggle
                      ListTile(
                        leading: Icon(Icons.palette, color: colorScheme.primary),
                        title: Text(l10n.theme),
                        subtitle: Text(
                          ThemeController.I.mode.value == ThemeMode.dark
                              ? l10n.dark
                              : l10n.light,
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: ThemeToggle(
                            mode: ThemeController.I.mode.value,
                            onChanged: ThemeController.I.set,
                          ),
                        ),
                        onTap: () => ThemeController.I.set(
                          ThemeController.I.mode.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'uz':
        return l10n.uzbek;
      case 'ru':
        return l10n.russian;
      case 'en':
        return l10n.english;
      default:
        return l10n.uzbek;
    }
  }
}

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  MapProvider _selectedProvider = MapProvider.openStreetMap; // Default
  bool _isLoading = true;
  late ApiKeyService _apiKeyService;

  // API key input controllers
  final TextEditingController _googleApiKeyController = TextEditingController();
  final TextEditingController _yandexApiKeyController = TextEditingController();
  final TextEditingController _osmApiKeyController = TextEditingController();

  // API key visibility states
  bool _googleApiKeyVisible = false;
  bool _yandexApiKeyVisible = false;
  bool _osmApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeApiKeyService();
    _loadCurrentMapSettings();
  }

  @override
  void dispose() {
    _googleApiKeyController.dispose();
    _yandexApiKeyController.dispose();
    _osmApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeApiKeyService() async {
    try {
      await sl.isReady<ApiKeyService>();
      _apiKeyService = sl<ApiKeyService>();
      await _loadApiKeys();
    } catch (e) {
      if (kDebugMode) print('Error initializing API key service: $e');
      // Fallback: try to get from context
      try {
        _apiKeyService = ApiKeyService.instance;
        await _apiKeyService.initialize(
          context.read<SharedPreferencesService>(),
        );
        await _loadApiKeys();
      } catch (fallbackError) {
        if (kDebugMode)
          print(
            'Fallback API key service initialization failed: $fallbackError',
          );
      }
    }
  }

  Future<void> _loadApiKeys() async {
    try {
      final googleKey = await _apiKeyService.getApiKey(
        ApiKeyService.googleMapsApiKey,
      );
      final yandexKey = await _apiKeyService.getApiKey(
        ApiKeyService.yandexMapsApiKey,
      );
      final osmKey = await _apiKeyService.getApiKey(
        ApiKeyService.openStreetMapsApiKey,
      );

      setState(() {
        _googleApiKeyController.text = googleKey ?? '';
        _yandexApiKeyController.text = yandexKey ?? '';
        _osmApiKeyController.text = osmKey ?? '';
      });
    } catch (e) {
      if (kDebugMode) print('Error loading API keys: $e');
    }
  }

  Future<void> _loadCurrentMapSettings() async {
    try {
      final prefs = context.read<SharedPreferencesService>();
      final savedProvider = prefs.preferences.getString('default_map_provider');

      if (savedProvider != null) {
        setState(() {
          _selectedProvider = MapProvider.values.firstWhere(
            (provider) => provider.toString() == savedProvider,
            orElse: () => MapProvider.openStreetMap,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading map settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeDefaultMap(MapProvider provider) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDefaultMap),
        content: Text('${l10n.selectDefaultMap} ${provider.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = context.read<SharedPreferencesService>();
        await prefs.preferences.setString(
          'default_map_provider',
          provider.toString(),
        );

        setState(() {
          _selectedProvider = provider;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.defaultMapChanged),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) print('Error saving map settings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getMapProviderName(MapProvider provider, AppLocalizations l10n) {
    switch (provider) {
      case MapProvider.google:
        return l10n.googleMaps;
      case MapProvider.yandex:
        return l10n.yandexMaps;
      case MapProvider.openStreetMap:
        return l10n.openStreetMap;
    }
  }

  Future<String> _getApiKeyStatus(MapProvider provider) async {
    try {
      switch (provider) {
        case MapProvider.google:
          final hasKey = await _apiKeyService.hasApiKey(
            ApiKeyService.googleMapsApiKey,
          );
          if (kDebugMode) print('hasKey: $hasKey');
          return hasKey ? 'configured' : 'not_configured';
        case MapProvider.yandex:
          final hasKey = await _apiKeyService.hasApiKey(
            ApiKeyService.yandexMapsApiKey,
          );
          if (kDebugMode) print('hasKey: $hasKey');
          return hasKey ? 'configured' : 'not_configured';
        case MapProvider.openStreetMap:
          return 'key_not_required'; // OSM doesn't require API key
      }
    } catch (e) {
      if (kDebugMode) print('Error checking API key status: $e');
      return 'error';
    }
  }

  Future<void> _saveApiKey(String keyType, String apiKey) async {
    try {
      final result = await _apiKeyService.storeAndValidateApiKey(
        keyType,
        apiKey,
      );
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.apiKeySaved ??
                    'API kaliti muvaffaqiyatli saqlandi',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: ${result.errorMessage}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showApiKeyDialog(MapProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    String keyType;
    TextEditingController controller;
    String title;
    String hint;

    switch (provider) {
      case MapProvider.google:
        keyType = ApiKeyService.googleMapsApiKey;
        controller = _googleApiKeyController;
        title = 'Google Maps API Kaliti';
        hint = 'AIza...';
        break;
      case MapProvider.yandex:
        keyType = ApiKeyService.yandexMapsApiKey;
        controller = _yandexApiKeyController;
        title = 'Yandex Maps API Kaliti';
        hint = 'sizning-yandex-api-kalitingiz';
        break;
      case MapProvider.openStreetMap:
        // OSM doesn't require API key, but we can store custom config
        keyType = ApiKeyService.openStreetMapsApiKey;
        controller = _osmApiKeyController;
        title = 'OpenStreetMap Konfiguratsiyasi';
        hint = 'ixtiyoriy-maxsus-konfiguratsiya';
        break;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          obscureText: true, // Hide API key by default
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                Navigator.pop(context, apiKey);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveApiKey(keyType, result);
      setState(() {}); // Refresh UI to show updated status
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Settings Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l10n.mapSettings,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.mapConfiguration,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Current Map Provider
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currentMapProvider,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getMapProviderName(_selectedProvider, l10n),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(Icons.check_circle, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Available Maps
          Text(
            l10n.availableMaps,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...MapProvider.values.map(
            (provider) =>
                _buildMapProviderCard(provider, l10n, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildMapProviderCard(
    MapProvider provider,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = provider == _selectedProvider;

    return FutureBuilder<String>(
      future: _getApiKeyStatus(provider),
      builder: (context, snapshot) {
        final apiKeyStatus = snapshot.data ?? 'xatolik';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _changeDefaultMap(provider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Map Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.map, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getMapProviderName(provider, l10n),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${l10n.apiKey}: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              apiKeyStatus == 'key_not_required'
                                  ? l10n.apiKeyNotRequired
                                  : apiKeyStatus == 'configured'
                                  ? l10n.apiKeyConfigured
                                  : apiKeyStatus == 'not_configured'
                                  ? l10n.apiKeyNotConfigured
                                  : l10n.error,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    apiKeyStatus == 'configured' ||
                                        apiKeyStatus == 'key_not_required'
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => _showApiKeyDialog(provider),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.languageCode,
    required this.languageName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Language Flag/Icon (placeholder)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  languageCode.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
