import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Modern Date Range Picker Widget
/// Provides a beautiful, animated date range selection interface
class ModernDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final String? title;
  final String? confirmText;
  final String? cancelText;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  const ModernDateRangePicker({
    super.key,
    this.initialRange,
    this.title,
    this.confirmText,
    this.cancelText,
    this.minimumDate,
    this.maximumDate,
  });

  /// Static method to show the date range picker as a modal bottom sheet
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    String? title,
    String? confirmText,
    String? cancelText,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernDateRangePicker(
        initialRange: initialRange,
        title: title,
        confirmText: confirmText,
        cancelText: cancelText,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      ),
    );
  }

  @override
  State<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker>
    with TickerProviderStateMixin {
  late DateTimeRange? _selectedRange;
  late DateTime _currentMonth;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
    _currentMonth = _selectedRange?.start ?? DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_selectedRange == null) {
        // First date selection
        _selectedRange = DateTimeRange(start: date, end: date);
      } else if (_selectedRange!.start == _selectedRange!.end) {
        // Second date selection
        if (date.isBefore(_selectedRange!.start)) {
          _selectedRange = DateTimeRange(start: date, end: _selectedRange!.start);
        } else {
          _selectedRange = DateTimeRange(start: _selectedRange!.start, end: date);
        }
      } else {
        // Reset selection
        _selectedRange = DateTimeRange(start: date, end: date);
      }
    });
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedRange == null) return false;
    return date.isAtSameMomentAs(_selectedRange!.start) ||
           date.isAtSameMomentAs(_selectedRange!.end);
  }

  bool _isDateInRange(DateTime date) {
    if (_selectedRange == null) return false;
    return date.isAfter(_selectedRange!.start) &&
           date.isBefore(_selectedRange!.end);
  }

  bool _isValidDate(DateTime date) {
    if (widget.minimumDate != null && date.isBefore(widget.minimumDate!)) {
      return false;
    }
    if (widget.maximumDate != null && date.isAfter(widget.maximumDate!)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.title ?? AppLocalizations.of(context)?.selectDateRange ?? 'Select date range',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Selected range display
                  if (_selectedRange != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${DateFormat('dd.MM.yyyy').format(_selectedRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedRange!.end)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Calendar
            Expanded(
              child: _buildCalendar(colorScheme),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.cancelText ?? AppLocalizations.of(context)?.cancelButton ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selectedRange != null
                          ? () => Navigator.of(context).pop(_selectedRange)
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.confirmText ?? AppLocalizations.of(context)?.confirmButton ?? 'Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ColorScheme colorScheme) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final adjustedFirstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

    return Column(
      children: [
        // Month/Year header with navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(
                  Icons.chevron_left,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy', 'uz').format(_currentMonth),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final weekdays = [
                l10n?.weekdayMon ?? 'Mo',
                l10n?.weekdayTue ?? 'Tu',
                l10n?.weekdayWed ?? 'We',
                l10n?.weekdayThu ?? 'Th',
                l10n?.weekdayFri ?? 'Fr',
                l10n?.weekdaySat ?? 'Sa',
                l10n?.weekdaySun ?? 'Su',
              ];
              return Row(
                children: weekdays.map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42, // 6 weeks * 7 days
              itemBuilder: (context, index) {
                final dayOffset = index - adjustedFirstWeekday + 1;
                final isValidDay = dayOffset > 0 && dayOffset <= daysInMonth;
                final currentDate = isValidDay
                    ? DateTime(_currentMonth.year, _currentMonth.month, dayOffset)
                    : null;

                if (!isValidDay || currentDate == null) {
                  return const SizedBox.shrink();
                }

                final isSelected = _isDateSelected(currentDate);
                final isInRange = _isDateInRange(currentDate);
                final isValid = _isValidDate(currentDate);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isInRange
                        ? colorScheme.primary.withOpacity(0.2)
                        : isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : isInRange
                              ? colorScheme.primary.withOpacity(0.5)
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isValid ? () => _selectDate(currentDate) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Center(
                        child: Text(
                          dayOffset.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : isInRange
                                    ? colorScheme.primary
                                    : isValid
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(colorScheme.primary, AppLocalizations.of(context)?.selectedPeriod ?? 'Selected period'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}