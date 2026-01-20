import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_access_control_service.dart';

/// Modern, professional access control verification page
/// 
/// This page displays the access verification process with:
/// - Beautiful animations and transitions
/// - Clear status indicators
/// - User-friendly error messages
/// - Professional design following Material Design 3 guidelines
class AccessControlPage extends StatefulWidget {
  final AppAccessControlService accessControlService;
  
  const AccessControlPage({
    super.key,
    required this.accessControlService,
  });

  @override
  State<AccessControlPage> createState() => _AccessControlPageState();
}

class _AccessControlPageState extends State<AccessControlPage> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  AccessCheckResult? _checkResult;
  bool _isChecking = true;
  String _currentStatus = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
    
    // Start access check after the first frame when context is fully available
    // This prevents the error: "dependOnInheritedWidgetOfExactType was called before initState completed"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAccessCheck();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Perform the access check with status updates
  Future<void> _performAccessCheck() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Update status: Checking
      setState(() {
        _currentStatus = l10n.accessControlChecking;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update status: Checking internet
      setState(() {
        _currentStatus = l10n.accessControlCheckingInternet;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Perform actual check
      final result = await widget.accessControlService.performInitialAccessCheck();
      
      // Update status: Verifying time
      if (result.isAccessGranted) {
        setState(() {
          _currentStatus = l10n.accessControlVerifyingTime;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Show result
      setState(() {
        _checkResult = result;
        _isChecking = false;
      });
      
      // If access granted, navigate to main app after delay
      if (result.isAccessGranted) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToMainApp();
        }
      }
    } catch (e) {
      setState(() {
        _checkResult = AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.error,
          message: e.toString(),
        );
        _isChecking = false;
      });
    }
  }
  
  /// Navigate to main app
  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed(AppRouter.securityCheckRoute);
  }
  
  /// Retry access check
  /// Resets navigation stack to restart the app flow
  void _retryCheck() {
    // Reset navigation stack to access control page
    // This ensures a clean restart of the access verification flow
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.accessControlRoute,
      (route) => false,
    );
  }
  
  /// Exit app
  void _exitApp() {
    SystemNavigator.pop();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildContent(context, theme, l10n),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build main content based on current state
  Widget _buildContent(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    if (_isChecking) {
      return _buildCheckingState(theme, l10n);
    } else if (_checkResult != null) {
      if (_checkResult!.isAccessGranted) {
        return _buildSuccessState(theme, l10n);
      } else {
        return _buildDeniedState(theme, l10n);
      }
    }
    
    return const SizedBox.shrink();
  }
  
  /// Build checking state UI
  Widget _buildCheckingState(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              l10n.accessControlTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Status text
            Text(
              _currentStatus,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Progress indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build success state UI
  Widget _buildSuccessState(ThemeData theme, AppLocalizations l10n) {
    final daysRemaining = _checkResult?.daysRemaining ?? 0;
    final isOffline = _checkResult?.isOfflineMode ?? false;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              l10n.accessControlGranted,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Days remaining
            if (daysRemaining > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: daysRemaining <= 7 
                      ? Colors.orange.withOpacity(0.1)
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.accessDaysRemaining(daysRemaining),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: daysRemaining <= 7 
                        ? Colors.orange.shade700
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            
            // Offline mode indicator
            if (isOffline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.accessOfflineMode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Loading message
            Text(
              l10n.accessLoadingApp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build denied state UI
  Widget _buildDeniedState(ThemeData theme, AppLocalizations l10n) {
    final reason = _checkResult?.reason;
    final message = _checkResult?.message;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title based on reason
            Text(
              _getTitleForReason(reason, l10n),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              _getMessageForReason(reason, message, l10n),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(reason, theme, l10n),
          ],
        ),
      ),
    );
  }
  
  /// Get title text based on denial reason
  String _getTitleForReason(AccessDenialReason? reason, AppLocalizations l10n) {
    switch (reason) {
      case AccessDenialReason.expired:
        return l10n.accessExpired;
      case AccessDenialReason.timeManipulation:
        return l10n.accessTimeManipulation;
      case AccessDenialReason.internetRequired:
        return l10n.accessInternetRequired;
      case AccessDenialReason.error:
      default:
        return l10n.accessVerificationError;
    }
  }
  
  /// Get message text based on denial reason
  String _getMessageForReason(
    AccessDenialReason? reason, 
    String? customMessage,
    AppLocalizations l10n,
  ) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }
    
    switch (reason) {
      case AccessDenialReason.expired:
        return l10n.accessExpiredMessage;
      case AccessDenialReason.timeManipulation:
        return l10n.accessTimeManipulationMessage;
      case AccessDenialReason.internetRequired:
        return l10n.accessInternetRequiredMessage;
      case AccessDenialReason.error:
      default:
        return l10n.accessVerificationErrorMessage;
    }
  }
  
  /// Build action buttons based on denial reason
  Widget _buildActionButtons(
    AccessDenialReason? reason,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        // Retry button (for certain reasons)
        if (reason == AccessDenialReason.internetRequired ||
            reason == AccessDenialReason.error) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _retryCheck,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.accessRetry),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Contact support button (for expired)
        if (reason == AccessDenialReason.expired) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // Data is already cleared by TimeVerificationService.blockUserAndClearData()
                // Reset navigation stack to access control page to restart the app flow
                // This will re-run the access check and navigate to login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.accessControlRoute,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.support_agent),
              label: Text(l10n.accessContactSupport),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Exit button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exitApp,
            icon: const Icon(Icons.exit_to_app),
            label: Text(l10n.accessExit),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
