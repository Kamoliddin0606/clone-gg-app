import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/promotions_page.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yangilash',
            onPressed: () {
              // TODO: Implement refresh functionality for marketing data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marketing ma\'lumotlari yangilanmoqda...')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aksiyalar'),
            Tab(text: 'E\'lonlar'),
            Tab(text: 'Yangiliklar'),
            Tab(text: 'Narxlar'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(.08),
              cs.primaryContainer.withOpacity(.06),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            PromotionsPage(),
            Center(child: Text('E\'lonlar sahifasi')),
            Center(child: Text('Yangiliklar sahifasi')),
            Center(child: Text('Narxlar sahifasi')),
          ],
        ),
      ),
    );
  }
}