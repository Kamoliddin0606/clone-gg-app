// Import necessary Dart and Flutter libraries for asynchronous operations, debugging, UI building, and dependency injection
import 'dart:async';
import 'package:flutter/foundation.dart'; // For kDebugMode and compute function
import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:get_it/get_it.dart'; // Dependency injection container
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking network connectivity
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart'; // Service for data synchronization
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart'; // Data model for promotions
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/widgets/promotion_card.dart'; // Widget for displaying promotion cards
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/widgets/promotion_card_shimmer.dart'; // Shimmer loading widget for promotion cards

/// PromotionsPage is a StatefulWidget that displays a list of promotions.
/// It handles loading promotions from cache and API, refreshing data, and managing offline/online states.
/// This page supports pull-to-refresh functionality and shows appropriate UI states (loading, error, empty).
class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

/// State class for PromotionsPage that manages the page's state and lifecycle.
/// Handles data loading, connectivity monitoring, and UI state management.
class _PromotionsPageState extends State<PromotionsPage> {
  // Dependency injection: Get the DataSyncService instance for data operations
  final DataSyncService _dataSyncService = GetIt.I<DataSyncService>();

  // Connectivity instance to monitor network status
  final Connectivity _connectivity = Connectivity();

  // List to hold the promotions data fetched from cache or API
  List<PromotionModel> _promotions = [];

  // Flag to indicate if the page is currently loading data for the first time
  bool _isLoading = true;

  // Flag to indicate if the page is currently refreshing data (pull-to-refresh)
  bool _isRefreshing = false;

  // Error message to display if data loading fails
  String? _errorMessage;

  // Flag to indicate if the device is offline
  bool _isOffline = false;

  // Subscription to listen for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Called when the widget is inserted into the widget tree.
  /// Initializes connectivity monitoring and starts loading promotions data.
  @override
  void initState() {
    super.initState();
    debugPrint('initState called: Initializing PromotionsPage state'); // Log: State initialization started
    debugPrint('initState: DataSyncService instance: $_dataSyncService'); // Log: Service instance
    debugPrint('initState: Connectivity instance: $_connectivity'); // Log: Connectivity instance
    debugPrint('initState: Initial state variables - _promotions: ${_promotions.length}, _isLoading: $_isLoading, _isRefreshing: $_isRefreshing, _errorMessage: $_errorMessage, _isOffline: $_isOffline'); // Log: Initial state values
    _initConnectivity(); // Initialize connectivity monitoring
    _loadPromotions(); // Start loading promotions data
    debugPrint('initState completed'); // Log: Initialization finished
  }

  /// Called when the widget is removed from the widget tree.
  /// Cancels the connectivity subscription to prevent memory leaks.
  @override
  void dispose() {
    debugPrint('dispose called: Cleaning up PromotionsPage state'); // Log: Disposal started
    debugPrint('dispose: Cancelling connectivity subscription: $_connectivitySubscription'); // Log: Subscription being cancelled
    _connectivitySubscription?.cancel(); // Cancel the connectivity subscription
    debugPrint('dispose: Connectivity subscription cancelled'); // Log: Subscription cancelled
    super.dispose();
    debugPrint('dispose completed'); // Log: Disposal finished
  }

  /// Initializes connectivity monitoring by checking the current connectivity status
  /// and setting up a listener for connectivity changes.
  Future<void> _initConnectivity() async {
    debugPrint('_initConnectivity called: Starting connectivity initialization'); // Log: Method entry
    // Check initial connectivity status
    final results = await _connectivity.checkConnectivity();
    debugPrint('_initConnectivity: Initial connectivity results: $results'); // Log: Initial connectivity check results
    _updateConnectionStatus(results); // Update the connection status based on results

    // Listen for connectivity changes and update status accordingly
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus, // Callback to handle status updates
    );
    debugPrint('_initConnectivity: Connectivity listener set up'); // Log: Listener initialized
    debugPrint('_initConnectivity completed'); // Log: Method exit
  }

  /// Updates the connection status based on the provided connectivity results.
  /// If the device comes back online and there is cached data, attempts background sync.
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    debugPrint('_updateConnectionStatus called with results: $results'); // Log: Method entry with input data
    final wasOffline = _isOffline; // Store previous offline state
    debugPrint('_updateConnectionStatus: Previous offline state: $wasOffline'); // Log: Previous state
    setState(() {
      // Determine if offline: true if no connectivity or all results are none
      _isOffline = results.contains(ConnectivityResult.none) ||
                    results.every((result) => result == ConnectivityResult.none);
    });
    debugPrint('_updateConnectionStatus: Updated offline state: $_isOffline'); // Log: New state

    // If we came back online and had cached data, try to sync in background
    if (wasOffline && !_isOffline && _promotions.isNotEmpty) {
      debugPrint('_updateConnectionStatus: Came back online with cached data, starting background sync'); // Log: Condition met for sync
      _syncPromotionsInBackground(); // Perform background synchronization
    } else {
      debugPrint('_updateConnectionStatus: No sync needed - wasOffline: $wasOffline, isOffline: $_isOffline, hasPromotions: ${_promotions.isNotEmpty}'); // Log: Why no sync
    }
    debugPrint('_updateConnectionStatus completed'); // Log: Method exit
  }

  /// Loads promotions data by first attempting to load from cache,
  /// then synchronizing in the background if possible.
  /// Updates the UI state accordingly (loading, error, or data display).
  Future<void> _loadPromotions() async {
    debugPrint('_loadPromotions called: Starting to load promotions'); // Log: Method entry
    debugPrint('_loadPromotions: Current state before loading - _isLoading: $_isLoading, _promotions length: ${_promotions.length}'); // Log: Initial state
    setState(() {
      _isLoading = true; // Set loading flag to show loading UI
      _errorMessage = null; // Clear any previous error messages
    });
    debugPrint('_loadPromotions: State updated - _isLoading: $_isLoading, _errorMessage: $_errorMessage'); // Log: State after update

    try {
      // Load from cache first for immediate display
      debugPrint('_loadPromotions: Attempting to load cached promotions'); // Log: Cache loading start
      final cachedPromotions = await _dataSyncService.getCachedPromotions();
      debugPrint('_loadPromotions: Cached promotions received - length: ${cachedPromotions.length}, isNotEmpty: ${cachedPromotions.isNotEmpty}'); // Log: Cache data received
      print('cache data promotions: ${cachedPromotions.isNotEmpty}'); // Existing print statement
      if (cachedPromotions.isNotEmpty) {
        debugPrint('_loadPromotions: Cached data available, updating UI'); // Log: Cache data exists
        setState(() {
          _promotions = cachedPromotions; // Update promotions list with cached data
          _isLoading = false; // Stop loading since we have data to show
        });
        debugPrint('_loadPromotions: UI updated with cached data - _promotions length: ${_promotions.length}, _isLoading: $_isLoading'); // Log: UI updated
      } else {
        debugPrint('_loadPromotions: No cached data available'); // Log: No cache data
      }

      // Then try to sync in background to get fresh data
      debugPrint('_loadPromotions: Starting background sync for fresh data'); // Log: Background sync start
      await _syncPromotionsInBackground(); // Perform background synchronization
      debugPrint('_loadPromotions: Background sync completed'); // Log: Background sync done
    } catch (e) {
      debugPrint('_loadPromotions: Error occurred during loading - error: $e'); // Log: Error caught
      setState(() {
        _errorMessage = 'Ma\'lumotlarni yuklashda xatolik: $e'; // Set error message for UI
        _isLoading = false; // Stop loading
      });
      debugPrint('_loadPromotions: State updated due to error - _errorMessage: $_errorMessage, _isLoading: $_isLoading'); // Log: Error state
    }
    debugPrint('_loadPromotions completed'); // Log: Method exit
  }

  /// Synchronizes promotions data in the background using an isolate to avoid blocking the UI.
  /// Shows a snackbar if synchronization fails.
  Future<void> _syncPromotionsInBackground() async {
    debugPrint('_syncPromotionsInBackground called: Starting background sync'); // Log: Method entry
    debugPrint('_syncPromotionsInBackground: Current promotions count: ${_promotions.length}'); // Log: Current data state
    try {
      // Use isolate for non-blocking sync to prevent UI freezing
      debugPrint('_syncPromotionsInBackground: Launching isolate for sync'); // Log: Isolate launch
      await compute(_syncPromotionsIsolate, null); // Run sync in separate isolate
      debugPrint('_syncPromotionsInBackground: Isolate completed successfully'); // Log: Isolate success
    } catch (e) {
      debugPrint('_syncPromotionsInBackground: Error in background sync - error: $e'); // Log: Error occurred
      if (mounted) {
        debugPrint('_syncPromotionsInBackground: Showing error snackbar'); // Log: UI feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aksiyalar yangilanishida xatolik: $e')), // Display error message
        );
      } else {
        debugPrint('_syncPromotionsInBackground: Widget not mounted, skipping snackbar'); // Log: Widget not mounted
      }
    }
    debugPrint('_syncPromotionsInBackground completed'); // Log: Method exit
  }

  /// Static method that runs in an isolate to perform promotions synchronization.
  /// This method cannot access the widget's state or context.
  /// In a real implementation, this would initialize services and perform actual sync.
  static Future<void> _syncPromotionsIsolate(dynamic _) async {
    debugPrint('_syncPromotionsIsolate called: Running in isolate'); // Log: Isolate entry
    debugPrint('_syncPromotionsIsolate: Input parameter received (placeholder)'); // Log: Input data (should be null)
    // This would run in an isolate, but for simplicity we'll keep it simple
    // In a real implementation, you'd initialize services here and perform sync
    debugPrint('_syncPromotionsIsolate: Simulating sync operation (placeholder)'); // Log: Placeholder operation
    // Simulate some work
    await Future.delayed(const Duration(seconds: 1)); // Simulate async operation
    debugPrint('_syncPromotionsIsolate: Sync simulation completed'); // Log: Simulation done
    debugPrint('_syncPromotionsIsolate completed'); // Log: Isolate exit
  }

  /// Handles the pull-to-refresh action by forcing a refresh of promotions data from the API.
  /// Updates the UI to show refreshing state and displays error messages if needed.
  Future<void> _onRefresh() async {
    debugPrint('_onRefresh called: Starting pull-to-refresh'); // Log: Method entry
    debugPrint('_onRefresh: Current promotions count before refresh: ${_promotions.length}'); // Log: Current data
    setState(() {
      _isRefreshing = true; // Set refreshing flag to show refresh indicator
    });
    debugPrint('_onRefresh: State updated - _isRefreshing: $_isRefreshing'); // Log: Refreshing state

    try {
      // Force refresh from API to get latest data
      debugPrint('_onRefresh: Calling syncPromotions with forceRefresh: true'); // Log: API call start
      final freshPromotions = await _dataSyncService.syncPromotions(forceRefresh: true);
      debugPrint('_onRefresh: Fresh promotions received - length: ${freshPromotions.length}'); // Log: API response
      setState(() {
        _promotions = freshPromotions; // Update promotions with fresh data
      });
      debugPrint('_onRefresh: UI updated with fresh data - _promotions length: ${_promotions.length}'); // Log: UI updated
    } catch (e) {
      debugPrint('_onRefresh: Error during refresh - error: $e'); // Log: Error occurred
      if (mounted) {
        debugPrint('_onRefresh: Showing error snackbar'); // Log: UI feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yangilanishda xatolik: $e')), // Display error message
        );
      } else {
        debugPrint('_onRefresh: Widget not mounted, skipping snackbar'); // Log: Widget not mounted
      }
    } finally {
      debugPrint('_onRefresh: Finally block - resetting refreshing state'); // Log: Cleanup start
      setState(() {
        _isRefreshing = false; // Reset refreshing flag
      });
      debugPrint('_onRefresh: State updated - _isRefreshing: $_isRefreshing'); // Log: Refreshing reset
    }
    debugPrint('_onRefresh completed'); // Log: Method exit
  }

  /// Builds the main UI for the PromotionsPage.
  /// Returns a decorated container with gradient background, containing a refresh indicator
  /// and an offline banner if applicable.
  @override
  Widget build(BuildContext context) {
    debugPrint('build called: Building PromotionsPage UI'); // Log: Method entry
    debugPrint('build: Current state - _promotions: ${_promotions.length}, _isLoading: $_isLoading, _isRefreshing: $_isRefreshing, _isOffline: $_isOffline, _errorMessage: $_errorMessage'); // Log: Current state
    final cs = Theme.of(context).colorScheme; // Get color scheme from theme
    debugPrint('build: Color scheme primary: ${cs.primary}, primaryContainer: ${cs.primaryContainer}'); // Log: Theme colors

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, // Gradient starts from top-left
          end: Alignment.bottomRight, // Ends at bottom-right
          colors: [
            cs.primary.withOpacity(.08), // Light primary color with opacity
            cs.primaryContainer.withOpacity(.06), // Lighter primary container with opacity
          ],
        ),
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh, // Handle pull-to-refresh gesture
            child: _buildContent(), // Build the main content (list or states)
          ),
          if (_isOffline) // Show offline banner only when offline
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange, // Orange background for offline indicator
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16), // Offline icon
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline rejim - keshlangan ma\'lumotlar ko\'rsatilmoqda', // Offline message
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadPromotions, // Retry button to reload data
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                      ),
                      child: const Text(
                        'Yangilash', // Refresh button text
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
    debugPrint('build completed: UI built successfully'); // Log: Method exit
  }

  /// Builds the main content widget based on the current state.
  /// Returns different views: loading, error, empty, or the promotions list.
  Widget _buildContent() {
    debugPrint('_buildContent called: Determining content to display'); // Log: Method entry
    debugPrint('_buildContent: State check - _isLoading: $_isLoading, _promotions.isEmpty: ${_promotions.isEmpty}, _errorMessage: $_errorMessage'); // Log: State conditions

    if (_isLoading && _promotions.isEmpty) {
      debugPrint('_buildContent: Showing loading view - first load with no cached data'); // Log: Loading condition
      return _buildLoadingView(); // Show loading shimmer cards
    }

    if (_errorMessage != null && _promotions.isEmpty) {
      debugPrint('_buildContent: Showing error view - error: $_errorMessage, no data available'); // Log: Error condition
      return _buildErrorView(); // Show error message with retry option
    }

    if (_promotions.isEmpty) {
      debugPrint('_buildContent: Showing empty view - no promotions available'); // Log: Empty condition
      return _buildEmptyView(); // Show empty state message
    }

    debugPrint('_buildContent: Showing promotions list - count: ${_promotions.length}'); // Log: List condition
    return ListView.separated(
      itemCount: _promotions.length, // Number of promotion items
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), // Padding around the list
      physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even with few items
      separatorBuilder: (_, __) => const SizedBox(height: 8), // Space between items
      itemBuilder: (context, index) {
        debugPrint('_buildContent: Building item at index: $index'); // Log: Item building
        final promotion = _promotions[index]; // Get promotion at current index
        debugPrint('_buildContent: Promotion data - name: ${promotion.name}, code: ${promotion.code}, dateStart: ${promotion.dateStart}, dateEnd: ${promotion.dateEnd}'); // Log: Promotion data
        final description = _buildPromotionDescription(promotion); // Build description string
        debugPrint('_buildContent: Built description: $description'); // Log: Description
        final startDate = _formatDate(promotion.dateStart); // Format start date
        debugPrint('_buildContent: Formatted start date: $startDate'); // Log: Start date
        final endDate = _formatDate(promotion.dateEnd); // Format end date
        debugPrint('_buildContent: Formatted end date: $endDate'); // Log: End date
        return PromotionCard(
          name: promotion.name, // Promotion name
          id: promotion.code, // Promotion code/ID
          description: description, // Built description
          startDate: startDate, // Formatted start date
          endDate: endDate, // Formatted end date
          onTap: () => _navigateToDetail(promotion), // Tap handler for navigation
        );
      },
    );
    debugPrint('_buildContent completed: Content widget built'); // Log: Method exit
  }

  /// Builds the loading view with shimmer placeholders for promotion cards.
  /// Shows 5 shimmer cards to simulate loading state.
  Widget _buildLoadingView() {
    debugPrint('_buildLoadingView called: Building loading shimmer view'); // Log: Method entry
    debugPrint('_buildLoadingView: Creating 5 shimmer cards for loading state'); // Log: Shimmer count
    return ListView.separated(
      itemCount: 5, // Show 5 shimmer cards to indicate loading
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), // Consistent padding
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for loading view
      separatorBuilder: (_, __) => const SizedBox(height: 8), // Space between shimmers
      itemBuilder: (context, index) {
        debugPrint('_buildLoadingView: Building shimmer card at index: $index'); // Log: Shimmer building
        return const PromotionCardShimmer(); // Return shimmer widget
      },
    );
    debugPrint('_buildLoadingView completed: Loading view built'); // Log: Method exit
  }

  /// Builds the error view displaying the error message and a retry button.
  /// Centers the content and provides option to retry loading data.
  Widget _buildErrorView() {
    debugPrint('_buildErrorView called: Building error view'); // Log: Method entry
    debugPrint('_buildErrorView: Error message to display: $_errorMessage'); // Log: Error message
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red), // Error icon
          const SizedBox(height: 16), // Space below icon
          Text(
            _errorMessage ?? 'Xatolik yuz berdi', // Display error message or default
            textAlign: TextAlign.center, // Center text
            style: const TextStyle(fontSize: 16), // Text style
          ),
          const SizedBox(height: 16), // Space below text
          ElevatedButton(
            onPressed: _loadPromotions, // Retry button action
            child: const Text('Qayta urinib ko\'ring'), // Retry button text
          ),
        ],
      ),
    );
    debugPrint('_buildErrorView completed: Error view built'); // Log: Method exit
  }

  /// Builds the empty view when no promotions are available.
  /// Displays an icon and message indicating no promotions found.
  Widget _buildEmptyView() {
    debugPrint('_buildEmptyView called: Building empty state view'); // Log: Method entry
    debugPrint('_buildEmptyView: No promotions available to display'); // Log: Empty state
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey), // Empty icon
          SizedBox(height: 16), // Space below icon
          Text(
            'Aksiyalar topilmadi', // Empty state message
            style: TextStyle(fontSize: 18, color: Colors.grey), // Text style
          ),
        ],
      ),
    );
    debugPrint('_buildEmptyView completed: Empty view built'); // Log: Method exit
  }

  /// Builds a description string for a promotion based on its type, product count, and bonus count.
  /// Returns a formatted string describing the promotion details.
  String _buildPromotionDescription(PromotionModel promotion) {
    debugPrint('_buildPromotionDescription called with promotion: ${promotion.name}'); // Log: Method entry with input
    final productCount = promotion.productList.length; // Count of products in promotion
    debugPrint('_buildPromotionDescription: Product count: $productCount'); // Log: Product count
    final bonusCount = promotion.bonusList.length; // Count of bonuses in promotion
    debugPrint('_buildPromotionDescription: Bonus count: $bonusCount'); // Log: Bonus count
    final description = '${promotion.type} aksiyasi. $productCount ta mahsulot, $bonusCount ta bonus.'; // Build description
    debugPrint('_buildPromotionDescription: Built description: $description'); // Log: Output description
    return description; // Return the formatted description
    debugPrint('_buildPromotionDescription completed'); // Log: Method exit
  }

  /// Formats a DateTime object into a string in DD.MM.YYYY format.
  /// Pads day and month with leading zeros if necessary.
  String _formatDate(DateTime date) {
    debugPrint('_formatDate called with date: $date'); // Log: Method entry with input
    final formatted = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'; // Format date
    debugPrint('_formatDate: Formatted date: $formatted'); // Log: Output formatted date
    return formatted; // Return formatted date string
    debugPrint('_formatDate completed'); // Log: Method exit
  }

  /// Handles navigation to the promotion detail page.
  /// Currently shows a snackbar as placeholder for actual navigation.
  void _navigateToDetail(PromotionModel promotion) {
    debugPrint('_navigateToDetail called with promotion: ${promotion.name} (code: ${promotion.code})'); // Log: Method entry with input
    // TODO: Navigate to detail page with promotion data
    // Navigator.pushNamed(context, '/promotion-detail', arguments: promotion);
    debugPrint('_navigateToDetail: Showing snackbar instead of navigation (TODO)'); // Log: Placeholder action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promotion.name} tanlandi')), // Show selection confirmation
    );
    debugPrint('_navigateToDetail: Snackbar shown for promotion: ${promotion.name}'); // Log: UI feedback
    debugPrint('_navigateToDetail completed'); // Log: Method exit
  }
}