import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import '../../../../core/services/reports_sync_service.dart';

/// Animated Percentage Widget - Barcha percent elementlar uchun umumiy widget
enum PercentageDisplayType {
  circular, // Dial gauge (doiraviy progress)
  linear, // Chiziqli progress bar
  text, // Faqat matn ko'rinishida
  number, // Raqamlar uchun animatsiya
}

class AnimatedPercentageWidget extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final PercentageDisplayType type;
  final Color color;
  final String? label;
  final String? valueText;
  final double size;
  final Duration animationDuration;
  final String? numberValue; // For number animation

  const AnimatedPercentageWidget({
    super.key,
    required this.percentage,
    this.type = PercentageDisplayType.circular,
    required this.color,
    this.label,
    this.valueText,
    this.size = 100,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.numberValue,
  });

  @override
  State<AnimatedPercentageWidget> createState() =>
      _AnimatedPercentageWidgetState();
}

class _AnimatedPercentageWidgetState extends State<AnimatedPercentageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation =
        Tween<double>(
          begin: 0.0,
          end: widget.percentage.clamp(0.0, 1.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Sahifa yuklanganda animatsiyani boshlash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedPercentageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.percentage.clamp(0.0, 1.0),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case PercentageDisplayType.circular:
            return _buildCircularProgress();
          case PercentageDisplayType.linear:
            return _buildLinearProgress();
          case PercentageDisplayType.text:
            return _buildTextProgress();
          case PercentageDisplayType.number:
            return _buildNumberProgress();
        }
      },
    );
  }

  Widget _buildCircularProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: _animation.value,
              color: widget.color,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.4),
            ),
            child: Center(
              child: Text(
                widget.valueText ??
                    '${(_animation.value * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLinearProgress() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.label!, style: theme.textTheme.labelMedium),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        if (widget.valueText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.valueText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextProgress() {
    return Text(
      widget.valueText ?? '${(_animation.value * 100).toStringAsFixed(1)}%',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: widget.color,
      ),
    );
  }

  Widget _buildNumberProgress() {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end: double.tryParse(widget.numberValue ?? '0') ?? 0,
      ),
      duration: widget.animationDuration,
      builder: (_, value, __) => Text(
        widget.valueText ?? value.toStringAsFixed(0),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: widget.color,
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // 180 degrees (semi-circle)
      3.14159,
      false,
      backgroundPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

class MainReportPage extends StatefulWidget {
  const MainReportPage({super.key});

  @override
  State<MainReportPage> createState() => _MainReportPageState();
}

class _MainReportPageState extends State<MainReportPage>
    with TickerProviderStateMixin {
  MainReport? report;
  late final AnimationController _controller;
  late final DataSyncService _dataSyncService;
  late final ApiDatabaseService _dbService;
  late final ReportsSyncService _dbReportService;
  late final SharedPreferencesService _prefs;
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  Map<String, int> _akbByRegion = {};
  Map<String, int> _categories = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Initialize services
    _dataSyncService = GetIt.instance<DataSyncService>();
    _dbService = GetIt.instance<ApiDatabaseService>();
    _dbReportService = GetIt.instance<ReportsSyncService>();
    _prefs = GetIt.instance<SharedPreferencesService>();

    // Load report data from database
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final userCode = _prefs.getUserCode();
      if (kDebugMode) print(userCode);
      if (userCode != null) {
        final today = DateTime.now();
        final dateStart = today.toIso8601String().split('T')[0];
        final dateEnd = dateStart;
        final reportData = await _dbReportService.syncReportWithoutPeriod(
          userCode: userCode,
          dateStart: dateStart,
          dateEnd: dateEnd,
          forceRefresh: false,
        );
        final mainReport = reportData['mainReport'] as MainReport;
        final businessRegionReports =
            reportData['businessRegionReports'] as List<BusinessRegionReport>;
        final akbByCategories =
            reportData['akbByCategories'] as List<AKBByCategory>;

        // Convert to maps for UI
        final akbByRegion = <String, int>{};
        for (final regionReport in businessRegionReports) {
          akbByRegion[regionReport.name] = regionReport.akb;
        }

        final categories = <String, int>{};
        for (final category in akbByCategories) {
          categories[category.name] = category.akb;
        }

        setState(() {
          report = mainReport;
          // Store related data for UI
          _akbByRegion = akbByRegion;
          _categories = categories;
          // Initialize selected range with report's date range
          if (report!.dateStart != null && report!.dateEnd != null) {
            _selectedRange = DateTimeRange(
              start: report!.dateStart!,
              end: report!.dateEnd!,
            );
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading report data: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // void _showReportPeriodCalendar(BuildContext context, MainReport? report) async {
  //   // Show the enhanced calendar dialog
  //   _showEnhancedCalendarDialog(
  //     context,
  //     _selectedRange,
  //     (selectedRange) {
  //       if (selectedRange != null && !_prefs.isOfflineMode()) {
  //         // Perform operations asynchronously in the background without blocking UI
  //         _performBackgroundDataSync(selectedRange, context);
  //       } else {
  //         _showErrorSnackBar(context, "Offline rejimda malumotlarni yangilashning imkoni yo'q");
  //       }
  //     },
  //   );
  // }
  // ESKI: _showEnhancedCalendarDialog(...) chaqirardi
  // YANGI: reports_page.dart dagidek Material date range picker dan foydalanamiz
  void _showReportPeriodCalendar(
    BuildContext context,
    MainReport? report,
  ) async {
    // 2-fayldagi parametrlar bilan bir xil: initialDateRange, firstDate, lastDate
    // initialDateRange ni tekshirib, agar end lastDate dan keyin bo'lsa, uni lastDate ga teng qilish
    DateTimeRange? safeInitialRange = _selectedRange;
    final lastDate = DateTime.now();
    if (safeInitialRange != null && safeInitialRange.end.isAfter(lastDate)) {
      safeInitialRange = DateTimeRange(
        start: safeInitialRange.start,
        end: lastDate,
      );
    }

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: safeInitialRange,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      // istasangiz quyidagilarni ham qo‘shsa bo‘ladi:
      // initialEntryMode: DatePickerEntryMode.calendarOnly,
      // helpText: 'Select range',
      // saveText: 'Save',
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });

      if (!_prefs.isOfflineMode()) {
        // 1-fayldagi mavjud sinxronizatsiya oqimi saqlanadi
        _performBackgroundDataSync(picked, context);
      } else {
        _showErrorSnackBar(
          context,
          AppLocalizations.of(context)?.offlineCannotRefresh ??
              "Offline rejimda ma'lumotlarni yangilashning imkoni yo'q",
        );
      }
    }
  }

  /// Enhanced calendar dialog with modern UI effects and animations
  void _showEnhancedCalendarDialog(
    BuildContext context,
    DateTimeRange? currentRange,
    Function(DateTimeRange?) onRangeSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Animation controller for smooth transitions
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    DateTimeRange? selectedRange =
        currentRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Calendar Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale: animation1,
          child: FadeTransition(
            opacity: animation1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient background
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: colorScheme.onPrimary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.selectPeriodTitle ??
                                        'Davrni tanlang',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.selectReportDatesHint ??
                                        'Hisobot uchun boshlanish va tugash sanalarini belgilang',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onPrimary,
                              ),
                              tooltip:
                                  AppLocalizations.of(context)?.close ??
                                  'Yopish',
                            ),
                          ],
                        ),
                      ),

                      // Calendar content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current selection display
                              AnimatedBuilder(
                                animation: fadeAnimation,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.date_range,
                                            color: colorScheme.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                        context,
                                                      )?.selectedPeriod ??
                                                      'Tanlangan davr',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${DateFormat('dd.MM.yyyy').format(selectedRange!.start)} - ${DateFormat('dd.MM.yyyy').format(selectedRange!.end)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              // Enhanced calendar picker
                              AnimatedBuilder(
                                animation: scaleAnimation,
                                builder: (context, child) {
                                  return ScaleTransition(
                                    scale: scaleAnimation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: colorScheme.outline
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: CalendarDatePicker(
                                          initialDate: selectedRange!.start,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                          onDateChanged: (date) {
                                            // For single date selection, create a range
                                            selectedRange = DateTimeRange(
                                              start: date,
                                              end: date.add(
                                                const Duration(days: 30),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              // Quick selection buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickSelectButton(
                                    context,
                                    AppLocalizations.of(context)?.today ??
                                        'Bugun',
                                    DateTimeRange(
                                      start: DateTime.now(),
                                      end: DateTime.now(),
                                    ),
                                    selectedRange,
                                    (range) => selectedRange = range,
                                  ),
                                  _buildQuickSelectButton(
                                    context,
                                    AppLocalizations.of(context)?.last7Days ??
                                        'Oxirgi 7 kun',
                                    DateTimeRange(
                                      start: DateTime.now().subtract(
                                        const Duration(days: 7),
                                      ),
                                      end: DateTime.now(),
                                    ),
                                    selectedRange,
                                    (range) => selectedRange = range,
                                  ),
                                  _buildQuickSelectButton(
                                    context,
                                    AppLocalizations.of(context)?.last30Days ??
                                        'Oxirgi 30 kun',
                                    DateTimeRange(
                                      start: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      end: DateTime.now(),
                                    ),
                                    selectedRange,
                                    (range) => selectedRange = range,
                                  ),
                                  _buildQuickSelectButton(
                                    context,
                                    AppLocalizations.of(
                                          context,
                                        )?.currentMonth ??
                                        'Joriy oy',
                                    DateTimeRange(
                                      start: DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        1,
                                      ),
                                      end: DateTime.now(),
                                    ),
                                    selectedRange,
                                    (range) => selectedRange = range,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.cancel),
                                      label: Text(
                                        AppLocalizations.of(context)?.cancel ??
                                            'Bekor qilish',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        onRangeSelected(selectedRange);
                                        Navigator.of(context).pop();

                                        // Trigger report sync based on server selection
                                        final dataSyncService =
                                            _dataSyncService;
                                        final reportsSyncService =
                                            _dbReportService;

                                        if (dataSyncService
                                            .isEvyapServerSelected()) {
                                          // Sync reports for Evyap server
                                          reportsSyncService.syncReportByPeriod(
                                            userCode:
                                                _prefs.getUserCode() ?? '',
                                            dateStart: selectedRange!.start
                                                .toIso8601String()
                                                .split('T')[0],
                                            dateEnd: selectedRange!.end
                                                .toIso8601String()
                                                .split('T')[0],
                                          );
                                        } else if (dataSyncService
                                            .isAvonServerSelected()) {
                                          // Sync promotions for Avon server
                                          dataSyncService.syncPromotions();
                                        }
                                      },
                                      icon: const Icon(Icons.check),
                                      label: Text(
                                        AppLocalizations.of(context)?.confirm ??
                                            'Tasdiqlash',
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      animationController.dispose();
    });

    // Start the animation
    animationController.forward();
  }

  /// Helper method to build quick selection buttons
  Widget _buildQuickSelectButton(
    BuildContext context,
    String label,
    DateTimeRange range,
    DateTimeRange? selectedRange,
    Function(DateTimeRange) onSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSelected =
        selectedRange != null &&
        selectedRange.start == range.start &&
        selectedRange.end == range.end;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => onSelected(range),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performBackgroundDataSync(
    DateTimeRange selectedRange,
    BuildContext context,
  ) async {
    try {
      // Get user code from preferences
      final userCode = _prefs.getUserCode();
      if (kDebugMode) print("userCode: $userCode");
      if (userCode == null) {
        _showErrorSnackBar(context, 'Foydalanuvchi kodi topilmadi');
        return;
      }

      if (kDebugMode) {
        print('Starting background data sync for user: $userCode');
      }

      // Step 1: Clear main report data
      if (kDebugMode) print('clear main report data started');
      await _dataSyncService.clearMainReportData();
      if (kDebugMode) print('clear main report data finished sucesfuly');
      // Step 2: Sync new report data
      final reportData = await _dataSyncService.syncReportByPeriod(
        userCode: userCode,
        dateStart: selectedRange.start.toIso8601String().split('T')[0],
        dateEnd: selectedRange.end.toIso8601String().split('T')[0],
        forceRefresh: true,
      );

      // Step 3: Update UI with new data
      // Parse the reportData and update the report object
      if (mounted) {
        final mainReport = reportData['mainReport'] as MainReport;
        final businessRegionReports =
            reportData['businessRegionReports'] as List<BusinessRegionReport>;
        final akbByCategories =
            reportData['akbByCategories'] as List<AKBByCategory>;
        if (kDebugMode)
          print(
            'malumotlarni saqlashdan oldin to\'liq main report qismlar ${reportData}',
          );
        // Convert business region reports to map
        final akbByRegion = <String, int>{};
        for (final regionReport in businessRegionReports) {
          akbByRegion[regionReport.name] = regionReport.akb;
        }

        // Convert AKB by categories to map
        final categories = <String, int>{};
        for (final category in akbByCategories) {
          categories[category.name] = category.akb;
        }

        setState(() {
          _selectedRange = selectedRange;
          // Update report with synced data
          report = mainReport;
          _akbByRegion = akbByRegion;
          _categories = categories;
        });
      }

      if (kDebugMode) {
        print('Background data sync completed successfully');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.reportDataRefreshed ??
                  'Hisobot ma\'lumotlari muvaffaqiyatli yangilandi',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during background data sync: $e');
      }

      // Show error message
      if (mounted) {
        _showErrorSnackBar(context, 'Ma\'lumotlarni yangilashda xatolik: $e');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  void _updateLoadingDialog(BuildContext context, String message) {
    // Find the current dialog and update its content
    Navigator.of(context).pop(); // Close current dialog
    _showLoadingDialog(
      context,
      message,
    ); // Show new dialog with updated message
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.08),
            cs.primaryContainer.withOpacity(0.06),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Period Display - Prominent UI element
                      GestureDetector(
                        onDoubleTap: () =>
                            _showReportPeriodCalendar(context, report),
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withOpacity(0.1),
                                  cs.primaryContainer.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: cs.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.reportPeriod,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.onSurface,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.touch_app,
                                            size: 16,
                                            color: cs.onSurfaceVariant
                                                .withOpacity(0.6),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (_selectedRange != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const SizedBox(width: 4),
                                                Text(
                                                  ' ${DateFormat('yyyy-MM-dd').format(_selectedRange!.start)} dan ${DateFormat('yyyy-MM-dd').format(_selectedRange!.end)} gacha',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: cs.primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                        )
                                      else if (report?.dateStart != null &&
                                          report?.dateEnd != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const SizedBox(width: 4),
                                                Text(
                                                  ' ${DateFormat('yyyy-MM-dd').format(report!.dateStart!)} dan ${DateFormat('yyyy-MM-dd').format(report!.dateEnd!)} gacha',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: cs.primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                        )
                                      else
                                        Text(
                                          report?.dateStart
                                                  ?.toLocal()
                                                  .toString()
                                                  .split(' ')[0] ??
                                              'No Data',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: cs.primary,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.info_outline,
                                  color: cs.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      _SectionTitle(
                        icon: Icons.groups_2_outlined,
                        title:
                            AppLocalizations.of(context)?.monthlyOkbAkb ??
                            'Oylik OKB/AKB',
                      ),
                      const SizedBox(height: 8),
                      _OkbAkbMonthly(report: report),

                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.ssid_chart_rounded,
                        title:
                            AppLocalizations.of(
                              context,
                            )?.monthlyPlanFactForecast ??
                            'Oylik reja / Fakt / Bashorat',
                      ),
                      const SizedBox(height: 8),
                      _PlanFactForecast(report: report),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.analytics_outlined,
                        title:
                            AppLocalizations.of(context)?.todayMainIndicators ??
                            'Bugun — asosiy ko\'rsatkichlar',
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _StatCard(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )?.territoryOKB ??
                                    'Hudud OKB',
                                value: (report?.countOKB ?? 0).toString(),
                                icon: Icons.map_outlined,
                                tooltip:
                                    AppLocalizations.of(
                                      context,
                                    )?.territoryOKBTooltip ??
                                    'Hudud bo\'yicha mijozlar bazasini qamrab olish',
                              ),
                              _StatCard(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )?.visitedTradingPoints ??
                                    'Tashrif buyurilgan s.n.',
                                value: (report?.countVisited ?? 0).toString(),
                                icon: Icons.store_mall_directory_outlined,
                                tooltip:
                                    AppLocalizations.of(
                                      context,
                                    )?.visitedTradingPointsTooltip ??
                                    'Tashrif buyurilgan savdo nuqtalari soni',
                              ),
                              _StatCard(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )?.activeClients ??
                                    'Faol mijozlar',
                                value: (report?.countAKB ?? 0).toString(),
                                icon: Icons.check_circle,
                                tooltip:
                                    AppLocalizations.of(
                                      context,
                                    )?.activeClientsTooltip ??
                                    'Bugun faol buyurtmalari bo\'lgan mijozlar',
                              ),
                              _MoneyCard(
                                label:
                                    AppLocalizations.of(context)?.cash ??
                                    'Naqd',
                                amount: report?.cash ?? 0.0,
                                icon: Icons.payments_outlined,
                              ),
                              _MoneyCard(
                                label:
                                    AppLocalizations.of(context)?.cashless ??
                                    'Naqdsiz',
                                amount: report?.transfer ?? 0.0,
                                icon: Icons.account_balance_outlined,
                              ),
                              _MoneyCard(
                                label:
                                    AppLocalizations.of(context)?.ordersTotal ??
                                    'Buyurtmalar jami',
                                amount: report?.sum ?? 0.0,
                                icon: Icons.receipt_long_outlined,
                                highlight: true,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.map_outlined,
                        title: 'Hududlar bo\'yicha AKB',
                      ),
                      const SizedBox(height: 8),
                      _RegionChips(regions: _akbByRegion),

                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.category_outlined,
                        title: 'Tovar kategoriyalari bo\'yicha AKB',
                      ),
                      const SizedBox(height: 8),
                      _CategoryList(categories: _categories),

                      // const SizedBox(height: 28),
                      // _FooterNote(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? tooltip;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = _GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, v, __) => Text(
                    v.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

class _MoneyCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool highlight;

  const _MoneyCard({
    required this.label,
    required this.amount,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      highlight: highlight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.tertiary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: amount),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, v, __) => Text(
                    formatCurrencyUz(v),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool highlight;
  const _GlassCard({required this.child, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: highlight
            ? LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.06),
                  cs.surface.withOpacity(0.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: child,
    );
  }
}

class _PlanFactForecast extends StatelessWidget {
  final MainReport? report;
  const _PlanFactForecast({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildBar({
      required String label,
      required double percent,
      required Color color,
      String? value,
    }) {
      percent = percent.clamp(0, 1);
      return _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                if (value != null)
                  Text(
                    value,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedPercentageWidget(
              percentage: percent,
              type: PercentageDisplayType.linear,
              color: color,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (report != null) ...[
          buildBar(
            label: AppLocalizations.of(context)?.fact ?? 'Fakt',
            percent: report!.sum / (report!.sum == 0 ? 1 : report!.sum),
            color: cs.primary,
            value: formatCurrencyUz(report!.sum),
          ),
          const SizedBox(height: 10),
          buildBar(
            label: AppLocalizations.of(context)?.cash ?? 'Naqd',
            percent: report!.cash / (report!.sum == 0 ? 1 : report!.sum),
            color: cs.tertiary,
            value: formatCurrencyUz(report!.cash),
          ),
          const SizedBox(height: 10),
          buildBar(
            label: AppLocalizations.of(context)?.cashless ?? 'Naqdsiz',
            percent: report!.transfer / (report!.sum == 0 ? 1 : report!.sum),
            color: cs.secondary,
            value: formatCurrencyUz(report!.transfer),
          ),
        ],
      ],
    );
  }
}

class _RegionChips extends StatelessWidget {
  final Map<String, int> regions;
  const _RegionChips({required this.regions});

  @override
  Widget build(BuildContext context) {
    final entries = regions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries)
          Chip(
            avatar: const Icon(Icons.location_city_outlined, size: 18),
            label: Text('${e.key}: ${e.value} t.t.'),
          ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  final Map<String, int> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _GlassCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_mall_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        AnimatedPercentageWidget(
                          percentage:
                              e.value /
                              (items.first.value == 0 ? 1 : items.first.value),
                          type: PercentageDisplayType.linear,
                          color: cs.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OkbAkbMonthly extends StatelessWidget {
  final MainReport? report;
  const _OkbAkbMonthly({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    if (report == null) {
      return const SizedBox.shrink();
    }
    final akbPercent = report!.countAKB > 0
        ? (report!.countAKB / report!.countOKB * 100)
        : 0.0;
    return Row(
      children: [
        Expanded(
          child: _GlassCard(
            child: AnimatedPercentageWidget(
              percentage: akbPercent / 100.0,
              type: PercentageDisplayType.circular,
              color: cs.primary,
              label: 'AKB %',
              valueText: '${akbPercent.toStringAsFixed(2)}%',
              size: 100,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(context, l10n.monthlyOKB, report!.countOKB.toString()),
                const SizedBox(height: 6),
                _kv(context, l10n.akbPlan, report!.countAKB.toString()),
                const SizedBox(height: 6),
                _kv(context, l10n.akbFact, report!.countAKB.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(
          v,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.08),
            cs.surfaceVariant.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ma\'lumotlar Telegram hisobotidan import qilingan. Yangi manbaga o\'tish uchun matnni o\'zgartirishingiz mumkin — UI yangilanadi.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRangeCalendar extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _CustomRangeCalendar({required this.startDate, required this.endDate});

  @override
  State<_CustomRangeCalendar> createState() => _CustomRangeCalendarState();
}

class _CustomRangeCalendarState extends State<_CustomRangeCalendar> {
  late DateTime _currentMonth;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _currentMonth = DateTime(_startDate.year, _startDate.month, 1);
  }

  bool _isDateInRange(DateTime date) {
    return date.isAtSameMomentAs(_startDate) ||
        date.isAtSameMomentAs(_endDate) ||
        (date.isAfter(_startDate) && date.isBefore(_endDate));
  }

  bool _isStartDate(DateTime date) {
    return date.isAtSameMomentAs(_startDate);
  }

  bool _isEndDate(DateTime date) {
    return date.isAtSameMomentAs(_endDate);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Adjust for Monday as first day of week
    final adjustedFirstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

    return Column(
      children: [
        // Month/Year header with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left, color: cs.primary),
            ),
            Text(
              DateFormat('MMMM yyyy', 'uz').format(_currentMonth),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right, color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekday headers
        Row(
          children: ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
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

            final isInRange = _isDateInRange(currentDate);
            final isStart = _isStartDate(currentDate);
            final isEnd = _isEndDate(currentDate);

            return Container(
              decoration: BoxDecoration(
                color: isInRange ? cs.primary.withOpacity(0.2) : cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isStart || isEnd
                      ? cs.primary
                      : isInRange
                      ? cs.primary.withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  dayOffset.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isStart || isEnd
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: isInRange ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildLegendItem(cs.primary, 'Hisobot davri')],
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// =====================
/// Parsing & Model Layer
/// =====================
// class DailyRepor {
//    final DateTime? dateTime;
//    final DateTime? dateStart;
//    final DateTime? dateEnd;
//    final String agentName;
//    final String territoryLabel;
//
//   // Today
//   final int okbTerritory;
//   final int visitedTT;
//   final int activeToday;
//
//   // Orders
//   final double cash;
//   final double cashless;
//   final double totalOrders;
//
//   // Regions & Categories
//   final Map<String, int> akbByRegion;
//   final Map<String, int> categories;
//
//   // Monthly
//   final double plan;
//   final double fact;
//   final double forecast;
//   final double factPercent;
//   final double forecastPercent;
//   final int okbMonth;
//   final int akbPlan;
//   final int akbFact;
//   final double akbPercent;
//
//   DailyReport({
//     required this.dateTime,
//     this.dateStart,
//     this.dateEnd,
//     required this.agentName,
//     required this.territoryLabel,
//     required this.okbTerritory,
//     required this.visitedTT,
//     required this.activeToday,
//     required this.cash,
//     required this.cashless,
//     required this.totalOrders,
//     required this.akbByRegion,
//     required this.categories,
//     required this.plan,
//     required this.fact,
//     required this.forecast,
//     required this.factPercent,
//     required this.forecastPercent,
//     required this.okbMonth,
//     required this.akbPlan,
//     required this.akbFact,
//     required this.akbPercent,
//   });
//
//   String get formattedDateTime {
//     if (dateTime == null) return '-';
//     final d = dateTime!;
//     String two(int v) => v.toString().padLeft(2, '0');
//     return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
//   }
//
//   factory DailyReport.fromTelegram(String raw) {
//     String getLineAfter(String label) {
//       final m = RegExp(RegExp.escape(label) + r"\s*([^\n]+)").firstMatch(raw);
//       return (m != null ? m.group(1) : '')!.trim();
//     }
//
//     double parseMoney(String s) {
//       // Keep digits and separators
//       final cleaned = s.replaceAll(RegExp(r"[^0-9.,]"), '').replaceAll(' ', '').replaceAll(',', '.');
//       if (cleaned.isEmpty) return 0;
//       return double.tryParse(cleaned) ?? 0;
//     }
//
//     int parseCount(String s) {
//       final m = RegExp(r"(\d+)").firstMatch(s);
//       return int.tryParse(m?.group(1) ?? '0') ?? 0;
//     }
//
//     // Date
//     DateTime? dt;
//     DateTime? dateStart, dateEnd;
//     try {
//       final dateLine = getLineAfter('Sana:');
//       // Expect formats like 9-10-2025  14:30:54
//       final parts = RegExp(r"(\d{1,2})[-./](\d{1,2})[-./](\d{4})\s+(\d{1,2}):(\d{2})").firstMatch(dateLine);
//       if (parts != null) {
//         final d = int.parse(parts.group(1)!);
//         final m = int.parse(parts.group(2)!);
//         final y = int.parse(parts.group(3)!);
//         final hh = int.parse(parts.group(4)!);
//         final mm = int.parse(parts.group(5)!);
//         dt = DateTime(y, m, d, hh, mm);
//       }
//
//       // For SOAP API integration, extract dateStart and dateEnd
//       // These would come from the SOAP response, but for now we'll use defaults
//       final now = DateTime.now();
//       dateStart = DateTime(now.year, now.month, 1); // First day of current month
//       print('now: $now $dateStart  $dateEnd }');
//       dateEnd = DateTime(now.year, now.month + 1, 0); // Last day of current month
//     } catch (_) {}
//
//     // Agent name
//     final nameLine = getLineAfter('FIO:');
//     final agentName = nameLine.isEmpty ? '—' : nameLine;
//
//     // Territory
//     String territory = '—';
//     final terr = getLineAfter('Hudud :');
//     final terrM = RegExp(r"\('([^']+)'\)").firstMatch(terr);
//     if (terrM != null) territory = terrM.group(1)!;
//
//     // Today block
//     final okbTerritory = parseCount(getLineAfter('Hudud bo\'yicha OKB --'));
//     final visited = parseCount(getLineAfter('Bugun tashrif buyurilgan savdo nuqtalari soni  --'));
//     final active = parseCount(getLineAfter('Bugun faol mijozlar  --'));
//
//     // Orders block
//     final cash = parseMoney(getLineAfter('Naqd  --'));
//     final cashless = parseMoney(getLineAfter('Naqdsiz  --'));
//     final total = parseMoney(getLineAfter('Buyurtmalar umumiy summasi  --'));
//
//     // Regions section
//     Map<String, int> regions = {};
//     final regionSection = _sectionBetween(raw, 'AKB hududlar bo\'yicha taqsimlanishi:', 'Buyurtmalar umumiy summasi:');
//     for (final line in regionSection.split('\n')) {
//       final m = RegExp(r"^\s*([^\-\n]+?)\s*--\s*(\d+)").firstMatch(line);
//       if (m != null) {
//         regions[m.group(1)!.trim()] = int.parse(m.group(2)!);
//       }
//     }
//
//     // Categories section
//     Map<String, int> categories = {};
//     final catSection = _sectionBetween(raw, 'AKB tovar kategoriyalari bo\'yicha:', '✿');
//     for (final line in catSection.split('\n')) {
//       final m = RegExp(r"^\s*([^\-\n]+?)\s*--\s*(\d+)").firstMatch(line);
//       if (m != null) {
//         categories[m.group(1)!.trim()] = int.parse(m.group(2)!);
//       }
//     }
//
//     // Monthly block
//     final plan = parseMoney(getLineAfter('Reja  --'));
//     final fact = parseMoney(getLineAfter('Fakt  --'));
//     final factP = parseMoney(getLineAfter('Fakt foizda  --'));
//     final forecast = parseMoney(getLineAfter('Bashorat  --'));
//     final forecastP = parseMoney(getLineAfter('Bashorat foizda  --'));
//
//     final okbMonth = parseCount(getLineAfter('OKB  --'));
//     final akbPlan = parseCount(getLineAfter('AKB reja  --'));
//     final akbFact = parseCount(getLineAfter('AKB fakt  --'));
//     final akbP = parseMoney(getLineAfter('AKB foizda --'));
//
//     return DailyReport(
//       dateTime: dt,
//       dateStart: dateStart,
//       dateEnd: dateEnd,
//       agentName: agentName,
//       territoryLabel: territory,
//       okbTerritory: okbTerritory,
//       visitedTT: visited,
//       activeToday: active,
//       cash: cash,
//       cashless: cashless,
//       totalOrders: total,
//       akbByRegion: regions.isEmpty ? {'—': 0} : regions,
//       categories: categories.isEmpty ? {'—': 0} : categories,
//       plan: plan,
//       fact: fact,
//       forecast: forecast,
//       factPercent: factP,
//       forecastPercent: forecastP,
//       okbMonth: okbMonth,
//       akbPlan: akbPlan,
//       akbFact: akbFact,
//       akbPercent: akbP,
//     );
//   }
// }

String _sectionBetween(String raw, String start, String end) {
  final sIdx = raw.indexOf(start);
  if (sIdx == -1) return '';
  final from = sIdx + start.length;
  final eIdx = raw.indexOf(end, from);
  final to = eIdx == -1 ? raw.length : eIdx;
  return raw.substring(from, to).trim();
}

String formatCurrencyUz(num n) {
  // space-separated thousands, no currency symbol; append " so'm" where needed externally
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final remaining = s.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buf.write(' ');
  }
  return '${buf.toString()} so\'m';
}
