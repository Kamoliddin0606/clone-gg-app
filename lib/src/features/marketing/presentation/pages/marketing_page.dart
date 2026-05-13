import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/promotions_page.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/pages/notification_list_page.dart';

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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketing),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.marketingDataRefreshing)),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.promotions),
            Tab(text: l10n.announcements),
            Tab(text: l10n.news),
            Tab(text: l10n.prices),
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
          children: [
            const PromotionsPage(),
            // Announcements tab is now the notification feed — system
            // announcements, debt alerts, etc. all surface here.
            // See docs/notifications/passport-mobile.md.
            const NotificationListView(),
            Center(child: Text(l10n.newsPage)),
            Center(child: Text(l10n.pricesPage)),
          ],
        ),
      ),
    );
  }
}
