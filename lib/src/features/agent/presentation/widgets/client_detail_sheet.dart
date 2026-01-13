/// ============================================================================
/// Enterprise-Level Client Detail Sheet
/// ============================================================================
/// Modern, professional UI for displaying client information with progressive
/// disclosure pattern. Follows Material You design principles with full
/// localization support (RU/UZ/EN).
///
/// Key Features:
/// - Clean, minimal design with strong visual hierarchy
/// - Collapsible sections for secondary information
/// - Swipeable image gallery
/// - Integrated balance widget
/// - Action buttons with permission-based visibility
/// - Fully localized interface
/// - Responsive layout for portrait/landscape
/// - Scalable architecture for future enhancements
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/client_balance_widget_v2.dart';
import 'package:url_launcher/url_launcher.dart';

/// Main client detail sheet widget
class ClientDetailSheet extends StatefulWidget {
  final TradingPoint tradingPoint;
  final SalesReqPermissions? permissions;
  final ClientImagesService? clientImagesService;
  final VoidCallback? onVisit;
  final VoidCallback? onCreateOrder;
  final VoidCallback? onViewOrders;
  final VoidCallback? onViewContracts;
  final VoidCallback? onRefusal;
  final VoidCallback? onEditCoordinates;

  const ClientDetailSheet({
    super.key,
    required this.tradingPoint,
    this.permissions,
    this.clientImagesService,
    this.onVisit,
    this.onCreateOrder,
    this.onViewOrders,
    this.onViewContracts,
    this.onRefusal,
    this.onEditCoordinates,
  });

  @override
  State<ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<ClientDetailSheet> {
  // Collapsible section states
  bool _showAdditionalInfo = false;
  bool _showLocationInfo = false;
  bool _showBusinessInfo = false;

  // Image gallery state
  List<ClientImage> _clientImages = [];
  bool _isLoadingImages = true;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadClientImages();
    _imagePageController.addListener(() {
      final page = _imagePageController.page?.round() ?? 0;
      if (page != _currentImageIndex) {
        setState(() => _currentImageIndex = page);
      }
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  /// Load client images from service
  Future<void> _loadClientImages() async {
    if (widget.clientImagesService == null) {
      setState(() => _isLoadingImages = false);
      return;
    }

    try {
      final images = await widget.clientImagesService!.getClientImages(
        widget.tradingPoint.id,
      );
      if (mounted) {
        setState(() {
          _clientImages = images;
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading client images: $e');
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  /// Make phone call
  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable content
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Image gallery section
                    SliverToBoxAdapter(
                      child: _buildImageGallery(context),
                    ),

                    // Main content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Client name and status
                            _buildHeader(context),
                            const SizedBox(height: 20),

                            // Primary actions
                            _buildPrimaryActions(context),
                            const SizedBox(height: 24),

                            // Balance widget
                            _buildBalanceSection(context),
                            const SizedBox(height: 24),

                            // Essential information (always visible)
                            _buildEssentialInfo(context),
                            const SizedBox(height: 16),

                            // Collapsible sections
                            _buildCollapsibleSections(context),
                            const SizedBox(height: 24),

                            // Secondary actions
                            _buildSecondaryActions(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build image gallery with swipeable pages
  Widget _buildImageGallery(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoadingImages) {
      return Container(
        height: 240,
        color: cs.surfaceContainerHighest,
        child: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    if (_clientImages.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withOpacity(0.3),
              cs.secondaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.noImagesAvailable,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _imagePageController,
            itemCount: _clientImages.length,
            itemBuilder: (context, index) {
              final image = _clientImages[index];
              return Image.network(
                image.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Image counter overlay
          if (_clientImages.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${_clientImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Page indicators
          if (_clientImages.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _clientImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentImageIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentImageIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build header with client name and status indicators
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client name
        Text(
          widget.tradingPoint.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Status chips row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Visit status
            if (widget.tradingPoint.isVisited)
              _buildStatusChip(
                context,
                icon: Icons.check_circle,
                label: AppLocalizations.of(context)?.visited ?? '',
                color: Colors.green,
              ),
            if (widget.tradingPoint.visitToday && !widget.tradingPoint.isVisited)
              _buildStatusChip(
                context,
                icon: Icons.schedule,
                label: AppLocalizations.of(context)?.plannedForToday ?? '',
                color: Colors.orange,
              ),

            // Contract status
            if (widget.tradingPoint.hasContract)
              _buildStatusChip(
                context,
                icon: Icons.description,
                label: AppLocalizations.of(context)!.hasContract,
                color: cs.primary,
              ),
          ],
        ),
      ],
    );
  }

  /// Build status chip
  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build primary action buttons
  Widget _buildPrimaryActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canVisit = widget.permissions?.visit == true && 
                     widget.tradingPoint.visitToday == true;
    final canCreateOrder = widget.permissions?.visit == true &&
                          widget.permissions?.unplannedOrder == true &&
                          widget.tradingPoint.visitToday == false;

    return Column(
      children: [
        // Visit button (primary action)
        if (canVisit && widget.onVisit != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onVisit,
              icon: const Icon(Icons.storefront),
              label: Text(l10n.visitClient),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Unplanned order button
        if (canCreateOrder && widget.onCreateOrder != null) ...[
          if (canVisit) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: widget.onCreateOrder,
              icon: const Icon(Icons.shopping_cart),
              label: Text(l10n.unplannedOrder),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build balance section
  Widget _buildBalanceSection(BuildContext context) {
    return ClientBalanceWidgetV2(
      tradingPoint: widget.tradingPoint,
    );
  }

  /// Build essential information (always visible)
  Widget _buildEssentialInfo(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Address
          _buildInfoRow(
            context,
            icon: Icons.place_outlined,
            label: l10n.address,
            value: widget.tradingPoint.address,
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          // INN
          _buildInfoRow(
            context,
            icon: Icons.badge_outlined,
            label: l10n.inn,
            value: widget.tradingPoint.inn,
          ),
          const SizedBox(height: 12),

          // Phone (clickable)
          if (widget.tradingPoint.phone.isNotEmpty)
            InkWell(
              onTap: () => _makeCall(widget.tradingPoint.phone),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildInfoRow(
                  context,
                  icon: Icons.phone_outlined,
                  label: AppLocalizations.of(context)!.phone,
                  value: widget.tradingPoint.phone,
                  valueColor: Theme.of(context).colorScheme.primary,
                  isClickable: true,
                ),
              ),
            ),

          // Contact person
          if (widget.tradingPoint.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.person_outline,
              label: l10n.contactPerson,
              value: widget.tradingPoint.contactPerson,
            ),
          ],
        ],
      ),
    );
  }

  /// Build collapsible sections
  Widget _buildCollapsibleSections(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Additional information section
        _buildCollapsibleSection(
          context,
          title: l10n.additionalInformation,
          isExpanded: _showAdditionalInfo,
          onToggle: () => setState(() => _showAdditionalInfo = !_showAdditionalInfo),
          child: _buildAdditionalInfoContent(context),
        ),
        const SizedBox(height: 12),

        // Location information section
        _buildCollapsibleSection(
          context,
          title: l10n.locationInformation,
          isExpanded: _showLocationInfo,
          onToggle: () => setState(() => _showLocationInfo = !_showLocationInfo),
          child: _buildLocationInfoContent(context),
        ),
        const SizedBox(height: 12),

        // Business information section
        _buildCollapsibleSection(
          context,
          title: l10n.businessInformation,
          isExpanded: _showBusinessInfo,
          onToggle: () => setState(() => _showBusinessInfo = !_showBusinessInfo),
          child: _buildBusinessInfoContent(context),
        ),
      ],
    );
  }

  /// Build collapsible section wrapper
  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Build additional information content
  Widget _buildAdditionalInfoContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (widget.tradingPoint.ownerName.isNotEmpty)
          _buildInfoRow(
            context,
            icon: Icons.person,
            label: l10n.ownerName,
            value: widget.tradingPoint.ownerName,
          ),
        if (widget.tradingPoint.ownerName.isNotEmpty &&
            widget.tradingPoint.responsiblePerson.isNotEmpty)
          const SizedBox(height: 12),
        if (widget.tradingPoint.responsiblePerson.isNotEmpty)
          _buildInfoRow(
            context,
            icon: Icons.account_circle_outlined,
            label: l10n.responsiblePerson,
            value: widget.tradingPoint.responsiblePerson,
          ),
        if (widget.tradingPoint.responsiblePerson.isNotEmpty &&
            widget.tradingPoint.responsiblePersonPhone.isNotEmpty)
          const SizedBox(height: 12),
        if (widget.tradingPoint.responsiblePersonPhone.isNotEmpty)
          _buildInfoRow(
            context,
            icon: Icons.phone_android_outlined,
            label: l10n.responsiblePersonPhone,
            value: widget.tradingPoint.responsiblePersonPhone,
          ),
      ],
    );
  }

  /// Build location information content
  Widget _buildLocationInfoContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildInfoRow(
          context,
          icon: Icons.location_city_outlined,
          label: l10n.region,
          value: '${widget.tradingPoint.region}, ${widget.tradingPoint.district}',
        ),
        if (widget.tradingPoint.signboard.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.signpost_outlined,
            label: l10n.signboard,
            value: widget.tradingPoint.signboard,
          ),
        ],
        if (widget.tradingPoint.referencePoint.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.gps_fixed_outlined,
            label: l10n.referencePoint,
            value: widget.tradingPoint.referencePoint,
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          icon: Icons.map_outlined,
          label: l10n.coordinates,
          value: '${widget.tradingPoint.latitude.toStringAsFixed(6)}, ${widget.tradingPoint.longitude.toStringAsFixed(6)}',
        ),
      ],
    );
  }

  /// Build business information content
  Widget _buildBusinessInfoContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (widget.tradingPoint.tradePointType.isNotEmpty)
          _buildInfoRow(
            context,
            icon: Icons.storefront_outlined,
            label: l10n.tradePointType,
            value: widget.tradingPoint.tradePointType,
          ),
        if (widget.tradingPoint.tradePointType.isNotEmpty &&
            widget.tradingPoint.creditLimit > 0)
          const SizedBox(height: 12),
        if (widget.tradingPoint.creditLimit > 0)
          _buildInfoRow(
            context,
            icon: Icons.credit_card_outlined,
            label: l10n.creditLimit,
            value: '${widget.tradingPoint.creditLimit.toStringAsFixed(2)} ${l10n.currency}',
          ),
      ],
    );
  }

  /// Build information row
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 2,
    Color? valueColor,
    bool isClickable = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? cs.onSurface,
                  fontWeight: FontWeight.w500,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build secondary actions
  Widget _buildSecondaryActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // View orders
        if (widget.onViewOrders != null)
          OutlinedButton.icon(
            onPressed: widget.onViewOrders,
            icon: const Icon(Icons.list_alt, size: 18),
            label: Text(l10n.orders),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

        // View contracts
        if (widget.tradingPoint.hasContract && widget.onViewContracts != null)
          OutlinedButton.icon(
            onPressed: widget.onViewContracts,
            icon: const Icon(Icons.description, size: 18),
            label: Text(l10n.contracts),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

        // Refusal
        if (widget.onRefusal != null)
          OutlinedButton.icon(
            onPressed: widget.onRefusal,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l10n.refusal),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: Colors.red,
            ),
          ),
      ],
    );
  }
}
