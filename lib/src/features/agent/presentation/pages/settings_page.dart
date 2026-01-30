import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/providers/locale_provider.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_toggle.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings/data_sync_tab.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _initialTabIndex,
    ); // Changed from 3 to 4
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
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PermissionsTab(),
                const MapsTab(),
                const DataSyncTab(), // NEW TAB CONTENT
                InterfaceSettingsTab(),
              ],
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

  @override
  void initState() {
    super.initState();
    _loadPermissions();
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

  String _getPermissionCategory(String key, AppLocalizations l10n) {
    switch (key) {
      case 'skipTINduplicateCheck':
      case 'allowCreationWithoutTIN':
      case 'allowCreatingPointOfSale':
        return AppLocalizations.of(context)!.dataValidation;
      case 'visit':
      case 'strictSequence':
      case 'unplannedOrder':
      case 'plannedRoute':
        return AppLocalizations.of(context)!.visitManagement;
      case 'editClientCoordinates':
        return l10n.editInformation;
      default:
        return AppLocalizations.of(context)!.general;
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

  Color _getCategoryColor(
    String category,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    switch (category) {
      case 'dataValidation':
        return colorScheme.primary;
      case 'visitManagement':
        return colorScheme.secondary;
      case 'Malumotlarni tahrirlash':
        return colorScheme.tertiary;
      default:
        return colorScheme.tertiary;
    }
  }

  Map<String, List<String>> get _groupedPermissions {
    if (_permissions == null) return {};

    final l10n = AppLocalizations.of(context)!;
    final grouped = <String, List<String>>{};

    // Add main permissions
    final mainPermissions = [
      'skipTINduplicateCheck',
      'allowCreationWithoutTIN',
      'allowCreatingPointOfSale',
      'visit',
      'strictSequence',
      'unplannedOrder',
      'plannedRoute',
      'editClientCoordinates',
    ];

    for (final key in mainPermissions) {
      final category = _getPermissionCategory(key, l10n);
      grouped.putIfAbsent(category, () => []).add(key);
    }

    return grouped;
  }

  bool _getPermissionValue(String key) {
    if (_permissions == null) return false;

    switch (key) {
      case 'skipTINduplicateCheck':
        return _permissions!.skipTINduplicateCheck;
      case 'allowCreationWithoutTIN':
        return _permissions!.allowCreationWithoutTIN;
      case 'allowCreatingPointOfSale':
        return _permissions!.allowCreatingPointOfSale;
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

  // Visit Steps section
  Widget _buildVisitStepsSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    if (_permissions == null || _permissions!.visitSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.visitSteps,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._permissions!.visitSteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${step.stepCode}',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
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
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            step.stepRequired
                                ? AppLocalizations.of(
                                    context,
                                  )!.mandatoryExecution
                                : AppLocalizations.of(context)!.optional,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: step.stepRequired
                                      ? colorScheme.error
                                      : colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      step.stepRequired
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: step.stepRequired
                          ? colorScheme.error
                          : colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permissions Overview
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
                        Icons.security,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.agentPermissions,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.userPermissionsAndVisitSteps,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Permissions by Category
          Text(
            AppLocalizations.of(context)!.permissions,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._groupedPermissions.entries.map((entry) {
            final category = entry.key;
            final permissions = entry.value;
            final categoryColor = _getCategoryColor(
              category,
              l10n,
              colorScheme,
            );

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, color: categoryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${permissions.where((p) => _getPermissionValue(p)).length}/${permissions.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...permissions.map((permissionKey) {
                    final isEnabled = _getPermissionValue(permissionKey);
                    return ListTile(
                      title: Text(
                        _getPermissionLabel(permissionKey, l10n),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isEnabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: isEnabled
                          ? null
                          : Text(
                              AppLocalizations.of(context)!.permissionDenied,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                      leading: Icon(
                        _getPermissionIcon(permissionKey),
                        color: isEnabled
                            ? categoryColor
                            : colorScheme.onSurfaceVariant,
                      ),
                      trailing: Icon(
                        isEnabled ? Icons.check_circle : Icons.cancel,
                        color: isEnabled
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // Visit Steps Section
          _buildVisitStepsSection(l10n, colorScheme),
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
