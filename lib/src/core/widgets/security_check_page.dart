import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/startup_access_bloc.dart';

/// =============================================================================
/// Security Check Page
/// =============================================================================
/// 
/// Bu sahifa ilova ishga tushganda xavfsizlik tekshiruvini amalga oshiradi.
/// Foydalanuvchi login qilgan bo'lsa, device va account bog'liqligini tekshiradi.
/// =============================================================================

class SecurityCheckPage extends StatefulWidget {
  const SecurityCheckPage({super.key});

  @override
  State<SecurityCheckPage> createState() => _SecurityCheckPageState();
}

class _SecurityCheckPageState extends State<SecurityCheckPage> {
  @override
  void initState() {
    super.initState();
    // Tekshiruvni boshlash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StartupAccessBloc>().add(CheckAccessEvent());
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
  }

  void _navigateToHome() {
    // Foydalanuvchi roliga qarab home sahifasiga o'tish
    Navigator.of(context).pushReplacementNamed(AppRouter.permissionCheckRoute);
  }

  void _navigateToBlocked(String message, String? reason) {
    Navigator.of(context).pushReplacementNamed(
      AppRouter.accessBlockedRoute,
      arguments: {
        'message': message,
        'reason': reason,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<StartupAccessBloc, StartupAccessState>(
            listener: (context, state) {
              if (state is StartupAccessNotLoggedIn) {
                _navigateToLogin();
              } else if (state is StartupAccessAllowed) {
                _navigateToHome();
              } else if (state is StartupAccessBlocked) {
                _navigateToBlocked(state.message, state.reason.name);
              } else if (state is StartupAccessError) {
                // Xatolik bo'lsa ham, davom etish
                _navigateToHome();
              }
            },
            builder: (context, state) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo yoki ilova nomi
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Gloria Marketing',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status text
                    Text(
                      _getStatusText(state),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Loading indicator
                    if (state is StartupAccessLoading || state is StartupAccessInitial)
                      const CircularProgressIndicator(),
                    
                    // Error state
                    if (state is StartupAccessError)
                      Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              context.read<StartupAccessBloc>().add(RetryAccessCheckEvent());
                            },
                            child: Text(AppLocalizations.of(context)!.retryCheck),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getStatusText(StartupAccessState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is StartupAccessInitial) {
      return l10n.securityCheckLoading;
    } else if (state is StartupAccessLoading) {
      return l10n.securityCheckVerifying;
    } else if (state is StartupAccessAllowed) {
      return l10n.securityCheckAllowed;
    } else if (state is StartupAccessBlocked) {
      return l10n.securityCheckBlocked;
    } else if (state is StartupAccessError) {
      return l10n.securityCheckError;
    } else if (state is StartupAccessNotLoggedIn) {
      return l10n.securityCheckLogin;
    }
    return '';
  }
}
