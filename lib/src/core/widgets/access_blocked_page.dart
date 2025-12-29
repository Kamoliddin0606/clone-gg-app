import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart' show sl;
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// =============================================================================
/// Access Blocked Page
/// =============================================================================
/// 
/// Bu sahifa foydalanuvchi bloklangan holatda ko'rsatiladi.
/// Foydalanuvchi logout qilishi yoki support bilan bog'lanishi mumkin.
/// =============================================================================

class AccessBlockedPage extends StatelessWidget {
  final String message;
  final String? reason;

  const AccessBlockedPage({
    super.key,
    required this.message,
    this.reason,
  });

  /// Route arguments dan yaratish
  factory AccessBlockedPage.fromArguments(Map<String, dynamic>? arguments) {
    return AccessBlockedPage(
      message: arguments?['message'] as String? ?? '',
      reason: arguments?['reason'] as String?,
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
              Theme.of(context).colorScheme.error.withOpacity(0.1),
              Theme.of(context).colorScheme.errorContainer.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.block,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    AppLocalizations.of(context)!.accessDenied,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message card
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          if (reason != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.reason}: ${_getReasonText(context, reason!)}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logout button
                      OutlinedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout),
                        label: Text(AppLocalizations.of(context)!.logout),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Retry button
                      FilledButton.icon(
                        onPressed: () => _handleRetry(context),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retryCheck),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Support button
                  TextButton.icon(
                    onPressed: () => _handleSupport(context),
                    icon: const Icon(Icons.support_agent),
                    label: Text(AppLocalizations.of(context)!.contactSupportTeam),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getReasonText(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason.toLowerCase()) {
      case 'accountalreadyboundtoanotherdevice':
        return l10n.accessBlockedReasonAccountBound;
      case 'devicealreadyhasanotheraccount':
        return l10n.accessBlockedReasonDeviceBound;
      case 'highriskdevice':
        return l10n.accessBlockedReasonHighRisk;
      case 'securitypolicyviolation':
        return l10n.accessBlockedReasonPolicyViolation;
      default:
        return l10n.accessBlockedReasonUnknown;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logoutConfirmTitle),
        content: Text(AppLocalizations.of(context)!.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Clear user data
      final prefs = sl<SharedPreferencesService>();
      await prefs.clearUserData();
      
      // Navigate to login
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
          (route) => false,
        );
      }
    }
  }

  void _handleRetry(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRouter.securityCheckRoute);
  }

  Future<void> _handleSupport(BuildContext context) async {
    // Telegram support link
    const telegramUrl = 'https://t.me/gloria_support';
    
    try {
      final uri = Uri.parse(telegramUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram ochilmadi. Iltimos, @gloria_support ga yozing.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    }
  }
}
