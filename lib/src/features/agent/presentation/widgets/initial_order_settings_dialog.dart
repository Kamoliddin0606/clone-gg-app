import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';

/// Initial Order Settings Dialog
///
/// Professional, user-friendly dialog that appears when:
/// - User enters order creation page for the first time
/// - Cart is empty (no selected products)
/// - No saved settings exist in database
///
/// This dialog allows users to configure essential order settings:
/// - Organization selection (required)
/// - Warehouse selection (required)
/// - Price type selection (required)
///
/// Features:
/// - Clean, modern Material Design 3 UI
/// - Localized content (English, Russian, Uzbek)
/// - Input validation with clear error messages
/// - Responsive layout with proper spacing
/// - Smooth animations and transitions
/// - Cannot be dismissed without completing settings
/// - Professional color scheme and typography
///
/// Usage:
/// ```dart
/// final result = await showDialog<Map<String, String>>(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => InitialOrderSettingsDialog(
///     organizations: organizations,
///     warehouses: warehouses,
///     priceTypes: priceTypes,
///   ),
/// );
/// ```
class InitialOrderSettingsDialog extends StatefulWidget {
  /// List of available organizations to choose from
  final List<UserOrganization> organizations;

  /// List of available warehouses to choose from
  final List<UserWarehouse> warehouses;

  /// List of available price types to choose from
  final List<PriceType> priceTypes;

  const InitialOrderSettingsDialog({
    super.key,
    required this.organizations,
    required this.warehouses,
    required this.priceTypes,
  });

  @override
  State<InitialOrderSettingsDialog> createState() =>
      _InitialOrderSettingsDialogState();
}

class _InitialOrderSettingsDialogState
    extends State<InitialOrderSettingsDialog> with SingleTickerProviderStateMixin {
  /// Animation controller for smooth dialog entrance
  late AnimationController _animationController;

  /// Fade animation for dialog content
  late Animation<double> _fadeAnimation;

  /// Scale animation for dialog container
  late Animation<double> _scaleAnimation;

  /// Currently selected organization code
  String? _selectedOrganizationCode;

  /// Currently selected warehouse code
  String? _selectedWarehouseCode;

  /// Currently selected price type code
  String? _selectedPriceTypeCode;

  /// Form key for validation
  final _formKey = GlobalKey<FormState>();

  /// Whether the form has been submitted at least once
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations for smooth entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animation
    _animationController.forward();

    // Auto-select first items if only one option available
    if (widget.organizations.length == 1) {
      _selectedOrganizationCode = widget.organizations.first.code;
    }
    if (widget.warehouses.length == 1) {
      _selectedWarehouseCode = widget.warehouses.first.code;
    }
    if (widget.priceTypes.length == 1) {
      _selectedPriceTypeCode = widget.priceTypes.first.code;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Validates and submits the form
  /// Returns selected settings if valid, otherwise shows error
  void _handleSubmit() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (_formKey.currentState?.validate() ?? false) {
      // All validations passed, return selected settings
      Navigator.of(context).pop({
        'organizationCode': _selectedOrganizationCode!,
        'warehouseCode': _selectedWarehouseCode!,
        'priceTypeCode': _selectedPriceTypeCode!,
      });
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.settingsNotComplete ??
                'Please complete all required settings',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 8,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 700,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon and title
                    _buildHeader(context, l10n, colorScheme),

                    // Scrollable content area
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _hasAttemptedSubmit
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Description text
                              _buildDescription(l10n, theme),

                              const SizedBox(height: 24),

                              // Organization selector
                              _buildOrganizationSelector(l10n, colorScheme),

                              const SizedBox(height: 20),

                              // Warehouse selector
                              _buildWarehouseSelector(l10n, colorScheme),

                              const SizedBox(height: 20),

                              // Price type selector
                              _buildPriceTypeSelector(l10n, colorScheme),

                              const SizedBox(height: 32),

                              // Continue button
                              _buildContinueButton(l10n, colorScheme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the dialog header with icon and title
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // Settings icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.settings_suggest_rounded,
              color: colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              l10n?.initialOrderSettings ?? 'Initial Order Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the description text explaining the purpose of the dialog
  Widget _buildDescription(AppLocalizations? l10n, ThemeData theme) {
    return Text(
      l10n?.initialOrderSettingsDescription ??
          'Please configure the following settings before creating your first order.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  /// Builds the organization dropdown selector
  Widget _buildOrganizationSelector(
    AppLocalizations? l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.business_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.selectOrganization ?? 'Select Organization',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Dropdown
        DropdownButtonFormField<String>(
          value: _selectedOrganizationCode,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: Text(
            widget.organizations.isEmpty
                ? (l10n?.noOrganizationsAvailable ?? 'No organizations available')
                : (l10n?.selectOrganization ?? 'Select Organization'),
          ),
          items: widget.organizations.map((org) {
            return DropdownMenuItem<String>(
              value: org.code,
              child: Text(
                org.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.organizations.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedOrganizationCode = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n?.organizationRequired ?? 'Organization is required';
            }
            return null;
          },
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Builds the warehouse dropdown selector
  Widget _buildWarehouseSelector(
    AppLocalizations? l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.warehouse_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.selectWarehouse ?? 'Select Warehouse',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Dropdown
        DropdownButtonFormField<String>(
          value: _selectedWarehouseCode,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: Text(
            widget.warehouses.isEmpty
                ? (l10n?.noWarehousesAvailable ?? 'No warehouses available')
                : (l10n?.selectWarehouse ?? 'Select Warehouse'),
          ),
          items: widget.warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse.code,
              child: Text(
                warehouse.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.warehouses.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedWarehouseCode = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n?.warehouseRequired ?? 'Warehouse is required';
            }
            return null;
          },
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Builds the price type dropdown selector
  Widget _buildPriceTypeSelector(
    AppLocalizations? l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.selectPriceType ?? 'Select Price Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Dropdown
        DropdownButtonFormField<String>(
          value: _selectedPriceTypeCode,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: Text(
            widget.priceTypes.isEmpty
                ? (l10n?.noPriceTypesAvailable ?? 'No price types available')
                : (l10n?.selectPriceType ?? 'Select Price Type'),
          ),
          items: widget.priceTypes.map((priceType) {
            return DropdownMenuItem<String>(
              value: priceType.code,
              child: Text(
                priceType.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.priceTypes.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedPriceTypeCode = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n?.priceTypeRequired ?? 'Price type is required';
            }
            return null;
          },
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Builds the continue button
  Widget _buildContinueButton(
    AppLocalizations? l10n,
    ColorScheme colorScheme,
  ) {
    return FilledButton(
      onPressed: _handleSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n?.continueToOrder ?? 'Continue to Order',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }
}
