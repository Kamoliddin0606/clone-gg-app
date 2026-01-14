import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../../data/models/faq_section_model.dart';
import '../../data/models/faq_item_model.dart';

/// A collapsible card widget displaying a FAQ section with its items.
/// Uses smooth animations for expand/collapse transitions.
class FaqSectionCard extends StatefulWidget {
  final FaqSection section;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const FaqSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<FaqSectionCard> createState() => _FaqSectionCardState();
}

class _FaqSectionCardState extends State<FaqSectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accentColor = widget.section.accentColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isExpanded
              ? accentColor.withOpacity(0.5)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: _toggleExpansion,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? accentColor.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Icon container with accent color
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.section.icon,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title
                  Expanded(
                    child: Text(
                      _getLocalizedString(l10n, widget.section.titleKey),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isExpanded
                            ? accentColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Items count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.section.items.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/collapse icon
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.expand_more,
                      color: _isExpanded
                          ? accentColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
                ...widget.section.items.map(
                  (item) => _FaqItemTile(
                    item: item,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedString(AppLocalizations l10n, String key) {
    // Dynamic localization key lookup
    switch (key) {
      // Supervisor sections
      case 'faqSvGpsTitle':
        return l10n.faqSvGpsTitle;
      case 'faqSvSalesTitle':
        return l10n.faqSvSalesTitle;
      case 'faqSvKpiTitle':
        return l10n.faqSvKpiTitle;
      case 'faqSvTravelTitle':
        return l10n.faqSvTravelTitle;
      case 'faqSvTimeTitle':
        return l10n.faqSvTimeTitle;
      case 'faqSvSalaryTitle':
        return l10n.faqSvSalaryTitle;
      // Sales rep sections
      case 'faqTpGeneralTitle':
        return l10n.faqTpGeneralTitle;
      case 'faqTpHoursTitle':
        return l10n.faqTpHoursTitle;
      case 'faqTpVisitsTitle':
        return l10n.faqTpVisitsTitle;
      case 'faqTpVideoTitle':
        return l10n.faqTpVideoTitle;
      case 'faqTpReportingTitle':
        return l10n.faqTpReportingTitle;
      case 'faqTpResponsibilityTitle':
        return l10n.faqTpResponsibilityTitle;
      default:
        return key;
    }
  }
}

/// Individual FAQ item tile with expand/collapse functionality
class _FaqItemTile extends StatefulWidget {
  final FaqItem item;
  final Color accentColor;

  const _FaqItemTile({
    required this.item,
    required this.accentColor,
  });

  @override
  State<_FaqItemTile> createState() => _FaqItemTileState();
}

class _FaqItemTileState extends State<_FaqItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        InkWell(
          onTap: _toggleExpansion,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Item icon
                if (widget.item.icon != null) ...[
                  Icon(
                    widget.item.icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                ],
                // Item title
                Expanded(
                  child: Text(
                    _getLocalizedTitle(l10n, widget.item.titleKey),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: _isExpanded ? FontWeight.w600 : FontWeight.w500,
                      color: _isExpanded
                          ? widget.accentColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Expand indicator
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _isExpanded
                        ? widget.accentColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(48, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getLocalizedContent(l10n, widget.item.contentKey),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        // Divider between items
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ],
    );
  }

  String _getLocalizedTitle(AppLocalizations l10n, String key) {
    switch (key) {
      // Supervisor items
      case 'faqSvGpsMorningTitle':
        return l10n.faqSvGpsMorningTitle;
      case 'faqSvGpsEveningTitle':
        return l10n.faqSvGpsEveningTitle;
      case 'faqSvSalesInterimTitle':
        return l10n.faqSvSalesInterimTitle;
      case 'faqSvSalesFinalTitle':
        return l10n.faqSvSalesFinalTitle;
      case 'faqSvKpiMondayTitle':
        return l10n.faqSvKpiMondayTitle;
      case 'faqSvKpiAnalysisTitle':
        return l10n.faqSvKpiAnalysisTitle;
      case 'faqSvTravelMonthlyTitle':
        return l10n.faqSvTravelMonthlyTitle;
      case 'faqSvTimeWeeklyTitle':
        return l10n.faqSvTimeWeeklyTitle;
      case 'faqSvTimeMonthlyTitle':
        return l10n.faqSvTimeMonthlyTitle;
      case 'faqSvSalaryKpiTitle':
        return l10n.faqSvSalaryKpiTitle;
      case 'faqSvSalaryCalcTitle':
        return l10n.faqSvSalaryCalcTitle;
      // Sales rep items
      case 'faqTpGeneralPurposeTitle':
        return l10n.faqTpGeneralPurposeTitle;
      case 'faqTpHoursScheduleTitle':
        return l10n.faqTpHoursScheduleTitle;
      case 'faqTpHoursRouteTitle':
        return l10n.faqTpHoursRouteTitle;
      case 'faqTpHoursDelayTitle':
        return l10n.faqTpHoursDelayTitle;
      case 'faqTpVisitsDailyTitle':
        return l10n.faqTpVisitsDailyTitle;
      case 'faqTpVisitsChangesTitle':
        return l10n.faqTpVisitsChangesTitle;
      case 'faqTpVisitsPhotoTitle':
        return l10n.faqTpVisitsPhotoTitle;
      case 'faqTpVideoMorningTitle':
        return l10n.faqTpVideoMorningTitle;
      case 'faqTpVideoDuringTitle':
        return l10n.faqTpVideoDuringTitle;
      case 'faqTpVideoEndTitle':
        return l10n.faqTpVideoEndTitle;
      case 'faqTpReportingRealTimeTitle':
        return l10n.faqTpReportingRealTimeTitle;
      case 'faqTpReportingConsequenceTitle':
        return l10n.faqTpReportingConsequenceTitle;
      case 'faqTpResponsibilityRulesTitle':
        return l10n.faqTpResponsibilityRulesTitle;
      case 'faqTpResponsibilityMeasuresTitle':
        return l10n.faqTpResponsibilityMeasuresTitle;
      default:
        return key;
    }
  }

  String _getLocalizedContent(AppLocalizations l10n, String key) {
    switch (key) {
      // Supervisor content
      case 'faqSvGpsMorningContent':
        return l10n.faqSvGpsMorningContent;
      case 'faqSvGpsEveningContent':
        return l10n.faqSvGpsEveningContent;
      case 'faqSvSalesInterimContent':
        return l10n.faqSvSalesInterimContent;
      case 'faqSvSalesFinalContent':
        return l10n.faqSvSalesFinalContent;
      case 'faqSvKpiMondayContent':
        return l10n.faqSvKpiMondayContent;
      case 'faqSvKpiAnalysisContent':
        return l10n.faqSvKpiAnalysisContent;
      case 'faqSvTravelMonthlyContent':
        return l10n.faqSvTravelMonthlyContent;
      case 'faqSvTimeWeeklyContent':
        return l10n.faqSvTimeWeeklyContent;
      case 'faqSvTimeMonthlyContent':
        return l10n.faqSvTimeMonthlyContent;
      case 'faqSvSalaryKpiContent':
        return l10n.faqSvSalaryKpiContent;
      case 'faqSvSalaryCalcContent':
        return l10n.faqSvSalaryCalcContent;
      // Sales rep content
      case 'faqTpGeneralPurposeContent':
        return l10n.faqTpGeneralPurposeContent;
      case 'faqTpHoursScheduleContent':
        return l10n.faqTpHoursScheduleContent;
      case 'faqTpHoursRouteContent':
        return l10n.faqTpHoursRouteContent;
      case 'faqTpHoursDelayContent':
        return l10n.faqTpHoursDelayContent;
      case 'faqTpVisitsDailyContent':
        return l10n.faqTpVisitsDailyContent;
      case 'faqTpVisitsChangesContent':
        return l10n.faqTpVisitsChangesContent;
      case 'faqTpVisitsPhotoContent':
        return l10n.faqTpVisitsPhotoContent;
      case 'faqTpVideoMorningContent':
        return l10n.faqTpVideoMorningContent;
      case 'faqTpVideoDuringContent':
        return l10n.faqTpVideoDuringContent;
      case 'faqTpVideoEndContent':
        return l10n.faqTpVideoEndContent;
      case 'faqTpReportingRealTimeContent':
        return l10n.faqTpReportingRealTimeContent;
      case 'faqTpReportingConsequenceContent':
        return l10n.faqTpReportingConsequenceContent;
      case 'faqTpResponsibilityRulesContent':
        return l10n.faqTpResponsibilityRulesContent;
      case 'faqTpResponsibilityMeasuresContent':
        return l10n.faqTpResponsibilityMeasuresContent;
      default:
        return key;
    }
  }
}
