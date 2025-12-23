import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/data_sync_progress_widget.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/Utility/formatter.dart';
import '../../../navbars/agent_bottom_nav_bar.dart';
import 'agent_home_modern.dart';

class AgentHomePage extends StatefulWidget {
  const AgentHomePage({super.key});

  @override
  State<AgentHomePage> createState() => _AgentHomePageState();
}

class _AgentHomePageState extends State<AgentHomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  KpiData? _kpiData;
  String userName = "Agent User";
  String userCode = "";
  String password = "";
  String warehouseCode = "";
  String codeProject = "";
  String telegramID = "";
  String chatID = "";
  String topicID = "";
  bool _isLoadingKpi = false;
  bool _isKpiCardsExpanded = false;
  bool _isDataSyncInProgress = false;
  Stream<SyncStep>? _syncStepStream;

  late AnimationController _planFactController;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Rang sxemasi
  static const Color primaryColor = Color(0xFF50AAEA); // Asosiy ko'k
  static const Color primaryColorText = Color(0xFF0D7DD8); // Asosiy ko'k
  static const Color successColor = Color(0xFF3EBD84); // Yashil
  static const Color successColorText = Color(0xFF438E71); // Yashil
  static const Color accentColor = Color(0xFFFFE8A3); // To'q sariq

  @override
  bool get wantKeepAlive => true; // State saqlanib qolinadi

  @override
  void initState() {
    super.initState();
    _planFactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _planFactController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleKpiCards() {
    setState(() {
      _isKpiCardsExpanded = !_isKpiCardsExpanded;
    });

    if (_isKpiCardsExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
        warehouseCode = prefs.getWarehouseCode() ?? "";
        codeProject = prefs.getCodeProject() ?? "";
        userName = prefs.getUserName() ?? "Agent User";
        telegramID = prefs.getTelegramID() ?? "";
        chatID = prefs.getChatID() ?? "";
        topicID = prefs.getTopicID() ?? "";
      });

      // Check if preferences user matches database user
      final dbHelper = DatabaseHelper();
      final dbUsers = await dbHelper.getAllUsers();
      final dbUser = dbUsers.isNotEmpty ? dbUsers.first : null;

      final prefsUserCode = userCode;
      final prefsUserName = userName;
      if (! prefs.isOfflineMode()) {


        if (dbUser != null &&
            dbUser['code'] == prefsUserCode &&
            dbUser['username'] == prefsUserName) {
          // User matches, continue with normal flow
          if (userCode.isNotEmpty && password.isNotEmpty) {
            // Update user data in preferences (ensure it's current)
            await _updateUserDataInPreferences();
            // Check if user data needs to be synced
            await _checkAndSyncUserData();

          }
        } else {
          // User doesn't match, clear cache and load new data
          final repository = sl<AgentRepository>();
          await repository.clearCache();

          if (userCode.isNotEmpty && password.isNotEmpty) {
            // Update user data in preferences (ensure it's current)
            await _updateUserDataInPreferences();
            // Check if user data needs to be synced
            await _checkAndSyncUserData();
          }

            await repository.savePrefsToUsers();

        }
      }
      else{
          if (userCode.isNotEmpty && password.isNotEmpty) {
            // Update user data in preferences (ensure it's current)
            await _updateUserDataInPreferences();
            // Check if user data needs to be synced
            await _checkAndSyncUserData();
          }
      }

    } catch (e) {
      if (kDebugMode) print('Error loading user data: $e');
    }
  }

  Future<void> _updateUserDataInPreferences() async {
    try {
      // Since user data comes from login API and is already saved,
      // we can refresh it here if needed. For now, we'll ensure it's loaded properly.
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      // Re-save current user data to ensure it's up to date
      await prefs.saveUserData(
        userCode: userCode,
        userName: userName,
        warehouseCode: warehouseCode,
        codeProject: codeProject,
        telegramID: telegramID,
        chatID: chatID,
        topicID: topicID,
      );

      if (kDebugMode) {
        print('User data updated in preferences: $userCode, $userName, $warehouseCode, $codeProject');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user data in preferences: $e');
      }
    }
  }

  Future<void> _checkAndSyncUserData() async {
    try {
      final dataSyncService = sl<DataSyncService>();
      final prefs = sl<SharedPreferencesService>();

      // Check if we're in offline mode
      final isOffline = prefs.isOfflineMode();

      if (isOffline) {
        // Offline mode - work with existing database data
        if (kDebugMode) {
          print('Offline mode detected - loading cached data');
        }
        await _loadKpiData();
        return;
      }

      // Online mode - check if preferences user matches database user
      final isValid = await dataSyncService.validateUserWithDatabase();

      if (!isValid) {
        // User data doesn't match - start sync with progress
        setState(() {
          _isDataSyncInProgress = true;
          _syncStepStream = dataSyncService.syncAllUserDataWithProgress(
            userCode: userCode,
            password: password,
            codeProject: codeProject,
            codeSklad: warehouseCode,
          );
        });
      } else {
        // User data matches - load existing data
        await _loadKpiData();
      }
    } catch (e) {
      if (kDebugMode) print('Error checking user data: $e');
      // Load cached data as fallback
      await _loadKpiData();
    }
  }

  void _onDataSyncComplete() {
    setState(() {
      _isDataSyncInProgress = false;
      _syncStepStream = null;
    });
    // Load fresh data after sync
    _loadKpiData();
  }

  Future<void> _loadKpiData() async {
    if (userCode.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoadingKpi = true;
    });

    try {
      final repository = sl<AgentRepository>();
      final kpiData = await repository.getKpiData(
        userCode: userCode,
        password: password,
      );

      setState(() {
        _kpiData = kpiData;
        _isLoadingKpi = false;
      });
      _planFactController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isLoadingKpi = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KPI ma\'lumotlarini yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshKpi() async {
    final prefs = sl<SharedPreferencesService>();
    if (prefs.isOfflineMode()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siz offline rejimdasiz. Malumotlarni yangilash imkoni mavjud emas')),
      );
      return;
      return ;
    }
    if (userCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foydalanuvchi ma\'lumotlari mavjud emas')),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KPI ma\'lumotlari yangilanmoqda...')),
      );
    }

    setState(() {
      _isLoadingKpi = true;
    });

    try {
      final repository = sl<AgentRepository>();
      final kpiData = await repository.getKpiData(
        userCode: userCode,
        password: password,
        forceRefresh: true,
      );

      setState(() {
        _kpiData = kpiData;
        _isLoadingKpi = false;
      });
      _planFactController.forward(from: 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KPI ma\'lumotlari yangilandi'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingKpi = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KPI ma\'lumotlarini yangilashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin uchun majburiy
    final theme = Theme.of(context);
    final prefs = sl<SharedPreferencesService>();
    final isOffline = prefs.isOfflineMode();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AgentHomeModern(
            userName: userName,
            userCode: userCode,
            kpi: KpiView(
              salesSum: _kpiData?.totalForecast,
              itemsSold: null,
              customersServed: null,
              totalPercent: _kpiData?.totalPercent,
              akbPlan: _kpiData?.akbPlan,
              akbFact: _kpiData?.akbFact,
              akbPercent: _kpiData?.akbPercent,
              okb: _kpiData?.okb,
            ),
            onRefresh: _refreshKpi,
            onSettings: () => Navigator.pushNamed(context, AppRouter.settingsRoute),
            onLogout: () => _showLogoutDialog(),
          ),

          // Data sync progress overlay
          if (_isDataSyncInProgress && _syncStepStream != null)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: DataSyncProgressWidget(
                  syncStepStream: _syncStepStream!,
                  onComplete: _onDataSyncComplete,
                ),
              ),
            ),
        ],
      ),
      // BottomNavigationBar ni olib tashladik - endi MainAgentScreen boshqaradi
    );
  }

  Widget _buildUserProfileSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.7),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: primaryColorText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: $userCode",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanFactProgress(ThemeData theme) {
    final plan = _kpiData?.plan != null ? num.tryParse(_kpiData!.plan) ?? 0 : 0;
    final fact = _kpiData?.fact != null ? num.tryParse(_kpiData!.fact) ?? 0 : 0;
    final percent = plan > 0 ? (fact / plan).clamp(0, 1).toDouble() : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleKpiCards,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "KPI Plan / Fact",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColorText,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isKpiCardsExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColorText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: plan.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Plan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                formatSum(value),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColorText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: fact.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fact", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                formatSum(value),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: successColorText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _planFactController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: percent * _planFactController.value,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(successColorText),
                      borderRadius: BorderRadius.circular(8),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(percent * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: successColorText,
                      ),
                    ),
                    Text(
                      _isKpiCardsExpanded ? "Yopish" : "Batafsil",
                      style: TextStyle(
                        color: primaryColorText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedKpiCard(
              title: "Total %",
              value: _kpiData?.totalPercent != null
                  ? formatProcent(num.tryParse(_kpiData!.totalPercent))
                  : "-",
              color: accentColor,
              icon: Icons.percent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AnimatedKpiCard(
              title: "Total Forecast",
              value: _kpiData?.totalForecast != null
                  ? formatSum(num.tryParse(_kpiData!.totalForecast))
                  : "-",
              color: primaryColorText,
              icon: Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAkbOkbSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB",
                  value: _kpiData?.akbPlan ?? "-",
                  color: primaryColorText,
                  icon: Icons.account_balance,
                  subtitle: "Plan",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedKpiCard(
                  title: "OKB",
                  value: _kpiData?.okb ?? "-",
                  color: successColorText,
                  icon: Icons.all_inbox,
                  subtitle: "Fact",
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB ",
                  value: _kpiData?.akbFact ?? "-",
                  color: primaryColorText,
                  icon: Icons.check_circle,
                  subtitle: "Fact",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedKpiCard(
                  title: "AKB ",
                  value: _kpiData?.totalPercent != null
                      ? formatProcent(num.tryParse(_kpiData!.akbPercent))
                      : "-",
                  color: successColorText,
                  icon: Icons.report_gmailerrorred,
                  subtitle: "Fact %",
                ),
              ),
            ],
          ),
        ],

      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.7),
          Colors.transparent,
        ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // _buildRefreshButton(theme),
              // const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),

    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _isLoadingKpi
          ? Card(
        key: const ValueKey('loading'),
        elevation: 4,
        color: primaryColorText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      )
          : Card(
        key: const ValueKey('button'),
        elevation: 4,
        color: primaryColorText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _refreshKpi,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Yangilash',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(

      child: Row(
        children: [
          Expanded(
            child: _AnimatedActionCard(
              title: 'Vazifalar',
              subtitle: 'Savdo nuqtalari',
              color: successColor,
              icon: Icons.list_alt,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.tradingPointsRoute);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnimatedActionCard(
              title: 'Shartnomalar',
              subtitle: 'Shartnomalar',
              color: primaryColor,
              icon: Icons.assignment,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shartnomalar sahifasi hali tayyor emas')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chiqish'),
          content: const Text('Haqiqatan ham ilovadan chiqmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => _logout(context),
              child: const Text('Chiqish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // await sl.isReady<SharedPreferencesService>();
      // final prefs = sl<SharedPreferencesService>();
      // await prefs.clearCredentials();
    } catch (e) {}
    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.loginRoute,
            (route) => false,
      );
    }
  }
}

class _AnimatedKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _AnimatedKpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}