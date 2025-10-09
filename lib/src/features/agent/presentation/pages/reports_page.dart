import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/reports_sync_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../navbars/agent_bottom_nav_bar.dart';
import 'main_report_page.dart';
import 'visits_report_page.dart';
import 'akb_client_report_page.dart';
import 'generic_report_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedReport = 'asosiy_hisobotlar';
  DateTimeRange? _selectedDateRange;
  bool _isMenuOpen = false;
  bool _isHeaderVisible = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuSlide;     // -1..0 (menu)
  late Animation<double> _contentSlide;  // 0..0.8 (main content)
  late AnimationController _headerAnimationController;
  late Animation<double> _headerScale;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late PageController _pageController;

  final prefs = sl<SharedPreferencesService>();
  late final userCode = prefs.getUserCode() ?? '';
  late final password = prefs.getPassword() ?? '';


  final List<Map<String, dynamic>> _reportItems = [
    {'key': 'asosiy_hisobotlar', 'title': 'Asosiy hisobotlar', 'icon': Icons.bar_chart, 'description': 'KPI ko\'rsatkichlari va asosiy statistikalar'},
    {'key': 'vizitlar_hisobot', 'title': 'Vizitlar bo\'yicha hisobot', 'icon': Icons.location_on, 'description': 'Mijozlarga qilingan tashriflar haqida ma\'lumot'},
    {'key': 'akb_client', 'title': 'AKB Client', 'icon': Icons.people, 'description': 'AKB mijozlari bo\'yicha hisobot'},
    {'key': 'akb_sum', 'title': 'AKB Sum', 'icon': Icons.attach_money, 'description': 'AKB summalari bo\'yicha moliyaviy hisobot'},
    {'key': 'akb_product', 'title': 'AKB Product', 'icon': Icons.inventory, 'description': 'AKB mahsulotlari bo\'yicha hisobot'},
    {'key': 'category_hisobotlari', 'title': 'Category hisobotlari', 'icon': Icons.category, 'description': 'Kategoriyalar bo\'yicha savdo tahlili'},
    {'key': 'oylik_natijalar', 'title': 'Oylik natijalar', 'icon': Icons.calendar_month, 'description': 'Oylik savdo natijalari va tendensiyalar'},
    {'key': 'oylik_kpi', 'title': 'Oylik KPI (maosh)', 'icon': Icons.trending_up, 'description': 'Oylik KPI bajarilishi va maosh hisoboti'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _getCurrentPageIndex());

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );
    _contentSlide = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start with header visible
    _headerAnimationController.value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Main content with slide animation
          AnimatedBuilder(
            animation: _contentSlide,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_contentSlide.value * MediaQuery.of(context).size.width, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.08),
                        colorScheme.primaryContainer.withOpacity(0.06),
                      ],
                    ),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: _isHeaderVisible ? 160 : kToolbarHeight,
                        surfaceTintColor: Colors.transparent,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // IconButton(
                            //   icon: const Icon(Icons.arrow_back),
                            //   onPressed: () => Navigator.of(context).pop(),
                            //   tooltip: 'Orqaga',
                            // ),
                            IconButton(
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.menu_close,
                                progress: _menuAnimationController,
                              ),
                              onPressed: _toggleMenu,
                              tooltip: 'Menyu',
                            ),
                          ],
                        ),
                        title: GestureDetector(
                          onTap: _toggleHeaderVisibility,
                          onDoubleTap: _toggleHeaderVisibility,
                          child: Text(
                            'Hisobotlar',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        flexibleSpace: _isHeaderVisible ? AnimatedBuilder(
                          animation: _headerAnimationController,
                          builder: (context, child) {
                            return GestureDetector(
                              onDoubleTap: _toggleHeaderVisibility,
                              child: Transform.scale(
                                scale: _headerScale.value,
                                child: Opacity(
                                  opacity: _headerOpacity.value,
                                  child: SlideTransition(
                                    position: _headerSlide,
                                    child: _buildHeader(context),
                                  ),
                                ),
                              ),
                            );
                          },
                        ) : null,
                        actions: [
                          IconButton(
                            tooltip: 'Headerni ${_isHeaderVisible ? "yashirish" : "ko\'rsatish"}',
                            onPressed: _toggleHeaderVisibility,
                            icon: Icon(_isHeaderVisible ? Icons.visibility_off : Icons.visibility),
                          ),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: null,
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            tooltip: 'Filtr',
                            onPressed: _showDateFilterDialog,
                            icon: const Icon(Icons.filter_list),
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200, // Adjust height as needed
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? _buildErrorState(context)
                              : _buildReportPageView(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Slide menu
          _buildSlideMenu(context),
        ],
      ),
      bottomNavigationBar: const AgentBottomNavBar(
        initialIndex: 4,
      ),
    );
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  void _toggleHeaderVisibility() {
    setState(() {
      _isHeaderVisible = !_isHeaderVisible;
      if (_isHeaderVisible) {
        _headerAnimationController.forward();
      } else {
        _headerAnimationController.reverse();
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedReport = _reportItems.firstWhere(
      (item) => item['key'] == _selectedReport,
      orElse: () => {'title': 'Hisobotlar', 'icon': Icons.bar_chart, 'description': 'Hisobotlar bo\'limi'},
    );

    return FlexibleSpaceBar(
      background: Container(
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
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                selectedReport['icon'] ?? Icons.bar_chart,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedReport['title'] ?? 'Hisobotlar',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedReport['description'] ?? 'Hisobotlar bo\'limi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSlideMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _menuSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_menuSlide.value * MediaQuery.of(context).size.width * 0.8, 0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            color: colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.bar_chart, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hisobotlar menyusi',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _reportItems.map((item) {
                      final isSelected = _selectedReport == item['key'];
                      return ListTile(
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? colorScheme.primary : null,
                        ),
                        title: Text(
                          item['title'],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isSelected ? colorScheme.primary : null,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedReport = item['key'];
                            _isMenuOpen = false;
                            _menuAnimationController.reverse();
                          });
                          final index = _reportItems.indexWhere((i) => i['key'] == item['key']);
                          if (index >= 0) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  void _showDateFilterDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        DateTimeRange? selectedRange = _selectedDateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            );

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Davrni tanlang',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date range ribbon display
                  if (selectedRange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${DateFormat('dd.MM.yyyy').format(selectedRange!.start)} - ${DateFormat('dd.MM.yyyy').format(selectedRange!.end)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                initialDateRange: selectedRange,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedRange = picked;
                                });
                              }
                            },
                            tooltip: 'Davrni o\'zgartirish',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextField(
                  //         decoration: InputDecoration(
                  //           labelText: 'Boshlanish sanasi',
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(12),
                  //           ),
                  //         ),
                  //         controller: TextEditingController(
                  //           text: selectedRange != null ? DateFormat('dd.MM.yyyy').format(selectedRange!.start) : '',
                  //         ),
                  //         readOnly: true,
                  //         onTap: () async {
                  //           final picked = await showDatePicker(
                  //             context: context,
                  //             initialDate: selectedRange?.start ?? DateTime.now().subtract(const Duration(days: 30)),
                  //             firstDate: DateTime(2020),
                  //             lastDate: DateTime.now(),
                  //           );
                  //           if (picked != null) {
                  //             setState(() {
                  //               selectedRange = DateTimeRange(
                  //                 start: picked,
                  //                 end: selectedRange?.end ?? picked.add(const Duration(days: 30)),
                  //               );
                  //             });
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Expanded(
                  //       child: TextField(
                  //         decoration: InputDecoration(
                  //           labelText: 'Tugash sanasi',
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(12),
                  //           ),
                  //         ),
                  //         controller: TextEditingController(
                  //           text: selectedRange != null ? DateFormat('dd.MM.yyyy').format(selectedRange!.end) : '',
                  //         ),
                  //         readOnly: true,
                  //         onTap: () async {
                  //           final picked = await showDatePicker(
                  //             context: context,
                  //             initialDate: selectedRange?.end ?? DateTime.now(),
                  //             firstDate: selectedRange?.start ?? DateTime(2020),
                  //             lastDate: DateTime.now(),
                  //           );
                  //           if (picked != null) {
                  //             setState(() {
                  //               selectedRange = DateTimeRange(
                  //                 start: selectedRange?.start ?? picked.subtract(const Duration(days: 30)),
                  //                 end: picked,
                  //               );
                  //             });
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),
                  // SizedBox(
                  //   height: 300,
                  //   child: CalendarDatePicker(
                  //     initialDate: selectedRange?.start ?? DateTime.now(),
                  //     firstDate: DateTime(2020),
                  //     lastDate: DateTime.now(),
                  //     onDateChanged: (date) {
                  //       // Handle single date selection - update range to single day
                  //       setState(() {
                  //         selectedRange = DateTimeRange(start: date, end: date);
                  //       });
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Bekor qilish'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final  reportSyncService = sl<ReportsSyncService>();
                            reportSyncService.syncAllReportsWithProgress( userCode: userCode, password: password, dateStart: selectedRange!.start, dateEnd: selectedRange!.end);
                            this.setState(() {
                              _selectedDateRange = selectedRange;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Qo\'llash'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _getCurrentPageIndex() {
    return _reportItems.indexWhere((item) => item['key'] == _selectedReport);
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < _reportItems.length) {
      setState(() {
        _selectedReport = _reportItems[index]['key'];
      });
    }
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Xatolik yuz berdi',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Noma\'lum xatolik',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = false;
                });
              },
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: _reportItems.map((item) {
        final key = item['key'] as String;
        return _getReportPage(key);
      }).toList(),
    );
  }

  Widget _getReportPage(String key) {
    switch (key) {
      case 'asosiy_hisobotlar':
        return const MainReportPage();
      case 'vizitlar_hisobot':
        return const VisitsReportPage();
      case 'akb_client':
        return const AkbClientReportPage();
      case 'akb_sum':
        return GenericReportPage(
          title: 'AKB Sum hisoboti',
          stats: [
            {'title': 'AKB summasi', 'value': '780 000 UZS', 'icon': Icons.attach_money, 'color': Colors.green},
            {'title': 'AKB rejasi', 'value': '1 000 000 UZS', 'icon': Icons.flag, 'color': Colors.blue},
          ],
        );
      case 'akb_product':
        return GenericReportPage(
          title: 'AKB Product hisoboti',
          stats: [
            {'title': 'AKB mahsulotlar', 'value': '156', 'icon': Icons.inventory, 'color': Colors.orange},
            {'title': 'Mahsulot turlari', 'value': '23', 'icon': Icons.category, 'color': Colors.purple},
          ],
        );
      case 'category_hisobotlari':
        return GenericReportPage(
          title: 'Category hisobotlari',
          stats: [
            {'title': 'Kategoriyalar soni', 'value': '12', 'icon': Icons.category, 'color': Colors.teal},
            {'title': 'Eng ko\'p sotilgan', 'value': 'Kosmetika', 'icon': Icons.star, 'color': Colors.amber},
          ],
        );
      case 'oylik_natijalar':
        return GenericReportPage(
          title: 'Oylik natijalar',
          stats: [
            {'title': 'Oylik savdo', 'value': '15 500 000 UZS', 'icon': Icons.calendar_month, 'color': Colors.indigo},
            {'title': 'Oylik o\'sish', 'value': '+15.3%', 'icon': Icons.trending_up, 'color': Colors.green},
          ],
        );
      case 'oylik_kpi':
        return GenericReportPage(
          title: 'Oylik KPI (maosh)',
          stats: [
            {'title': 'KPI bajarilishi', 'value': '85%', 'icon': Icons.trending_up, 'color': Colors.blue},
            {'title': 'Maosh miqdori', 'value': '2 500 000 UZS', 'icon': Icons.attach_money, 'color': Colors.green},
          ],
        );
      default:
        return const Center(child: Text('Hisobot mavjud emas'));
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class ReportsPage extends StatefulWidget {
//   const ReportsPage({super.key});
//
//   @override
//   State<ReportsPage> createState() => _ReportsPageState();
// }
//
// class _ReportsPageState extends State<ReportsPage> with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   String _selectedReport = 'asosiy_hisobotlar';
//   DateTimeRange? _selectedDateRange;
//   bool _isMenuOpen = false;
//   bool _isLoading = false;
//   String? _errorMessage;
//   late AnimationController _menuAnimationController;
//   late Animation<double> _menuAnimation;
//
//   final List<Map<String, dynamic>> _reportItems = [
//     {'key': 'asosiy_hisobotlar', 'title': 'Asosiy hisobotlar', 'icon': Icons.bar_chart},
//     {'key': 'vizitlar_hisobot', 'title': 'Vizitlar bo\'yicha hisobot', 'icon': Icons.location_on},
//     {'key': 'akb_client', 'title': 'AKB Client', 'icon': Icons.people},
//     {'key': 'akb_sum', 'title': 'AKB Sum', 'icon': Icons.attach_money},
//     {'key': 'akb_product', 'title': 'AKB Product', 'icon': Icons.inventory},
//     {'key': 'category_hisobotlari', 'title': 'Category hisobotlari', 'icon': Icons.category},
//     {'key': 'oylik_natijalar', 'title': 'Oylik natijalar', 'icon': Icons.calendar_month},
//     {'key': 'oylik_kpi', 'title': 'Oylik KPI (maosh)', 'icon': Icons.trending_up},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _menuAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _menuAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
//       CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _menuAnimationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Scaffold(
//       key: _scaffoldKey,
//       body: Stack(
//         children: [
//           // Main content with slide animation
//           AnimatedBuilder(
//             animation: _menuAnimation,
//             builder: (context, child) {
//               return Transform.translate(
//                 offset: Offset(_menuAnimation.value * MediaQuery.of(context).size.width * 0.8, 0),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         colorScheme.primary.withOpacity(0.08),
//                         colorScheme.primaryContainer.withOpacity(0.06),
//                       ],
//                     ),
//                   ),
//                   child: CustomScrollView(
//                     slivers: [
//                       SliverAppBar(
//                         pinned: true,
//                         expandedHeight: 160,
//                         surfaceTintColor: Colors.transparent,
//                         leading: IconButton(
//                           icon: AnimatedIcon(
//                             icon: AnimatedIcons.menu_close,
//                             progress: _menuAnimationController,
//                           ),
//                           onPressed: _toggleMenu,
//                           tooltip: 'Menyu',
//                         ),
//                         flexibleSpace: _buildHeader(context),
//                         actions: [
//                           IconButton(
//                             tooltip: 'Filtr',
//                             onPressed: _showDateFilterDialog,
//                             icon: const Icon(Icons.filter_list),
//                           ),
//                         ],
//                       ),
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: _isLoading
//                               ? const Center(child: CircularProgressIndicator())
//                               : _errorMessage != null
//                                   ? _buildErrorState(context)
//                                   : _buildReportContent(context),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//           // Slide menu
//           _buildSlideMenu(context),
//         ],
//       ),
//     );
//   }
//
//   void _toggleMenu() {
//     setState(() {
//       _isMenuOpen = !_isMenuOpen;
//       if (_isMenuOpen) {
//         _menuAnimationController.forward();
//       } else {
//         _menuAnimationController.reverse();
//       }
//     });
//   }
//
//   Widget _buildHeader(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return FlexibleSpaceBar(
//       background: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               colorScheme.primary,
//               colorScheme.primaryContainer,
//             ],
//           ),
//         ),
//         padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             CircleAvatar(
//               radius: 28,
//               child: Text(
//                 'H',
//                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Hisobotlar',
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       color: colorScheme.onPrimary,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _getSelectedReportTitle(),
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: colorScheme.onPrimary.withOpacity(.8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildSlideMenu(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return AnimatedBuilder(
//       animation: _menuAnimation,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(_menuAnimation.value * MediaQuery.of(context).size.width * 0.8, 0),
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.8,
//             color: colorScheme.surface,
//             child: Column(
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
//                   decoration: BoxDecoration(
//                     color: colorScheme.primaryContainer,
//                   ),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundColor: colorScheme.primary,
//                         child: const Icon(Icons.bar_chart, color: Colors.white),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Hisobotlar menyusi',
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                                 color: colorScheme.onPrimaryContainer,
//                               ),
//                               maxLines: 3,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Menu items
//                 Expanded(
//                   child: ListView(
//                     padding: EdgeInsets.zero,
//                     children: _reportItems.map((item) {
//                       final isSelected = _selectedReport == item['key'];
//                       return ListTile(
//                         leading: Icon(
//                           item['icon'],
//                           color: isSelected ? colorScheme.primary : null,
//                         ),
//                         title: Text(
//                           item['title'],
//                           style: theme.textTheme.bodyLarge?.copyWith(
//                             color: isSelected ? colorScheme.primary : null,
//                             fontWeight: isSelected ? FontWeight.w600 : null,
//                           ),
//                         ),
//                         selected: isSelected,
//                         onTap: () {
//                           setState(() {
//                             _selectedReport = item['key'];
//                             _isMenuOpen = false;
//                             _menuAnimationController.reverse();
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildReportContent(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: colorScheme.surface,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _getSelectedReportTitle(),
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (_selectedDateRange != null)
//               Text(
//                 'Davri: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: colorScheme.onSurfaceVariant,
//                 ),
//               ),
//             const SizedBox(height: 24),
//             // Mock content based on selected report
//             _buildMockReportContent(context),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorState(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: colorScheme.surface,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 48,
//               color: colorScheme.error,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Xatolik yuz berdi',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 color: colorScheme.error,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _errorMessage ?? 'Noma\'lum xatolik',
//               textAlign: TextAlign.center,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 16),
//             FilledButton(
//               onPressed: () {
//                 setState(() {
//                   _errorMessage = null;
//                   _isLoading = false;
//                 });
//               },
//               child: const Text('Qayta urinish'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMockReportContent(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     switch (_selectedReport) {
//       case 'asosiy_hisobotlar':
//         return Column(
//           children: [
//             _buildStatCard('Jami savdo', '1 250 000 UZS', Icons.trending_up, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Mijozlar soni', '45', Icons.people, colorScheme.secondary),
//             const SizedBox(height: 12),
//             _buildStatCard('O\'rtacha savdo', '27 778 UZS', Icons.show_chart, colorScheme.tertiary),
//           ],
//         );
//       case 'vizitlar_hisobot':
//         return Column(
//           children: [
//             _buildStatCard('Amalga oshirilgan vizitlar', '32', Icons.location_on, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Rejalashtirilgan vizitlar', '18', Icons.schedule, colorScheme.secondary),
//             const SizedBox(height: 12),
//             _buildStatCard('Vizit samaradorligi', '78%', Icons.percent, colorScheme.tertiary),
//           ],
//         );
//       case 'akb_client':
//         return Column(
//           children: [
//             _buildStatCard('AKB mijozlar', '28', Icons.people, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('AKB foizi', '62%', Icons.percent, colorScheme.secondary),
//           ],
//         );
//       case 'akb_sum':
//         return Column(
//           children: [
//             _buildStatCard('AKB summasi', '780 000 UZS', Icons.attach_money, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('AKB rejasi', '1 000 000 UZS', Icons.flag, colorScheme.secondary),
//           ],
//         );
//       case 'akb_product':
//         return Column(
//           children: [
//             _buildStatCard('AKB mahsulotlar', '156', Icons.inventory, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Mahsulot turlari', '23', Icons.category, colorScheme.secondary),
//           ],
//         );
//       case 'category_hisobotlari':
//         return Column(
//           children: [
//             _buildStatCard('Kategoriyalar soni', '12', Icons.category, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Eng ko\'p sotilgan', 'Kosmetika', Icons.star, colorScheme.secondary),
//           ],
//         );
//       case 'oylik_natijalar':
//         return Column(
//           children: [
//             _buildStatCard('Oylik savdo', '15 500 000 UZS', Icons.calendar_month, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Oylik o\'sish', '+15.3%', Icons.trending_up, colorScheme.secondary),
//           ],
//         );
//       case 'oylik_kpi':
//         return Column(
//           children: [
//             _buildStatCard('KPI bajarilishi', '85%', Icons.trending_up, colorScheme.primary),
//             const SizedBox(height: 12),
//             _buildStatCard('Maosh miqdori', '2 500 000 UZS', Icons.attach_money, colorScheme.secondary),
//           ],
//         );
//       default:
//         return const Center(child: Text('Hisobot mavjud emas'));
//     }
//   }
//
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     final theme = Theme.of(context);
//
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(icon, color: color, size: 32),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     value,
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _getSelectedReportTitle() {
//     final item = _reportItems.firstWhere(
//       (item) => item['key'] == _selectedReport,
//       orElse: () => {'title': 'Hisobotlar'},
//     );
//     return item['title'];
//   }
//
//   void _showDateFilterDialog() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: colorScheme.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         DateTime startDate = _selectedDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30));
//         DateTime endDate = _selectedDateRange?.end ?? DateTime.now();
//
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Davrni tanlang',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           decoration: InputDecoration(
//                             labelText: 'Boshlanish sanasi',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           controller: TextEditingController(
//                             text: DateFormat('dd.MM.yyyy').format(startDate),
//                           ),
//                           readOnly: true,
//                           onTap: () async {
//                             final picked = await showDatePicker(
//                               context: context,
//                               initialDate: startDate,
//                               firstDate: DateTime(2020),
//                               lastDate: DateTime.now(),
//                             );
//                             if (picked != null) {
//                               setState(() {
//                                 startDate = picked;
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           decoration: InputDecoration(
//                             labelText: 'Tugash sanasi',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           controller: TextEditingController(
//                             text: DateFormat('dd.MM.yyyy').format(endDate),
//                           ),
//                           readOnly: true,
//                           onTap: () async {
//                             final picked = await showDatePicker(
//                               context: context,
//                               initialDate: endDate,
//                               firstDate: startDate,
//                               lastDate: DateTime.now(),
//                             );
//                             if (picked != null) {
//                               setState(() {
//                                 endDate = picked;
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   SizedBox(
//                     height: 300,
//                     child: CalendarDatePicker(
//                       initialDate: startDate,
//                       firstDate: DateTime(2020),
//                       lastDate: DateTime.now(),
//                       onDateChanged: (date) {
//                         // Handle single date selection if needed
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text('Bekor qilish'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: FilledButton(
//                           onPressed: () {
//                             this.setState(() {
//                               _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
//                             });
//                             Navigator.pop(context);
//                           },
//                           child: const Text('Qo\'llash'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }