import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';

import 'dart:ui'; // blur uchun

import '../../../../core/router/app_router.dart';
import '../../../navbars/fluid_nav_bar.dart';
// (ixtiyoriy) agar Light/Dark toggle qo‘ymoqchi bo‘lsangiz, quyidagini oching:
// import '../../../../theme/theme_controller.dart';
// import '../../../../theme/theme_toggle.dart';
enum _ViewMode { list, grid }

String? _safePhotoUrl(dynamic tp) {
  try {
    final u = (tp as dynamic).photoUrl;
    if (u is String && u.trim().isNotEmpty) return u;
  } catch (_) {}
  try {
    final u = (tp as dynamic).imageUrl;
    if (u is String && u.trim().isNotEmpty) return u;
  } catch (_) {}
  try {
    final u = (tp as dynamic).avatar;
    if (u is String && u.trim().isNotEmpty) return u;
  } catch (_) {}
  try {
    final u = (tp as dynamic).logo;
    if (u is String && u.trim().isNotEmpty) return u;
  } catch (_) {}
  return null; // yo‘q bo‘lsa — default avatar ishlatiladi
}

class TradingPointsPage extends StatefulWidget {
  const TradingPointsPage({super.key});

  @override
  State<TradingPointsPage> createState() => _TradingPointsPageState();
}

class _TradingPointsPageState extends State<TradingPointsPage> {

  final TextEditingController _searchController = TextEditingController();
  List<TradingPoint> _allTradingPoints = [];
  List<TradingPoint> _filteredTradingPoints = [];
  bool _isLoading = true;
  String userCode = "";
  String password = "";

  bool _showViewBar = false;               // ADD: panel ko'rinish holati
  _ViewMode _viewMode = _ViewMode.list;    // ADD: hozirgi ko'rinish

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
      });

      if (userCode.isNotEmpty && password.isNotEmpty) {
        _loadTradingPoints();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // ignore
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTradingPoints() async {
    if (userCode.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repository = sl<AgentRepository>();
      final tradingPoints = await repository.getClients(
        userCode: userCode,
        password: password,
      );

      _allTradingPoints = tradingPoints;
      _filteredTradingPoints = List.from(_allTradingPoints);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mijozlar ma\'lumotlarini yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTradingPoints(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTradingPoints = List.from(_allTradingPoints);
      } else {
        _filteredTradingPoints = _allTradingPoints.where((tp) {
          final q = query.toLowerCase();
          return tp.name.toLowerCase().contains(q) ||
              tp.address.toLowerCase().contains(q) ||
              tp.contactPerson.toLowerCase().contains(q) ||
              tp.ownerName.toLowerCase().contains(q) ||
              tp.inn.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon raqami ko\'rsatilmagan')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon qo\'ng\'irog\'i amalga oshirilmadi')),
        );
      }
    }
  }

  Future<void> _informVisit(TradingPoint tradingPoint) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Tashrif haqida xabar berilmoqda...'),
          ],
        ),
      ),
    );

    // TODO: serverga yuborish (o‘zgarmagan mantiq)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop();

    setState(() {
      final index = _allTradingPoints.indexWhere((tp) => tp.id == tradingPoint.id);
      if (index != -1) {
        _allTradingPoints[index] = tradingPoint.copyWith(isVisited: true);
        _filterTradingPoints(_searchController.text);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tradingPoint.name} ga tashrif haqida xabar berildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createOrder(TradingPoint tradingPoint) {
    // TODO: Navigate to order creation page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tradingPoint.name} uchun buyurtma yaratish')),
    );
  }

  void _viewContracts(TradingPoint tradingPoint) {
    // TODO: Navigate to contracts page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tradingPoint.name} shartnomalarini ko\'rish')),
    );
  }

  void _showRefusalDialog(TradingPoint tradingPoint) {
    showDialog(
      context: context,
      builder: (context) => RefusalDialog(
        tradingPoint: tradingPoint,
        onRefusalSent: (reason) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tradingPoint.name} uchun rad etish sababi yuborildi: $reason'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  // ADD: Grid tile bosilganda batafsil oyna (bottom sheet) ochish
  void _openTpDetails(TradingPoint tp) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.60,
          builder: (_, scrollCtrl) {
            return _TradingPointDetailsSheet(
              tradingPoint: tp,
              scrollController: scrollCtrl,
              onCall: () => _makeCall(tp.phone),
              onInformVisit: () => _informVisit(tp),
              onCreateOrder: () => _createOrder(tp),
              onViewContracts: () => _viewContracts(tp),
              onRefusal: () => _showRefusalDialog(tp),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar — Material 3, AgentHome uslubi
      appBar: AppBar(
        title: Text('Savdo nuqtalari', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          // (ixtiyoriy) Light/Dark toggle qo‘yish uchun quyidagini oching:
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 8),
          //   child: ThemeToggle(
          //     mode: ThemeController.I.mode.value,
          //     onChanged: ThemeController.I.set,
          //   ),
          // ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'orders':
                // TODO
                  break;
                case 'new_client':
                // TODO
                  break;
                case 'orders_history':
                // TODO
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart),
                    SizedBox(width: 8),
                    Text('Buyurtmalar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_client',
                child: Row(
                  children: [
                    Icon(Icons.add_business),
                    SizedBox(width: 8),
                    Text('Yangi mijoz'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders_history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Buyurtmalar tarixi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // BODY — gradient fon + yuqorida qidiruv, pastda ro‘yxat
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(.08),
              theme.colorScheme.primaryContainer.withOpacity(.06),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search bar (M3 uslub, yumshoq soya)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SearchField(
                controller: _searchController,
                onChanged: _filterTradingPoints,
              ),
            ),
            // === ADD: yashirin/ko'rinar panel (son + list/grid tugmalar) ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showViewBar
                    ? _ViewToolbar(
                  count: _filteredTradingPoints.length,
                  mode: _viewMode,
                  onModeChanged: (m) => setState(() => _viewMode = m),
                  onCollapse: () => setState(() => _showViewBar = false),
                )
                    : Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Ko‘rinish paneli',
                    onPressed: () => setState(() => _showViewBar = true),
                    icon: const Icon(Icons.tune), // biriktirilgan namunadagi kabi "tune" tugma
                  ),
                ),
              ),
            ),
            // List

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTradingPoints.isEmpty
                  ? const _EmptyState()
                  : (_viewMode == _ViewMode.list
                  ? RefreshIndicator(
                onRefresh: _loadUserData,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _filteredTradingPoints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tp = _filteredTradingPoints[index];
                    // LIST: eski ExpansionTile kartamiz, lekin leading – foto
                    return TradingPointCard(
                      tradingPoint: tp,
                      onCall: () => _makeCall(tp.phone),
                      onInformVisit: () => _informVisit(tp),
                      onCreateOrder: () => _createOrder(tp),
                      onViewContracts: () => _viewContracts(tp),
                      onRefusal: () => _showRefusalDialog(tp),
                      onOpenDetails: () => _openTpDetails(tp),
                    );
                  },
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadUserData,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    // childAspectRatio: 0.82,
                    mainAxisExtent: 300,
                  ),
                  itemCount: _filteredTradingPoints.length,
                  itemBuilder: (context, index) {
                    final tp = _filteredTradingPoints[index];
                    // GRID: foto yuqorida, qolgan ma’lumotlar bitta ustunda pastda
                    return _TradingPointGridTile(
                      tp: tp,
                      onCall: () => _makeCall(tp.phone),
                      onInformVisit: () => _informVisit(tp),
                      onCreateOrder: () => _createOrder(tp),
                      onViewContracts: () => _viewContracts(tp),
                      onRefusal: () => _showRefusalDialog(tp),
                      onOpenDetails: () => _openTpDetails(tp),
                    );
                  },
                ),
              )),
            )

            // Expanded(
            //   child: _isLoading
            //       ? const Center(child: CircularProgressIndicator())
            //       : _filteredTradingPoints.isEmpty
            //       ? const _EmptyState()
            //       : RefreshIndicator(
            //     onRefresh: _loadUserData,
            //     child: _isLoading
            //         ? const Center(child: CircularProgressIndicator())
            //         : _filteredTradingPoints.isEmpty
            //         ? const _EmptyState()
            //         : (_viewMode == _ViewMode.list
            //         ? RefreshIndicator(
            //       onRefresh: _loadUserData,
            //       child: ListView.separated(
            //         padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            //         itemCount: _filteredTradingPoints.length,
            //         separatorBuilder: (_, __) => const SizedBox(height: 8),
            //         itemBuilder: (context, index) {
            //           final tp = _filteredTradingPoints[index];
            //           return TradingPointCard(
            //             tradingPoint: tp,
            //             onCall: () => _makeCall(tp.phone),
            //             onInformVisit: () => _informVisit(tp),
            //             onCreateOrder: () => _createOrder(tp),
            //             onViewContracts: () => _viewContracts(tp),
            //             onRefusal: () => _showRefusalDialog(tp),
            //           );
            //         },
            //       ),
            //     )
            //         : RefreshIndicator(
            //       onRefresh: _loadUserData,
            //       child: GridView.builder(
            //         padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //           crossAxisCount: 2,
            //           mainAxisSpacing: 8,
            //           crossAxisSpacing: 8,
            //           childAspectRatio: 0.92,
            //         ),
            //         itemCount: _filteredTradingPoints.length,
            //         itemBuilder: (context, index) {
            //           final tp = _filteredTradingPoints[index];
            //           // Grid’ga ham xuddi shu kartani qo‘llaymiz: ExpansionTile ochilmasa ham chiroyli turadi
            //           return TradingPointCard(
            //             tradingPoint: tp,
            //             onCall: () => _makeCall(tp.phone),
            //             onInformVisit: () => _informVisit(tp),
            //             onCreateOrder: () => _createOrder(tp),
            //             onViewContracts: () => _viewContracts(tp),
            //             onRefusal: () => _showRefusalDialog(tp),
            //           );
            //         },
            //       ),
            //     )),
            //
            //     // child: ListView.separated(
            //     //   padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            //     //   itemCount: _filteredTradingPoints.length,
            //     //   separatorBuilder: (_, __) => const SizedBox(height: 8),
            //     //   itemBuilder: (context, index) {
            //     //     final tp = _filteredTradingPoints[index];
            //     //     return TradingPointCard(
            //     //       tradingPoint: tp,
            //     //       onCall: () => _makeCall(tp.phone),
            //     //       onInformVisit: () => _informVisit(tp),
            //     //       onCreateOrder: () => _createOrder(tp),
            //     //       onViewContracts: () => _viewContracts(tp),
            //     //       onRefusal: () => _showRefusalDialog(tp),
            //     //     );
            //     //   },
            //     // ),
            //   ),
            // ),
          ],
        ),
      ),

      // Pastki menyu — mavjud nav bar (o‘zgarmagan)
      bottomNavigationBar: FluidNavBar(
        initialIndex: 2, // mavjud tanlov
        items: [
          FluidNavItem(
            icon: Icons.home,
            label: 'Home',
            onTap: () => Navigator.pushNamed(context, AppRouter.agentHomeRoute),
          ),
          FluidNavItem(
            icon: Icons.add_shopping_cart,
            label: 'Buyurtma',
            // onTap: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
          ),
          FluidNavItem(
            icon: Icons.people,
            label: 'Mijozlar',
            onTap: () => Navigator.pushNamed(context, AppRouter.tradingPointsRoute),
          ),
          const FluidNavItem(
            icon: Icons.storefront,
            label: 'Tovarlar',
          ),
          const FluidNavItem(
            icon: Icons.insert_chart_outlined,
            label: 'Hisobot',
          ),
        ],
      ),
    );
  }
}



// Aliasing original model
typedef TradingPoint = model.TradingPoint;

/// M3 uslubdagi qidiruv
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Qidirish...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }
}

/// Bo‘sh state (topilmadi)
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.find_in_page_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 8),
          Text('Savdo nuqtalari topilmadi', style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class TradingPointCard extends StatelessWidget {
  final TradingPoint tradingPoint;
  final VoidCallback onCall;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;

  const TradingPointCard({
    super.key,
    required this.tradingPoint,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final visitedColor = tradingPoint.isVisited ? Colors.green : Colors.orange;
    final visitedIcon = tradingPoint.isVisited ? Icons.check_circle : Icons.location_on;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading:  _AvatarLeading(tp: tradingPoint, visited: tradingPoint.isVisited),

      title: Text(
          tradingPoint.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(Icons.place_outlined, tradingPoint.address, soft: true),
              const SizedBox(height: 2),
              _line(Icons.badge_outlined, 'INN: ${tradingPoint.inn}'),
            ],
          ),
        ),
        children: [
          // Kontaktlar
          Row(
            children: [
              const Icon(Icons.person, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Aloqa: ${tradingPoint.contactPerson}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 8),
              InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  tradingPoint.phone,
                  style: TextStyle(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Actions — Material 3 uslub: Filled, Tonal, Outlined kombinatsiyasi
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!tradingPoint.isVisited)
                FilledButton.icon(
                  onPressed: onInformVisit,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Tashrif'),
                ),
              FilledButton.tonalIcon(
                onPressed: onCreateOrder,
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: const Text('Buyurtma'),
              ),
              if (tradingPoint.hasContract)
                OutlinedButton.icon(
                  onPressed: onViewContracts,
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text('Shartnoma'),
                ),
              OutlinedButton.icon(
                onPressed: onRefusal,
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Rad etish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, {bool soft = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: soft ? null : Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RefusalDialog extends StatefulWidget {
  final TradingPoint tradingPoint;
  final Function(String) onRefusalSent;

  const RefusalDialog({
    super.key,
    required this.tradingPoint,
    required this.onRefusalSent,
  });

  @override
  State<RefusalDialog> createState() => _RefusalDialogState();
}

class _RefusalDialogState extends State<RefusalDialog> {
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _refusalReasons = const [
    'Mijoz yo\'q',
    'Vaqt yo\'q',
    'Mahsulot kerak emas',
    'Narx mos kelmaydi',
    'Boshqa ta\'minotchi bilan ishlaydi',
    'Boshqa sabab',
  ];

  Future<void> _sendRefusal() async {
    if (_selectedReason == null) return;
    setState(() => _isLoading = true);
    // TODO: Send to server (unchanged)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onRefusalSent(_selectedReason!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Rad etish sababi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.tradingPoint.name} uchun rad etish sababini tanlang:'),
          const SizedBox(height: 12),
          ..._refusalReasons.map((reason) => RadioListTile<String>(
            title: Text(reason),
            value: reason,
            groupValue: _selectedReason,
            activeColor: cs.primary,
            onChanged: (value) => setState(() => _selectedReason = value),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedReason == null ? null : _sendRefusal,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Yuborish'),
        ),
      ],
    );
  }
}
// ADD: Ko'rinish paneli (count + list/grid tugmalar + yopish ikon)
class _ViewToolbar extends StatelessWidget {
  final int count;
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onModeChanged;
  final VoidCallback onCollapse;
  const _ViewToolbar({
    required this.count,
    required this.mode,
    required this.onModeChanged,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color _iconColor(bool active) =>
        active ? cs.primary : cs.onSurface.withOpacity(.45);

    return Row(
      children: [
        // Mijozlar soni
        Text(
          'Mijozlar soni: $count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),

        // List tugma
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onModeChanged(_ViewMode.list),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Icons.view_agenda_rounded, // list
              size: 22,
              color: _iconColor(mode == _ViewMode.list),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Grid tugma
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onModeChanged(_ViewMode.grid),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Icons.grid_view_rounded, // grid
              size: 22,
              color: _iconColor(mode == _ViewMode.grid),
            ),
          ),
        ),

        const SizedBox(width: 6),
        // Yopish
        IconButton(
          tooltip: 'Yopish',
          onPressed: onCollapse,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}


class TradingPointGridCard extends StatelessWidget {
  final TradingPoint tradingPoint;
  final VoidCallback onCall;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;

  const TradingPointGridCard({
    super.key,
    required this.tradingPoint,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
  });

  String? _photo(TradingPoint t) {
    final candidates = <String?>[
      (t as dynamic).photoUrl as String?,
      (t as dynamic).imageUrl as String?,
      (t as dynamic).avatarUrl as String?,
    ];
    for (final s in candidates) {
      if (s != null && s.trim().isNotEmpty) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _photo(tradingPoint);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FOTO (yuqori)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: url == null
                      ? Container(
                    color: cs.surfaceContainerHighest,
                    child: const Icon(Icons.storefront, size: 40),
                  )
                      : ImageFiltered(
                    imageFilter: tradingPoint.isVisited
                        ? ImageFilter.blur(sigmaX: 3, sigmaY: 3)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                ),
                if (tradingPoint.isVisited)
                  Container(
                    color: Colors.black.withOpacity(0.22),
                    height: double.infinity,
                    width: double.infinity,
                  ),
              ],
            ),
          ),

          // MA’LUMOTLAR (bitta ustunda)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tradingPoint.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(tradingPoint.address, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text('INN: ${tradingPoint.inn}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                // amallar — ixcham
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (!tradingPoint.isVisited)
                      FilledButton.icon(
                        onPressed: onInformVisit,
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Tashrif'),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: onCreateOrder,
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('Buyurtma'),
                    ),
                    if (tradingPoint.hasContract)
                      OutlinedButton.icon(
                        onPressed: onViewContracts,
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Shartnoma'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onRefusal,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Rad etish'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarLeading extends StatelessWidget {
  final TradingPoint tp;
  final bool visited;
  const _AvatarLeading({required this.tp, required this.visited});

  @override
  Widget build(BuildContext context) {
    final url = _safePhotoUrl(tp);

    Widget img = ClipOval(
      child: SizedBox(
        width: 56, height: 56,
        child: url == null
            ? _DefaultAvatar(name: tp.name)               // default avatar
            : _NetAvatar(url: url, visited: visited),      // network avatar
      ),
    );

    // Tashrif qilinganida — engil kulrang shaffof qatlam
    if (visited) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          // grayscale matrix
          0.2126,0.7152,0.0722,0,0,
          0.2126,0.7152,0.0722,0,0,
          0.2126,0.7152,0.0722,0,0,
          0,     0,     0,     1,0,
        ]),
        child: Stack(children: [
          img,
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.22)),
          ),
        ]),
      );
    }
    return SizedBox(width: 56, height: 56, child: img);
  }
}

class _NetAvatar extends StatelessWidget {
  final String url;
  final bool visited;
  const _NetAvatar({required this.url, required this.visited});

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _DefaultAvatar(name: null),
      loadingBuilder: (c, child, prog) => prog == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
    // Yengil blur ham qo‘shmoqchi bo‘lsangiz (visited payti):
    return visited
        ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5), child: image)
        : image;
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String? name;
  const _DefaultAvatar({this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = (name ?? '').trim().isEmpty
        ? '??'
        : name!.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase();

    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
class _TradingPointGridTile extends StatelessWidget {
  final TradingPoint tp;
  final VoidCallback onCall, onInformVisit, onCreateOrder, onViewContracts, onRefusal;
  final VoidCallback onOpenDetails;
  const _TradingPointGridTile({
    required this.tp,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _safePhotoUrl(tp);
    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(16),

      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP: customer photo
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: _NetAvatar(url: _safePhotoUrl(tp) ?? '', visited: tp.isVisited),
                ),
                if (_safePhotoUrl(tp) == null)
                  Container(color: cs.primaryContainer), // default rang (agar rasm yo‘q bo‘lsa)
                if (tp.isVisited)
                  Container(color: Colors.black.withOpacity(.22)),
              ],
            ),
          ),
          // BODY: bitta ustunda ma'lumotlar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tp.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                _line(Icons.place_outlined, tp.address),
                const SizedBox(height: 2),
                _line(Icons.badge_outlined, 'INN: ${tp.inn}'),
              ],
            ),
          ),
          const Spacer(),
          // ACTIONS
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                if (!tp.isVisited) FilledButton.icon(onPressed: onInformVisit, icon: const Icon(Icons.location_on, size: 18), label: const Text('Tashrif')),
                FilledButton.tonalIcon(onPressed: onCreateOrder, icon: const Icon(Icons.shopping_cart, size: 18), label: const Text('Buyurtma')),
                if (tp.hasContract) OutlinedButton.icon(onPressed: onViewContracts, icon: const Icon(Icons.description, size: 18), label: const Text('Shartnoma')),
                OutlinedButton.icon(onPressed: onRefusal, icon: const Icon(Icons.cancel, size: 18), label: const Text('Rad etish')),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _line(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ],
  );
}
// ADD: Grid detail oynasi (modal bottom-sheet)
class _TradingPointDetailsSheet extends StatelessWidget {
  final TradingPoint tradingPoint;
  final ScrollController scrollController;
  final VoidCallback onCall;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;

  const _TradingPointDetailsSheet({
    super.key,
    required this.tradingPoint,
    required this.scrollController,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _safePhotoUrl(tradingPoint);

    return Material(
      color: cs.surface,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header image + title (uslub AgentHome bilan uyg‘un)
                _HeaderImage(url: url, visited: tradingPoint.isVisited),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tradingPoint.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Manzil
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tradingPoint.address)),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // INN
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('INN: ${tradingPoint.inn}')),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Aloqa shaxs va telefon
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Aloqa: ${tradingPoint.contactPerson}')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onCall,
                            borderRadius: BorderRadius.circular(6),
                            child: Text(
                              tradingPoint.phone,
                              style: TextStyle(
                                color: cs.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Actions (Material 3 ko‘rinishida)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!tradingPoint.isVisited)
                            FilledButton.icon(
                              onPressed: onInformVisit,
                              icon: const Icon(Icons.location_on, size: 18),
                              label: const Text('Tashrif'),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: onCreateOrder,
                            icon: const Icon(Icons.shopping_cart, size: 18),
                            label: const Text('Buyurtma'),
                          ),
                          if (tradingPoint.hasContract)
                            OutlinedButton.icon(
                              onPressed: onViewContracts,
                              icon: const Icon(Icons.description, size: 18),
                              label: const Text('Shartnoma'),
                            ),
                          OutlinedButton.icon(
                            onPressed: onRefusal,
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Rad etish'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
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

// Yordamchi: header image (blur/overlay tashrifda)
class _HeaderImage extends StatelessWidget {
  final String? url;
  final bool visited;
  const _HeaderImage({required this.url, required this.visited});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = 180.0;
    Widget content;

    if (url == null || url!.trim().isEmpty) {
      content = Container(
        height: h,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: Icon(Icons.storefront, size: 48)),
      );
    } else {
      content = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url!,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, p) => p == null
                  ? child
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorBuilder: (c, e, s) => Container(
                color: cs.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.storefront, size: 48)),
              ),
            ),
            if (visited)
              Container(color: Colors.black.withOpacity(0.22)),
          ],
        ),
      );
    }

    return SizedBox(height: h, child: content);
  }
}
