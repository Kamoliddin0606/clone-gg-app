import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';

enum SyncStep {
  checkingUser(Icons.person_search),
  clearingData(Icons.cleaning_services),
  syncingKpi(Icons.bar_chart),
  syncingClients(Icons.people),
  syncingProducts(Icons.inventory),
  syncingPriceTypes(Icons.price_change),
  syncingBusinessRegions(Icons.location_on),
  syncingUserWarehouses(Icons.warehouse),
  syncingProductPrices(Icons.attach_money),
  syncingProductBalances(Icons.balance),
  syncingClientContracts(Icons.description),
  updatingClientContractStatus(Icons.update),
  syncingContractTypes(Icons.category),
  syncingDistrictContracting(Icons.location_city),
  syncingOrderStatuses(Icons.list_alt),
  syncingOrders(Icons.shopping_cart),
  syncingSalesReqPermissions(Icons.security),
  syncingPlannedRoutes(Icons.route),
  syncingUserOrganizations(Icons.business),
  syncingUserProjects(Icons.folder_special),
  syncingPromotions(Icons.local_offer),
  syncingMapTokens(Icons.map),
  syncingReports(Icons.analytics),
  syncingThumbnails(Icons.image),
  completed(Icons.check_circle),
  error(Icons.error);

  const SyncStep(this.icon);
  final IconData icon;

  String getMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SyncStep.checkingUser:
        return l10n?.syncStepCheckingUser ?? 'Checking user...';
      case SyncStep.clearingData:
        return l10n?.syncStepClearingData ?? 'Clearing old data...';
      case SyncStep.syncingKpi:
        return l10n?.syncStepSyncingKpi ?? 'Loading KPI data...';
      case SyncStep.syncingClients:
        return l10n?.syncStepSyncingClients ?? 'Loading clients list...';
      case SyncStep.syncingProducts:
        return l10n?.syncStepSyncingProducts ?? 'Loading products...';
      case SyncStep.syncingPriceTypes:
        return l10n?.syncStepSyncingPriceTypes ?? 'Loading price types...';
      case SyncStep.syncingBusinessRegions:
        return l10n?.syncStepSyncingBusinessRegions ?? 'Loading business regions...';
      case SyncStep.syncingUserWarehouses:
        return l10n?.syncStepSyncingUserWarehouses ?? 'Loading user warehouses...';
      case SyncStep.syncingProductPrices:
        return l10n?.syncStepSyncingProductPrices ?? 'Loading product prices...';
      case SyncStep.syncingProductBalances:
        return l10n?.syncStepSyncingProductBalances ?? 'Loading product balances...';
      case SyncStep.syncingClientContracts:
        return l10n?.syncStepSyncingClientContracts ?? 'Loading client contracts...';
      case SyncStep.updatingClientContractStatus:
        return l10n?.syncStepUpdatingClientContractStatus ?? 'Updating client contract statuses...';
      case SyncStep.syncingContractTypes:
        return l10n?.syncStepSyncingContractTypes ?? 'Loading contract types...';
      case SyncStep.syncingDistrictContracting:
        return l10n?.syncStepSyncingDistrictContracting ?? 'Loading districts...';
      case SyncStep.syncingOrderStatuses:
        return l10n?.syncStepSyncingOrderStatuses ?? 'Loading order statuses...';
      case SyncStep.syncingOrders:
        return l10n?.syncStepSyncingOrders ?? 'Loading orders...';
      case SyncStep.syncingSalesReqPermissions:
        return l10n?.syncStepSyncingSalesReqPermissions ?? 'Loading agent permissions...';
      case SyncStep.syncingPlannedRoutes:
        return l10n?.syncStepSyncingPlannedRoutes ?? 'Loading planned routes...';
      case SyncStep.syncingUserOrganizations:
        return l10n?.syncStepSyncingUserOrganizations ?? 'Loading user organizations...';
      case SyncStep.syncingUserProjects:
        return l10n?.syncStepSyncingUserProjects ?? 'Loading user projects...';
      case SyncStep.syncingPromotions:
        return l10n?.syncStepSyncingPromotions ?? 'Loading promotions...';
      case SyncStep.syncingMapTokens:
        return l10n?.syncStepSyncingMapTokens ?? 'Loading map tokens...';
      case SyncStep.syncingReports:
        return l10n?.syncStepSyncingReports ?? 'Loading reports...';
      case SyncStep.syncingThumbnails:
        return l10n?.syncStepSyncingThumbnails ?? 'Loading images...';
      case SyncStep.completed:
        return l10n?.syncStepCompleted ?? 'Data updated!';
      case SyncStep.error:
        return l10n?.syncStepError ?? 'An error occurred';
    }
  }
}

class DataSyncProgressWidget extends StatefulWidget {
  final Stream<SyncStep> syncStepStream;
  final VoidCallback onComplete;
  final Function(dynamic error)? onError;

  const DataSyncProgressWidget({
    super.key,
    required this.syncStepStream,
    required this.onComplete,
    this.onError,
  });

  @override
  State<DataSyncProgressWidget> createState() => _DataSyncProgressWidgetState();
}

class _DataSyncProgressWidgetState extends State<DataSyncProgressWidget> {
  SyncStep _currentStep = SyncStep.checkingUser;
  double _progress = 0.0;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    widget.syncStepStream.listen(
      (step) {
        setState(() {
          _currentStep = step;
          _progress = (SyncStep.values.indexOf(step) + 1) / SyncStep.values.length;
          _hasError = false;
          _errorMessage = null;
        });

        if (step == SyncStep.completed) {
          Future.delayed(const Duration(seconds: 1), widget.onComplete);
        }
      },
      onError: (error) {
        setState(() {
          _currentStep = SyncStep.error;
          _progress = 1.0;
          _hasError = true;
          _errorMessage = _getErrorMessage(error);
        });

        // Call the error callback if provided
        widget.onError?.call(error);

        // Auto-complete after showing error for 3 seconds
        Future.delayed(const Duration(seconds: 3), widget.onComplete);
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    final l10n = AppLocalizations.of(context);
    if (error is PaymentRequiredException) {
      return l10n?.paymentRequiredError ?? 'Payment required. Please check your subscription.';
    } else if (error is AuthenticationException) {
      return l10n?.authenticationError ?? 'Authentication error. Please login again.';
    } else if (error is ForbiddenException) {
      return l10n?.accessForbiddenError ?? 'Access forbidden. You don\'t have permission.';
    } else if (error is NotFoundException) {
      return l10n?.serviceNotFoundError ?? 'Service not found. Please contact support.';
    } else if (error is ServerUnavailableException) {
      return l10n?.serverUnavailableError ?? 'Server unavailable. Please try again later.';
    } else {
      return l10n?.dataUpdateError ?? 'Error updating data. Using cached data.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentStep == SyncStep.completed
                  ? colorScheme.primaryContainer
                  : colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentStep.icon,
              size: 48,
              color: _currentStep == SyncStep.completed
                  ? colorScheme.primary
                  : colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            _currentStep == SyncStep.completed
                ? AppLocalizations.of(context)?.syncSuccessTitle ?? 'Success!'
                : AppLocalizations.of(context)?.syncUpdatingTitle ?? 'Updating data...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            _currentStep.getMessage(context),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStep == SyncStep.completed
                    ? colorScheme.primary
                    : colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Progress Text
          Text(
            '${(_progress * 100).round()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}