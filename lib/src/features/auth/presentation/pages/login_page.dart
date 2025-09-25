import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';

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

  // Ranglar
  static const Color primaryColor = Color(0xFF50AAEA); // Asosiy ko'k
  static const Color primaryColorText = Color(0xFF0D7DD8); // Asosiy ko'k
  static const Color successColor = Color(0xFF3EBD84); // Yashil
  static const Color successColorText = Color(0xFF438E71); // Yashil
  static const Color accentColor = Color(0xFFFFE8A3); // To'q sariq

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _rememberMe = false;
        });
      }
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
    } catch (e) {}
  }

  void _onLoginButtonPressed() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      if (_rememberMe) {
        await prefs.saveCredentials(
          _usernameController.text,
          _passwordController.text,
        );
      } else {
        await prefs.clearCredentials();
      }
    } catch (e) {}
    context.read<AuthBloc>().add(
          LoginButtonPressed(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: accentColor.withOpacity(0.25),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            }
            if (state is AuthSuccess) {
              _saveUserData(state);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Login Successful! Role:  {state.user.role}')),
                );
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
                    ..showSnackBar(
                      SnackBar(content: Text('Unknown user role:  {state.user.role}')),
                    );
                  break;
              }
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeIn,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo yoki ilova nomi
                    Hero(
                      tag: 'app_logo',
                      child: Material(
                        color: Colors.transparent,
                        child: Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: primaryColor,
                          shadows: [
                            Shadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xush kelibsiz!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: primaryColorText,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kirish uchun login va parolni kiriting',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: primaryColorText.withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Username
                    _AnimatedInputField(
                      controller: _usernameController,
                      label: 'Login',
                      icon: Icons.person_outline,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    // Password
                    _AnimatedInputField(
                      controller: _passwordController,
                      label: 'Parol',
                      icon: Icons.lock_outline,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onPasswordToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Remember me va parolni ko'rsatish
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: successColor,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text(
                          'Eslab qolish',
                          style: TextStyle(
                            color: primaryColorText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              key: ValueKey(_isPasswordVisible),
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return state is AuthLoading
                            ? const Center(child: CircularProgressIndicator())
                            : AnimatedButton(
                                onTap: _onLoginButtonPressed,
                                text: 'KIRISH',
                                color: primaryColor,
                                textColor: Colors.white,
                                shadowColor: accentColor,
                              );
                      },
                    ),
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

// --- Animatsiyali input field ---
class _AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onPasswordToggle;

  const _AnimatedInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onPasswordToggle,
  });

  @override
  State<_AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<_AnimatedInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) {
        setState(() {
          _isFocused = focus;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: _isFocused ? widget.primaryColor : widget.accentColor,
            width: 1.5,
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && !widget.isPasswordVisible,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon, color: widget.primaryColor),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      widget.isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: widget.primaryColor,
                    ),
                    onPressed: widget.onPasswordToggle,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ),
    );
  }
}

// --- Animatsiyali Button ---
class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final Color color;
  final Color textColor;
  final Color shadowColor;

  const AnimatedButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.color,
    required this.textColor,
    required this.shadowColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor.withOpacity(_isPressed ? 0.1 : 0.25),
              blurRadius: _isPressed ? 4 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
              shadows: _isPressed
                  ? []
                  : [
                      Shadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}

