import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/promotion_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/widgets/promotion_card.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/widgets/promotion_card_shimmer.dart';

/// A page that displays a list of promotions with pull-to-refresh and offline support.
class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}
class _PromotionsPageState extends State<PromotionsPage> {
  final DataSyncService _dataSyncService = GetIt.I<DataSyncService>();
  final Connectivity _connectivity = Connectivity();
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadPromotions();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOffline = _isOffline;
    setState(() {
      _isOffline = results.contains(ConnectivityResult.none) ||
                    results.every((result) => result == ConnectivityResult.none);
    });

    if (wasOffline && !_isOffline && _promotions.isNotEmpty) {
      _syncPromotionsInBackground();
    }
  }

  Future<void> _loadPromotions() async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG: _loadPromotions called');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) print('[$timestamp] DEBUG: Fetching cached promotions');
      final cachedPromotions = await _dataSyncService.getCachedPromotions();
      if (kDebugMode) print('[$timestamp] DEBUG: Cached promotions count: ${cachedPromotions.length}');

      if (cachedPromotions.isNotEmpty) {
        setState(() {
          _promotions = cachedPromotions;
          _isLoading = false;
        });
        if (kDebugMode) print('[$timestamp] DEBUG: Set cached promotions to UI, count: ${cachedPromotions.length}');
      }

      if (kDebugMode) print('[$timestamp] DEBUG: Starting background sync');
      await _syncPromotionsInBackground();
    } catch (e) {
      if (kDebugMode) print('[$timestamp] DEBUG: Error in _loadPromotions: $e');
      setState(() {
        _errorMessage = 'Ma\'lumotlarni yuklashda xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncPromotionsInBackground() async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG: _syncPromotionsInBackground started');

    try {
      if (kDebugMode) print('[$timestamp] DEBUG: Calling _dataSyncService.syncPromotions');
      final freshPromotions = await _dataSyncService.syncPromotions(forceRefresh: true);
      if (kDebugMode) print('[$timestamp] DEBUG: Fresh promotions count: ${freshPromotions.length}');

      if (mounted) {
        setState(() {
          _promotions = freshPromotions;
          _isLoading = false; // In case it was still loading
        });
        if (kDebugMode) print('[$timestamp] DEBUG: Updated UI with fresh promotions, count: ${freshPromotions.length}');
      }
    } catch (e) {
      if (kDebugMode) print('[$timestamp] DEBUG: Error in _syncPromotionsInBackground: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aksiyalar yangilanishida xatolik: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG: _onRefresh called');

    setState(() {
      _isRefreshing = true;
    });

    try {
      if (kDebugMode) print('[$timestamp] DEBUG: Refreshing promotions');
      final freshPromotions = await _dataSyncService.syncPromotions(forceRefresh: true);
      if (kDebugMode) print('[$timestamp] DEBUG: Refreshed promotions count: ${freshPromotions.length}');

      setState(() {
        _promotions = freshPromotions;
      });
      if (kDebugMode) print('[$timestamp] DEBUG: Updated UI with refreshed promotions');
    } catch (e) {
      if (kDebugMode) print('[$timestamp] DEBUG: Error in _onRefresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yangilanishda xatolik: $e')),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
      if (kDebugMode) print('[$timestamp] DEBUG: _onRefresh completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
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
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh, // Handle pull-to-refresh gesture
            child: _buildContent(), // Build the main content (list or states)
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline rejim - keshlangan ma\'lumotlar ko\'rsatilmoqda',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadPromotions,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                      ),
                      child: const Text(
                        'Yangilash',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG UI: _buildContent called, isLoading: $_isLoading, promotions: ${_promotions.length}, error: $_errorMessage');

    if (_isLoading && _promotions.isEmpty) {
      if (kDebugMode) print('[$timestamp] DEBUG UI: Showing loading view');
      return _buildLoadingView();
    }

    if (_errorMessage != null && _promotions.isEmpty) {
      if (kDebugMode) print('[$timestamp] DEBUG UI: Showing error view');
      return _buildErrorView();
    }

    if (_promotions.isEmpty) {
      if (kDebugMode) print('[$timestamp] DEBUG UI: Showing empty view');
      return _buildEmptyView();
    }

    if (kDebugMode) print('[$timestamp] DEBUG UI: Building list view with ${_promotions.length} promotions');
    return ListView.separated(
      itemCount: _promotions.length,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final promotion = _promotions[index];
        final description = _buildPromotionDescription(promotion);
        final startDate = _formatDate(promotion.dateStart);
        final endDate = _formatDate(promotion.dateEnd);
        if (kDebugMode) print('[$timestamp] DEBUG UI: Building card for promotion ${promotion.code}: ${promotion.name}');
        return PromotionCard(
          name: promotion.name,
          id: promotion.code,
          description: description,
          startDate: startDate,
          endDate: endDate,
          onTap: () => _navigateToDetail(promotion),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return ListView.separated(
      itemCount: 5,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return const PromotionCardShimmer();
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Xatolik yuz berdi',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPromotions,
            child: const Text('Qayta urinib ko\'ring'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aksiyalar topilmadi',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _buildPromotionDescription(PromotionModel promotion) {
    final productCount = promotion.productList.length;
    final bonusCount = promotion.bonusList.length;
    return '${promotion.type} aksiyasi. $productCount ta mahsulot, $bonusCount ta bonus.';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _navigateToDetail(PromotionModel promotion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PromotionDetailPage(promotion: promotion),
      ),
    );
  }
}
