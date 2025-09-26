import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';

import '../../../../core/router/app_router.dart';
import '../../../navbars/fluid_nav_bar.dart';
// (ixtiyoriy) agar Light/Dark toggle qo‘ymoqchi bo‘lsangiz, quyidagini oching:
// import '../../../../theme/theme_controller.dart';
// import '../../../../theme/theme_toggle.dart';

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

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTradingPoints.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                onRefresh: _loadUserData,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _filteredTradingPoints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tp = _filteredTradingPoints[index];
                    return TradingPointCard(
                      tradingPoint: tp,
                      onCall: () => _makeCall(tp.phone),
                      onInformVisit: () => _informVisit(tp),
                      onCreateOrder: () => _createOrder(tp),
                      onViewContracts: () => _viewContracts(tp),
                      onRefusal: () => _showRefusalDialog(tp),
                    );
                  },
                ),
              ),
            ),
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
        leading: CircleAvatar(
          backgroundColor: visitedColor,
          child: Icon(visitedIcon, color: Colors.white),
        ),
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
