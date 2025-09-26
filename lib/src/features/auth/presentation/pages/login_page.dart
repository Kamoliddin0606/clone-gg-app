import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../theme/theme_controller.dart';
import '../../../../theme/theme_toggle.dart';

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
  late AnimationController _animationController;

  // (Saqladim — lekin pastda Theme.of(context) ranglari ishlatiladi)
  static const Color primaryColor = Color(0xFF50AAEA);
  static const Color primaryColorText = Color(0xFF0D7DD8);
  static const Color successColor = Color(0xFF3EBD84);
  static const Color accentColor = Color(0xFFFFE8A3);

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
      if (prefs.isRememberMeEnabled()) {
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
      );
    } catch (_) {}
  }

  void _onLoginButtonPressed() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      if (_rememberMe) {
        await prefs.saveCredentials(_usernameController.text, _passwordController.text);
      } else {
        await prefs.clearCredentials();
      }
    } catch (_) {}
    context.read<AuthBloc>().add(LoginButtonPressed(
      username: _usernameController.text,
      password: _passwordController.text,
    ));
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
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                  ));
              }
              if (state is AuthSuccess) {
                _saveUserData(state);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Login Successful!')));
                switch (state.user.role) {
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
                      ..showSnackBar(SnackBar(content: Text('Unknown user role:  ${state.user.role}')));
                }
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

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CHANGED: logo + subtile
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
                'Xush kelibsiz!',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Kirish uchun login va parolni kiriting',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
        ),
        const SizedBox(height: 20),

        // CHANGED: Inputlar — Material 3 uslubida, surface rang, outlineVariant border
        _M3Input(
          controller: _usernameController,
          label: 'Login',
          prefix: const Icon(Icons.person_outline),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {},
        ),
        const SizedBox(height: 12),
        _M3Input(
          controller: _passwordController,
          label: 'Parol',
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
              child: const Text('Parolni unutdingizmi?'),
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
                    : const Text('Kirish'),
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
