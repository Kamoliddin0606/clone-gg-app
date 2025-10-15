import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/data_sync_progress_widget.dart';

import '../../../../core/network/server_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isServerExplicitlySelected = false;
  late AnimationController _animationController;

  // (Saqladim — lekin pastda Theme.of(context) ranglari ishlatiladi)
  static const Color primaryColor = Color(0xFF50AAEA);
  static const Color primaryColorText = Color(0xFF0D7DD8);
  static const Color successColor = Color(0xFF3EBD84);
  static const Color accentColor = Color(0xFFFFE8A3);

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
    print(' tanlangan server malumotlar ${selected.toString()}');
    print(' tanlangan server url ${selected?.url}');
    print(' tanlangan server nomi ${selected?.name}');
    if (selected != null) {
      // Tanlovni saqlaymiz — ApiService baseUrl avtomatik yangilanadi
      await service.set(selected);
      _isServerExplicitlySelected = true;

      // (ixtiyoriy) eski login/credentiallarni tozalash:
      // await sl<SharedPreferencesService>().clearCredentials();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.label} server tanlandi')),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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
      if (_rememberMe) {
        await prefs.saveCredentials(_usernameController.text, _passwordController.text, _rememberMe);
      } else {
        await prefs.saveCredentials(_usernameController.text, _passwordController.text, _rememberMe);
      }
    } catch (_) {}

    // Ensure server is saved if not explicitly selected
    if (!_isServerExplicitlySelected) {
      try {
        final serverService = sl<ServerService>();
        await serverService.set(serverService.current.value);
      } catch (e) {
        // Log error but don't block login
        print('Error saving default server: $e');
      }
    }

    // First try online authentication
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
            const SnackBar(
              content: Text('Internet mavjud emas va saqlangan foydalanuvchi ma\'lumotlari topilmadi'),
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
            const SnackBar(
              content: Text('Internet mavjud emas va kiritilgan login saqlangan login bilan mos kelmaydi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get user from database by code
      final userData = await dbHelper.getUserByCode(prefsUserCode);
      if(userData?['base_url'] != sl<ServerService>().current.value.url) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saqlangan foydalanuvchi ma\'lumotlari joriy server bilan mos kelmaydi. Iltimos, serverni o\'zgartiring.'),
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
            const SnackBar(
              content: Text('Internet mavjud emas va foydalanuvchi ma\'lumotlari bazada topilmadi yoki mos kelmaydi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline kirishda xatolik: $e'),
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
        title: const Text('Internet mavjud emas'),
        content: Text(
          '${userData['name']} (${userData['username']}) sifatida offline rejimda kirishni xohlaysizmi?\n\n'
          'Offline rejimda siz mavjud ma\'lumotlar bilan ishlashingiz mumkin, lekin yangi ma\'lumotlarni yuklay olmaysiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Offline kirish'),
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
              SnackBar(content: Text('Unknown user role: $role')),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline login xatolik: $e'),
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

      bool needsDataSync = false;
      if (dbUser == null) {
        // No user in database, need to sync all data
        needsDataSync = true;
        print('No user found in database, will sync all data');
      } else {
        // Check if user data matches
        final userMatches = dbUser['code'] == state.user.code &&
            dbUser['name'] == state.user.name &&
            dbUser['warehouse_code'] == state.user.warehouseCode &&
            dbUser['code_project'] == state.user.codeProject &&
            dbUser['base_url'] == state.user.baseUrl;

        if (!userMatches) {
          // User data doesn't match, need to sync all data
          needsDataSync = true;
          print('User data mismatch, will sync all data');
        } else {
          print('User data matches, no sync needed');
        }
      }

      // Save user data to preferences
      await _saveUserData(state);

      // Save user to database for future offline use
      await dbHelper.saveUser({
        'code': state.user.code,
        'username': state.user.username,
        'password': '', // Don't store password in database
        'name': state.user.name,
        'role': state.user.role,
        'warehouse_code': state.user.warehouseCode,
        'code_project': state.user.codeProject,
        'base_url': state.user.baseUrl,
        'telegram_id': state.user.telegramID,
        'chat_id': state.user.chatID,
        'topic_id': state.user.topicID,
      });

      // If user data doesn't match, show sync progress dialog
      if (needsDataSync && mounted) {
        await _showDataSyncDialog(state.user);
      }

      // Show success message and navigate
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Login Successful!')));

        _navigateToHomePage(state.user.role);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Online login processing error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDataSyncDialog(UserEntity user) async {
    final dataSyncService = sl<DataSyncService>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ma\'lumotlar yangilanmoqda...'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<SyncStep>(
            stream: dataSyncService.syncAllUserDataWithProgress(
              userCode: user.code,
              password: '', // Password not needed for sync
              codeProject: user.codeProject,
              codeSklad: user.warehouseCode,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Xatolik: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    const Text('Kesh ma\'lumotlaridan foydalaniladi'),
                  ],
                );
              }

              final step = snapshot.data ?? SyncStep.checkingUser;
              final progress = (SyncStep.values.indexOf(step) + 1) / SyncStep.values.length;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(step.icon, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    step.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).round()}%'),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          ..showSnackBar(SnackBar(content: Text('Unknown user role: $role')));
    }
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        // // CHANGED: AppBar + ThemeToggle (light/dark)
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   title: Text('Kirish', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        //   centerTitle: false,
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: 8),
        //       child: ThemeToggle(
        //         mode: ThemeController.I.mode.value,
        //         onChanged: ThemeController.I.set,
        //       ),
        //     ),
        //   ],
        // ),

        // CHANGED: AgentHome’dagi kabi gradient fon va markaziy Card
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
              if (state is AuthFailure) {
                print('Auth failure: ${state.message}, type: ${state.errorType}');
                if (state.errorType == AuthErrorType.connectivity) {
                  // Only try offline login for connectivity issues
                  _tryOfflineLogin(_usernameController.text, _passwordController.text);
                } else {
                  // For authentication or server errors, just show the error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
              if (state is AuthSuccess) {
                // Online login successful
                _handleOnlineLoginSuccess(state);
              }
            },
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
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
    );
  }
  Widget _serverChip() {
    final server = sl<ServerService>();
    return ValueListenableBuilder<ServerEnv>(
      valueListenable: server.current,
      builder: (context, env, _) {
        final color = switch (env) {
          ServerEnv.Evyap    => Color.fromRGBO(0, 54, 152, 1.0),
          ServerEnv.Garnier => Color.fromRGBO(34, 50, 46, 1.0),
          ServerEnv.PPD    => Color.fromRGBO(0, 0, 0, 1.0),
          ServerEnv.Avon     => Color.fromRGBO(218, 0, 73, 1.0),
          ServerEnv.AvonTest     => Color.fromRGBO(80, 209, 248, 1.0),
        };
        return ActionChip(
          label: Text(env.label),
          avatar: CircleAvatar(radius: 6, backgroundColor: color),
          onPressed: () => _pickServer(context),
        );
      },
    );
  }
  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CHANGED: logo + subtile
        _serverChip(),
        Row(
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
        const SizedBox(height: 8),
        Text(
          l10n.enterCredentials,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
        ),
        const SizedBox(height: 20),

        // CHANGED: Inputlar — Material 3 uslubida, surface rang, outlineVariant border
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
            Text('Eslab qolish', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {}, // kerak bo‘lsa: parolni unutdingizmi
              child: Text(l10n.forgotPassword),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tugma — logika o‘zgarishsiz (BlocBuilder yuqorida)
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final loading = state is AuthLoading;
            return SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : _onLoginButtonPressed,
                child: loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3))
                    : Text(l10n.login),
              ),
            );
          },
        ),
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
        validator: (v) => (v == null || v.trim().isEmpty) ? '$label kiriting' : null,
      ),
    );
  }
}
