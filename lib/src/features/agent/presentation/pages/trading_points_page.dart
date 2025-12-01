import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart' as yandex;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/permissions_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart' hide MapType;
import 'package:gloria_marketing_flutter/src/core/maps/services/map_cache_service.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart' hide MarkerClusterConfig;
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/managers/marker_manager.dart' as marker_manager;
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../widgets/trading_points_filters_panel.dart';
import '../widgets/visit_indicators.dart';
import 'orders_page.dart';
import 'contracts_page.dart';
import '../widgets/yandex_map_builder.dart';
import 'map_pages/map_detail_page_google.dart';
import 'map_pages/map_detail_page_osm.dart';
import 'map_pages/map_detail_page_yandex.dart';
import 'visit_steps_page.dart';
import 'dart:ui'; // blur uchun
import 'dart:async';
import 'dart:math' as math; // For pi constant and math operations
import 'package:flutter/foundation.dart';

import '../../../../core/services/location_service.dart';



import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

// YandexMap vidjeti va MapWindow APIlari
import 'package:yandex_maps_mapkit/yandex_map.dart';

// MapKit core APIlari (MapKit, MapInputListener, UserLocationLayer, LocationManager, Point, CameraPosition, va h.k.)
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;

import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;
/// Transliterate Cyrillic characters to Latin (Uzbek standard)
String transliterateToLatin(String text) {
  const cyrillicToLatin = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': "'", 'ы': 'y', 'ь': "'", 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
    'Ж': 'J', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
    'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
    'Ф': 'F', 'Х': 'X', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
    'Ъ': "'", 'Ы': 'Y', 'Ь': "'", 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
  };

  return text.split('').map((char) => cyrillicToLatin[char] ?? char).join('');
}
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
    // PageStorage keys for state persistence
    static const String _searchTextKey = 'trading_points_search';
    static const String _filtersKey = 'trading_points_filters';
    static const String _viewModeKey = 'trading_points_view_mode';
    static const String _showFiltersKey = 'trading_points_show_filters';
    static const String _showViewBarKey = 'trading_points_show_view_bar';
    static const String _expandedIndexKey = 'trading_points_expanded_index';
    static const String _isAlphabeticalSortKey = 'trading_points_alphabetical_sort';
    static const String _isDistanceSortKey = 'trading_points_distance_sort';
    static const String _showVisitTodayOnlyKey = 'trading_points_visit_today_filter';

    final TextEditingController _searchController = TextEditingController();
    List<TradingPointWithPermissions> _allTradingPoints = [];
    List<TradingPointWithPermissions> _filteredTradingPoints = [];
    bool _isLoading = true;
    String userCode = "";
    String password = "";
    int? _expandedIndex;
    bool _showViewBar = false;               // ADD: panel ko'rinish holati
    _ViewMode _viewMode = _ViewMode.list;    // ADD: hozirgi ko'rinish
    Map<String, String> _regionNames = {};   // Business region code to name mapping

    // Permissions service
    PermissionsService? _permissionsService;

    // Sorting related
    bool _isAlphabeticalSort = true; // true = A-Z, false = Z-A
    bool _isDistanceSort = false; // true = distance sort, false = alphabetical
    Timer? _distanceUpdateTimer;
    LocationService? _locationService;

    // Permission related
    AppPermissionStatus _locationPermissionStatus = AppPermissionStatus.unknown;

    // Distance calculation cache for performance
    Map<String, double?> _distanceCache = {};
    Timer? _locationCheckTimer;

    // Filter related
    bool _showFilters = false; // Filter panel visibility
    TradingPointsFilterState _filters = TradingPointsFilterState(); // Filter state
    List<String> _availableTradePointTypes = []; // Available trade point types for filtering
    bool _showVisitTodayOnly = false; // Visit today filter state

    // Map provider settings
    MapProvider _defaultMapProvider = MapProvider.google; // Default map provider

    // Map rotation tracking removed - markers are naturally upright in all map providers

    // Offline caching
    MapCacheService? _mapCacheService;
    late Connectivity _connectivity;
    bool _isOnline = true;

    // PageStorage bucket for state persistence
    late final PageStorageBucket _storageBucket;

  @override
  void initState() {
    super.initState();
    _storageBucket = PageStorageBucket();
    _initializePermissions();
    _initializeLocationService();
    _initializePermissionsService();
    _initializeOfflineSupport();
    _loadUserData();
    _restoreState();
    _loadDefaultMapProvider();
  }

  /// Initialize permissions on page load
  Future<void> _initializePermissions() async {
    try {
      final permissionManager = sl<PermissionManager>();
      final status = await permissionManager.checkLocationPermission();
      if (mounted) {
        setState(() {
          _locationPermissionStatus = status;
        });
      }

      // Also check location services status
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled && mounted) {
          // Show snackbar to inform user about disabled location services
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Joylashuv xizmatlari o\'chirilgan. Masofa bo\'yicha tartiblash ishlamaydi.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking location services: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing permissions: $e');
      }
    }
  }

  /// Initialize permissions service
  Future<void> _initializePermissionsService() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      await sl.isReady<DataSyncService>();
      final dataSyncService = sl<DataSyncService>();

      _permissionsService = PermissionsService(
        dataSyncService: dataSyncService,
        prefs: prefs,
      );

      if (kDebugMode) {
        print('PermissionsService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing permissions service: $e');
      }
      // Create with default permissions if initialization fails
      _permissionsService = PermissionsService(
        dataSyncService: sl<DataSyncService>(),
        prefs: sl<SharedPreferencesService>(),
      );
    }
  }

  Future<void> _initializeLocationService() async {
    try {
      await sl.isReady<LocationService>();
      _locationService = sl<LocationService>();
      // LocationService already initialized in service locator

      // Check for user location every 30 seconds and update distances if needed
      _locationCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && _isDistanceSort) {
          _checkAndUpdateUserLocation();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
      _locationService = null; // Explicitly set to null on error
    }
  }

  /// Initialize offline support services
  Future<void> _initializeOfflineSupport() async {
    try {
      // Initialize connectivity monitoring
      _connectivity = Connectivity();
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      // Check initial connectivity status
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;

      // Initialize map cache service
      _mapCacheService = MapCacheService();
      await _mapCacheService!.initialize();

      if (kDebugMode) {
        print('Offline support initialized. Online: $_isOnline, MapCacheService initialized: ${_mapCacheService != null}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing offline support: $e');
      }
      _isOnline = true; // Default to online if initialization fails
      _mapCacheService = null; // Ensure it's null if initialization fails
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (kDebugMode) {
      print('Connectivity changed: ${wasOnline ? 'online' : 'offline'} -> ${_isOnline ? 'online' : 'offline'}');
    }

    // Notify user about connectivity changes
    if (mounted && wasOnline != _isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'Internetga ulandi' : 'Offline rejim'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
      });

      // Validate user data exists
      if (userCode.isEmpty || password.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foydalanuvchi ma\'lumotlari mavjud emas')),
          );
        }
        return;
      }

      // No additional validation needed - user data is already validated in home page

      _loadTradingPoints();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    }
  }

  /// Load default map provider from settings
  Future<void> _loadDefaultMapProvider() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final savedProvider = prefs.preferences.getString('default_map_provider');

      if (savedProvider != null) {
        setState(() {
          _defaultMapProvider = MapProvider.values.firstWhere(
            (provider) => provider.toString() == savedProvider,
            orElse: () => MapProvider.openStreetMap,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading default map provider: $e');
      }
      // Keep default value
    }
  }

  @override
  void dispose() {
    _saveState();
    _searchController.dispose();
    _locationCheckTimer?.cancel();
    _locationService?.dispose();
    if (kDebugMode) {
      print('Disposing TradingPointsPage, _permissionsService is null: ${_permissionsService == null}, _mapCacheService is null: ${_mapCacheService == null}');
    }
    _permissionsService?.dispose();
    _mapCacheService?.dispose();
    super.dispose();
  }

  /// Save current state to PageStorage
  void _saveState() {
    try {
      _storageBucket.writeState(context, _searchController.text);
      _storageBucket.writeState(context, _filters);
      _storageBucket.writeState(context, _viewMode);
      _storageBucket.writeState(context, _showFilters);
      _storageBucket.writeState(context, _showViewBar);
      _storageBucket.writeState(context, _expandedIndex);
      _storageBucket.writeState(context, _isAlphabeticalSort);
      _storageBucket.writeState(context, _isDistanceSort);
      _storageBucket.writeState(context, _showVisitTodayOnly);

      if (kDebugMode) {
        print('TradingPointsPage state saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving TradingPointsPage state: $e');
      }
    }
  }

  /// Restore state from PageStorage
  void _restoreState() {
    try {
      final savedSearch = _storageBucket.readState(context) as String?;
      final savedFilters = _storageBucket.readState(context) as TradingPointsFilterState?;
      final savedViewMode = _storageBucket.readState(context) as _ViewMode?;
      final savedShowFilters = _storageBucket.readState(context) as bool?;
      final savedShowViewBar = _storageBucket.readState(context) as bool?;
      final savedExpandedIndex = _storageBucket.readState(context) as int?;
      final savedAlphabeticalSort = _storageBucket.readState(context) as bool?;
      final savedDistanceSort = _storageBucket.readState(context) as bool?;
      final savedVisitTodayFilter = _storageBucket.readState(context) as bool?;

      if (savedSearch != null && savedSearch.isNotEmpty) {
        _searchController.text = savedSearch;
      }
      if (savedFilters != null) {
        _filters = savedFilters;
      }
      if (savedViewMode != null) {
        _viewMode = savedViewMode;
      }
      if (savedShowFilters != null) {
        _showFilters = savedShowFilters;
      }
      if (savedShowViewBar != null) {
        _showViewBar = savedShowViewBar;
      }
      if (savedExpandedIndex != null) {
        _expandedIndex = savedExpandedIndex;
      }
      if (savedAlphabeticalSort != null) {
        _isAlphabeticalSort = savedAlphabeticalSort;
      }
      if (savedDistanceSort != null) {
        _isDistanceSort = savedDistanceSort;
      }
      if (savedVisitTodayFilter != null) {
        _showVisitTodayOnly = savedVisitTodayFilter;
      }

      if (kDebugMode) {
        print('TradingPointsPage state restored successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring TradingPointsPage state: $e');
      }
    }
  }

  Future<void> _loadTradingPoints() async {
    if (userCode.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repository = sl<AgentRepository>();
      final dbService = sl<ApiDatabaseService>();

      // Load clients and business regions in parallel for better performance
      final results = await Future.wait([
        repository.getClients(userCode: userCode, password: password),
        repository.getCachedBusinessRegions(),
      ]);

      final tradingPoints = results[0] as List<TradingPoint>;
      List<BusinessRegion> regions = results[1] as List<BusinessRegion>;

      // If no cached regions, force sync from server
      if (regions.isEmpty) {
        try {
          regions = await repository.syncBusinessRegions(userCode: userCode);
        } catch (e) {
          print('Failed to sync business regions: $e');
          // Continue with empty regions - will show "Noma'lum"
        }
      }

      // Create region code to name mapping for fast lookups
      _regionNames = {for (final region in regions) region.code: region.name};

      // Get trading points with permissions and visit data using efficient JOIN query
      final tradingPointsWithPermissions = await dbService.getTradingPointsWithPermissions(userCode);

      if (kDebugMode) {
        print('Loaded ${tradingPointsWithPermissions.length} trading points with permissions');

        // Bugungi kun uchun planned routes sonini hisoblash
        final todayPlannedCount = tradingPointsWithPermissions.where((tp) => tp.visitToday).length;
        print('Bugungi kun uchun planned routes: $todayPlannedCount ta mijoz');

        if (tradingPointsWithPermissions.isNotEmpty) {
          final sample = tradingPointsWithPermissions.first;
          print('Sample trading point: ${sample.tradingPoint.name}, visitToday: ${sample.visitToday}, visitStepNumber: ${sample.visitStepNumber}');
        }
      }

      _allTradingPoints = tradingPointsWithPermissions;
      _filteredTradingPoints = List.from(_allTradingPoints);

      // Extract available trade point types for filtering
      _availableTradePointTypes = _allTradingPoints
          .map((tp) => tp.tradingPoint.tradePointType)
          .where((type) => type != null && type.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      _clearDistanceCache(); // Clear cache for fresh calculations
      _filterTradingPoints(_searchController.text); // Re-apply current filters including visit_today
      _applySorting(); // Apply initial sorting
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error loading trading points: $e');
      }
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
      if (query.isEmpty && _filters.tradePointTypes.isEmpty && _filters.businessRegions.isEmpty && !_showVisitTodayOnly) {
        _filteredTradingPoints = List.from(_allTradingPoints);
      } else {
        final qLatin = transliterateToLatin(query).toLowerCase();
        _filteredTradingPoints = _allTradingPoints.where((tp) {
          // Search filter
          final regionName = _regionNames[tp.tradingPoint.codeRegion]?.toLowerCase() ?? '';
          final searchMatch = query.isEmpty ||
              transliterateToLatin(tp.tradingPoint.name).toLowerCase().contains(qLatin) ||
              transliterateToLatin(tp.tradingPoint.address).toLowerCase().contains(qLatin) ||
              transliterateToLatin(tp.tradingPoint.contactPerson).toLowerCase().contains(qLatin) ||
              transliterateToLatin(tp.tradingPoint.ownerName).toLowerCase().contains(qLatin) ||
              transliterateToLatin(regionName).contains(qLatin) ||
              tp.tradingPoint.inn.contains(query);

          // Trade point type filter
          final typeMatch = _filters.tradePointTypes.isEmpty ||
              _filters.tradePointTypes.contains(tp.tradingPoint.tradePointType);

          // Business region filter
          final regionMatch = _filters.businessRegions.isEmpty ||
              _filters.businessRegions.contains(tp.tradingPoint.codeRegion);

          // Visit today filter
          final visitTodayMatch = !_showVisitTodayOnly || tp.visitToday;

          return searchMatch && typeMatch && regionMatch && visitTodayMatch;
        }).toList();
      }
      _clearDistanceCache(); // Clear cache when filtering changes
      _applySorting();
    });
  }

  void _onFiltersChanged(TradingPointsFilterState newFilters) {
    setState(() {
      _filters = newFilters;
      _filterTradingPoints(_searchController.text);
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _applySorting() {
    if (_isDistanceSort) {
      _sortByDistance();
    } else {
      _sortAlphabetically();
    }
  }

  void _sortAlphabetically() {
    _filteredTradingPoints.sort((a, b) {
      final aName = transliterateToLatin(a.tradingPoint.name).toLowerCase();
      final bName = transliterateToLatin(b.tradingPoint.name).toLowerCase();
      return _isAlphabeticalSort ? aName.compareTo(bName) : bName.compareTo(aName);
    });
  }

  void _sortByDistance() {
    if (_locationService == null) return;

    _filteredTradingPoints.sort((a, b) {
      final aDistance = _getCachedDistance(a);
      final bDistance = _getCachedDistance(b);

      // Handle null distances (put them at the end)
      if (aDistance == null && bDistance == null) return 0;
      if (aDistance == null) return 1;
      if (bDistance == null) return -1;

      return aDistance.compareTo(bDistance);
    });
  }

  /// Get cached distance for a trading point, calculate if not cached
  double? _getCachedDistance(TradingPointWithPermissions tp) {
    if (_locationService == null) return null; // Safety check

    final cacheKey = '${tp.tradingPoint.id}_${tp.tradingPoint.latitude}_${tp.tradingPoint.longitude}';
    if (_distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey];
    }

    final distance = _locationService!.getDistanceToTradingPoint(tp.tradingPoint.latitude, tp.tradingPoint.longitude);
    _distanceCache[cacheKey] = distance;
    return distance;
  }

  /// Check user location and update distances if location changed
  Future<void> _checkAndUpdateUserLocation() async {
    if (_locationService == null) return; // Safety check

    try {
      final userLocation = _locationService!.getStoredLocation();
      if (userLocation == null) {
        // Try to get fresh location if not available
        await _ensureUserLocationAvailable();
        return;
      }

      // Clear distance cache to force recalculation with new location
      _distanceCache.clear();

      // Update sorting if currently in distance sort mode
      if (_isDistanceSort && mounted) {
        setState(() {
          _sortByDistance();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking and updating user location: $e');
      }
    }
  }

  /// Ensure user location is available, fetch if needed
  Future<void> _ensureUserLocationAvailable() async {
    if (_locationService == null) return; // Safety check

    try {
      final userLocation = _locationService!.getStoredLocation();
      if (userLocation == null || !_locationService!.isLocationRecent()) {
        // Location is not available or not recent, try to get it
        // Note: LocationService already handles background updates every 10 seconds
        // This is just a fallback check
        if (kDebugMode) {
          print('User location not available or not recent, waiting for background update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring user location availability: $e');
      }
    }
  }

  /// Clear distance cache when data changes
  void _clearDistanceCache() {
    _distanceCache.clear();
  }

  void _toggleSorting() {
    setState(() {
      if (_isDistanceSort) {
        // Switch to alphabetical
        _isDistanceSort = false;
        _isAlphabeticalSort = !_isAlphabeticalSort; // Toggle A-Z / Z-A
      } else {
        // Switch to distance - ensure location permission first
        _ensureLocationPermissionForSorting().then((hasPermission) {
          if (hasPermission && mounted) {
            _ensureUserLocationForSorting().then((_) {
              if (mounted) {
                setState(() {
                  _isDistanceSort = true;
                  _applySorting();
                });
              }
            });
          }
        });
        return; // Don't call _applySorting here, it will be called in the callback
      }
      _applySorting();
    });
  }

  /// Ensure location permission is granted before enabling distance sorting
  Future<bool> _ensureLocationPermissionForSorting() async {
    final permissionManager = sl<PermissionManager>();
    final hasPermission = await permissionManager.showLocationPermissionDialog(context);

    // Update local permission status
    if (mounted) {
      final currentStatus = await permissionManager.checkLocationPermission();
      setState(() {
        _locationPermissionStatus = currentStatus;
      });
    }

    // If permission granted, ensure location tracking is started
    if (hasPermission && _locationService != null) {
      await _locationService!.ensureTrackingStarted();
    }
    print("has permissions: $hasPermission");
    return hasPermission;
  }

  /// Get sort button color based on permission status
  Color _getSortButtonColor(ThemeData theme) {
    if (_isDistanceSort) {
      // Distance sort active
      if (_locationPermissionStatus == AppPermissionStatus.granted) {
        return theme.colorScheme.primary;
      } else if (_locationPermissionStatus == AppPermissionStatus.denied) {
        return Colors.orange;
      } else if (_locationPermissionStatus == AppPermissionStatus.permanentlyDenied) {
        return Colors.red;
      }
    }
    return theme.colorScheme.primary;
  }

  /// Get sort button tooltip based on current state
  String _getSortButtonTooltip() {
    if (_isDistanceSort) {
      if (_locationPermissionStatus != AppPermissionStatus.granted) {
        return 'Masofaga ko\'ra tartiblash uchun joylashuv ruxsati kerak';
      }
      return 'Masofaga ko\'ra tartiblash';
    }
    return _isAlphabeticalSort ? 'Alifbo tartibida (A-Z)' : 'Alifbo tartibida (Z-A)';
  }

  /// Ensure user location is available before enabling distance sorting
  Future<void> _ensureUserLocationForSorting() async {
    if (_locationService == null) return; // Safety check

    try {
      // Ensure tracking is started
      await _locationService!.ensureTrackingStarted();

      final userLocation = _locationService!.getStoredLocation();
      if (userLocation == null || !_locationService!.isLocationRecent()) {
        // Try to get fresh location
        if (kDebugMode) {
          print('Getting fresh location for distance sorting');
        }
        // LocationService handles background updates, but we can wait a bit
        await Future.delayed(const Duration(seconds: 3)); // Increased wait time
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring location for sorting: $e');
      }
    }
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

  /// Handle visit client with distance validation
  Future<void> _handleVisitClient(BuildContext context, TradingPointWithPermissions tradingPointWithPermissions) async {
    try {
      // Check if visitToday is true
      if (!tradingPointWithPermissions.visitToday) {
        // Should not happen as button is only shown when visitToday is true, but safety check
        if (kDebugMode) {
          print('Visit client called but visitToday is false for ${tradingPointWithPermissions.tradingPoint.name}');
        }
        return;
      }

      // Get current distance in meters
      final distanceKm = _locationService?.getDistanceToTradingPoint(
        tradingPointWithPermissions.tradingPoint.latitude,
        tradingPointWithPermissions.tradingPoint.longitude,
      );

      if (distanceKm == null) {
        // No location available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joylashuv ma\'lumotlari mavjud emas. Tashrifni amalga oshirib bo\'lmaydi.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final distanceMeters = (distanceKm * 1000).round();
      final clientZoneAccess = tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;

      if (kDebugMode) {
        print('Distance check: ${distanceMeters}m vs clientZoneAccess: ${clientZoneAccess}m for ${tradingPointWithPermissions.tradingPoint.name}');
      }

      // If clientZoneAccess is 0, skip distance check and proceed directly
      if (clientZoneAccess == 0 || distanceMeters <= clientZoneAccess) {
        // Distance requirement met or no check required, proceed with visit
        await _informVisit(tradingPointWithPermissions);
      } else {
        // Distance requirement not met, show dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => DistanceValidationDialog(
              tradingPointWithPermissions: tradingPointWithPermissions,
              locationService: _locationService,
              onConditionsMet: () async {
                // Close dialog and proceed with visit
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  await _informVisit(tradingPointWithPermissions);
                }
              },
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _handleVisitClient: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _informVisit(TradingPointWithPermissions tradingPointWithPermissions) async {
    final tradingPoint = tradingPointWithPermissions.tradingPoint;

    // Navigate to visit steps page instead of showing simple dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitStepsPage(tradingPoint: tradingPointWithPermissions),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Visit completed successfully, update the trading point status
        setState(() {
          final index = _allTradingPoints.indexWhere((tp) => tp.tradingPoint.id == tradingPoint.id);
          if (index != -1) {
            final updatedTradingPoint = tradingPoint.copyWith(isVisited: true);
            _allTradingPoints[index] = TradingPointWithPermissions(
              tradingPoint: updatedTradingPoint,
              permissions: tradingPointWithPermissions.permissions,
            );
            _filterTradingPoints(_searchController.text);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tradingPoint.name} ga tashrif muvaffaqiyatli yakunlandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _createOrder(TradingPointWithPermissions tradingPointWithPermissions) {
    final tradingPoint = tradingPointWithPermissions.tradingPoint;
    _saveState(); // State saqlash
    // Orders sahifasiga mijoz parametrlar bilan o'tish
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdersPage(
          initialClientFilter: tradingPoint.id,
          initialClientName: tradingPoint.name,
        ),
      ),
    ).then((_) {
      // Qaytib kelganda state avtomatik tiklanadi
      _restoreState();
    });
  }

  void _viewContracts(TradingPointWithPermissions tradingPointWithPermissions) {
    final tradingPoint = tradingPointWithPermissions.tradingPoint;
    try {
      _saveState(); // Save current state before navigation

      if (kDebugMode) {
        print('Navigating to contracts page for client: ${tradingPoint.name} (ID: ${tradingPoint.id})');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractsPage(
            initialClientFilter: tradingPoint.id,
            initialClientName: tradingPoint.name,
          ),
        ),
      ).then((_) {
        // Restore state when returning from contracts page
        if (mounted) {
          _restoreState();
          if (kDebugMode) {
            print('Returned from contracts page, state restored');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to contracts page: $e');
      }

      // Fallback: show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shartnomalar sahifasiga o\'tishda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRefusalDialog(TradingPointWithPermissions tradingPointWithPermissions) {
    final tradingPoint = tradingPointWithPermissions.tradingPoint;
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
  void _openTpDetails(TradingPointWithPermissions tp) {
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
              tradingPoint: tp.tradingPoint,
              scrollController: scrollCtrl,
              onCall: () => _makeCall(tp.tradingPoint.phone),
              onInformVisit: () => _handleVisitClient(context, tp),
              onCreateOrder: () => _createOrder(tp),
              onViewContracts: () => _viewContracts(tp),
              onRefusal: () => _showRefusalDialog(tp),
              permissions: tp.permissions,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageStorage(
      bucket: PageStorageBucket(),
      child: Scaffold(
        // AppBar — Material 3, AgentHome uslubi
        appBar: AppBar(
          title: Text('Savdo nuqtalari', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          centerTitle: false,
          actions: [
            // Filter button
            IconButton(
              onPressed: _toggleFilters,
              icon: Icon(
                Icons.filter_alt_rounded,
                color: _showFilters
                    ? theme.colorScheme.primary
                    : null,
              ),
              tooltip: 'Filter',
            ),

            // Visit today filter button
            IconButton(
              onPressed: () {
                setState(() {
                  _showVisitTodayOnly = !_showVisitTodayOnly;
                  _filterTradingPoints(_searchController.text);
                });
              },
              icon: Icon(
                Icons.today_outlined,
                color: _showVisitTodayOnly ? theme.colorScheme.primary : null,
              ),
              tooltip: _showVisitTodayOnly ? 'Bugungi tashrif filtrini o\'chirish' : 'Faqat bugungi tashrif mijozlarini ko\'rsatish',
            ),

            // Sorting button
            IconButton(
              onPressed: _toggleSorting,
              icon: Icon(
                _isDistanceSort ? Icons.location_on : (_isAlphabeticalSort ? Icons.sort_by_alpha : Icons.sort_by_alpha_sharp),
                color: _getSortButtonColor(theme),
              ),
              tooltip: _getSortButtonTooltip(),
            ),

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

            // Filters panel
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showFilters
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TradingPointsFiltersPanel(
                  state: _filters,
                  availableTradePointTypes: _availableTradePointTypes,
                  regionNames: _regionNames,
                  onChange: _onFiltersChanged,
                ),
              )
                  : const SizedBox.shrink(),
            ),
            // List

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTradingPoints.isEmpty
                  ? const _EmptyState()
                  : (_viewMode == _ViewMode.list
                  ? NotificationListener<ScrollStartNotification>(
                    onNotification: (notification) {
                      if (_showFilters) {
                        setState(() => _showFilters = false);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: ListView.separated(
                        key: const PageStorageKey<String>('tp_list_scroll'),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: _filteredTradingPoints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tp = _filteredTradingPoints[index];
                          // LIST: eski ExpansionTile kartamiz, lekin leading – foto
                          return TradingPointCard(
                            tradingPoint: tp.tradingPoint,
                            onCall: () => _makeCall(tp.tradingPoint.phone),
                            onInformVisit: () => _handleVisitClient(context, tp),
                            onCreateOrder: () => _createOrder(tp),
                            onViewContracts: () => _viewContracts(tp),
                            onRefusal: () => _showRefusalDialog(tp),
                            onOpenDetails: () => _openTpDetails(tp),
                            regionNames: _regionNames,
                            locationService: _locationService,
                            permissions: tp.permissions,
                            mapProvider: _defaultMapProvider,
                            expanded: _expandedIndex == index,
                            onExpand: (open) {
                              setState(() {
                                _expandedIndex = open ? index : null; // faqat bittasi ochiq bo‘ladi
                              });
                            },
                          );
                        },
                      ),
                    ),
                  )
                  : NotificationListener<ScrollStartNotification>(
                    onNotification: (notification) {
                      if (_showFilters) {
                        setState(() => _showFilters = false);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: GridView.builder(
                        key: const PageStorageKey<String>('tp_grid_scroll'),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.60,
                          // mainAxisExtent: 300,
                        ),
                        itemCount: _filteredTradingPoints.length,
                        itemBuilder: (context, index) {
                          final tp = _filteredTradingPoints[index];
                          // GRID: foto yuqorida, qolgan ma’lumotlar bitta ustunda pastda
                          return _TradingPointGridTile(
                            tp: tp.tradingPoint,
                            onCall: () => _makeCall(tp.tradingPoint.phone),
                            onInformVisit: () => _handleVisitClient(context, tp),
                            onCreateOrder: () => _createOrder(tp),
                            onViewContracts: () => _viewContracts(tp),
                            onRefusal: () => _showRefusalDialog(tp),
                            onOpenDetails: () => _openTpDetails(tp),
                            locationService: _locationService,
                            permissions: tp.permissions,
                          );
                        },
                      ),
                    ),
                  )),
            )
          ],
        ),
      ),

      // Pastki menyu — mavjud nav bar (o‘zgarmagan)
      // bottomNavigationBar: const AgentBottomNavBar(
      //   initialIndex: 2,
      // ),
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
class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        // TradingPointsPage state'iga kirish uchun context orqali topish
        final state = context.findAncestorStateOfType<_TradingPointsPageState>();
        if (state != null) {
          await state._loadUserData();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.find_in_page_outlined, size: 48, color: theme.hintColor),
                const SizedBox(height: 8),
                Text(
                  'Savdo nuqtalari topilmadi',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pastga surib yangilash uchun urinib ko\'ring!',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pastga surish ish bermasa sozlamalar menyusida joylashgan "barcha ma\'lumotlarni yangilash amalini bajaring',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
  final VoidCallback onOpenDetails;
  final bool? expanded;
  final ValueChanged<bool>? onExpand;
  final Map<String, String> regionNames;
  final LocationService? locationService;
  final SalesReqPermissions? permissions;
  final MapProvider mapProvider;
  const TradingPointCard({
    super.key,
    required this.tradingPoint,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    required this.onOpenDetails,
    this.expanded,
    this.onExpand,
    required this.regionNames,
    this.locationService,
    this.permissions,
    required this.mapProvider,
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
      child: GestureDetector(
        onTap: () {
          final newExpanded = !(expanded ?? false);
          onExpand?.call(newExpanded);
        },
        onDoubleTap: onOpenDetails,
        child: ExpansionTile(

          key: PageStorageKey<String>('tp_expand_${tradingPoint.id}'), // FIXED: alohida kalit faqat ExpansionTile uchun
          initiallyExpanded: expanded ?? false,                       // NEW: tashqaridan boshqariladi
          onExpansionChanged: null,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading:  _AvatarLeading(tp: tradingPoint, visited: tradingPoint.isVisited),

      title: Row(
        children: [
          Expanded(
            child: _buildScrollableText(
              tradingPoint.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          VisitIndicators(
            visitToday: tradingPoint.visitToday,
            isVisited: tradingPoint.isVisited,
            visitStepNumber: tradingPoint.visitStepNumber,
          ),
        ],
      ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(context, Icons.place_outlined, tradingPoint.address, soft: true, maxLines: 3, scrollable: true),
              const SizedBox(height: 2),
              _line(context, Icons.badge_outlined, 'INN: ${tradingPoint.inn}', maxLines: 2),
              // Add distance display for list view
              
              if (locationService != null) ...[
                const SizedBox(height: 2),
                //Text('location servise ishladi'),
                _buildDistanceDisplayForList(context, tradingPoint, locationService!),
              ],
              if (locationService == null) ...[
                //Text('location servise ishlamadi')
              ]
            ],
          ),
        ),
        children: [
          // Kontaktlar
          Row(
            children: [
              const Icon(Icons.location_city_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Biznes region: ${regionNames[tradingPoint.codeRegion] ?? 'Noma\'lum'}')),
            ],
          ),
          const SizedBox(height: 8),
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
            spacing: 6,
            runSpacing: 6,
            children: _buildActionButtons(context, tradingPoint),
          ),
        ],
      ),
    ));
  }

  Widget _line(BuildContext context, IconData icon, String text, {bool soft = false, int maxLines = 2, bool scrollable = false}) {
    Widget textWidget;
    if (scrollable) {
      textWidget = SizedBox(
        height: maxLines * 20.0, // Approximate height for maxLines
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              text,
              softWrap: false,
            ),
          ),
        ),
      );
    } else {
      textWidget = Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      crossAxisAlignment: scrollable ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: soft ? null : Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: textWidget,
        ),
      ],
    );
  }

  Widget _buildScrollableText(String text, {TextStyle? style, int maxLines = 2}) {
    return SizedBox(
      height: maxLines * 20.0, // Approximate height for maxLines
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          text,
          style: style,
          maxLines: maxLines,
          softWrap: true, // Enable word wrapping for vertical scroll
        ),
      ),
    );
  }

  /// Build action buttons with localization and configuration
  List<Widget> _buildActionButtons(BuildContext context, TradingPoint tradingPoint) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Debug logging for permissions monitoring
    if (kDebugMode) {
      print('DEBUG: Building action buttons for ${tradingPoint.name}');
      print('DEBUG: permissions object: ${tradingPoint}');
      print('DEBUG: permissions?.visit: ${permissions?.visit}');
      print('DEBUG: permissions?.unplannedOrder: ${permissions?.unplannedOrder}');
    }

    return [
      // Visit button - only enabled if user has visit permission and meets distance requirements
      if (permissions?.visit == true && tradingPoint.visitToday == true)
        FilledButton.icon(
          onPressed: onInformVisit,
          icon: const Icon(Icons.storefront, size: 18),
          label: Text(l10n.visitClient),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: (theme.textTheme.labelLarge?.fontSize ?? 14) + 2,
            ),
          ),
        ),
      // Unplanned order button - only enabled if user has unplannedOrder permission
     if(permissions?.visit == true && permissions?.unplannedOrder == true && tradingPoint.visitToday == false)
      FilledButton.tonalIcon(
        onPressed: onCreateOrder ,
        icon: const Icon(Icons.shopping_cart, size: 18),
        label: Text(l10n.unplannedOrder),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // Contracts button - only enabled if trading point has contract
      OutlinedButton.icon(
        onPressed: tradingPoint.hasContract ? onViewContracts : null,
        icon: const Icon(Icons.description, size: 18),
        label: Text(l10n.contracts),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // Orders button
      OutlinedButton.icon(
        onPressed: onCreateOrder,
        icon: const Icon(Icons.list_alt, size: 18),
        label: Text(l10n.orders),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // Route button
      OutlinedButton.icon(
        onPressed: () {
          // Navigate to the appropriate map detail page based on selected map provider
          switch (mapProvider) {
            case MapProvider.google:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapDetailPageGoogle(tradingPoint: tradingPoint),
                ),
              );
              break;
            case MapProvider.openStreetMap:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapDetailPageOsm(tradingPoint: tradingPoint),
                ),
              );
              break;
            case MapProvider.yandex:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapDetailPageYandex(tradingPoint: tradingPoint),
                ),
              );
              break;
          }
        },
        icon: const Icon(Icons.route, size: 18),
        label: Text(l10n.route),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  Widget _buildDistanceDisplayForList(BuildContext context, TradingPoint tp, LocationService locationService) {
    print("tp.latitude: ${tp.latitude}, tp.longitude: ${tp.longitude} ${tp.name}");
    final distance = locationService.getDistanceToTradingPoint(tp.latitude, tp.longitude);
    print('Trading points distance ${distance}');
    if (distance == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Format distance as specified: "2.1km" format
    String distanceText;
    if (distance < 1.0) {
      // For distances under 1km, show in meters but format as km with decimal
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else if (distance < 10.0) {
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else {
      distanceText = '${distance.toStringAsFixed(1)}km';
    }
    print('distanceText: $distanceText');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.location_on, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          distanceText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
            fontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
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

    Color iconColor(bool active) =>
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
              color: iconColor(mode == _ViewMode.list),
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
              color: iconColor(mode == _ViewMode.grid),
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
  final SalesReqPermissions? permissions;

  const TradingPointGridCard({
    super.key,
    required this.tradingPoint,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    this.permissions,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(tradingPoint.address, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text('INN: ${tradingPoint.inn}', maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                // amallar — ixcham
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (permissions?.visit == true && tradingPoint.visitToday == true)
                    FilledButton.icon(
                          onPressed: onInformVisit,
                          icon: const Icon(Icons.storefront, size: 16),
                          label: Text(AppLocalizations.of(context)!.visitClient),
                        ),
                    if(permissions?.visit == true && permissions?.unplannedOrder == true && tradingPoint.visitToday == false)
                    FilledButton.tonalIcon(
                      onPressed: onCreateOrder,
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: Text(AppLocalizations.of(context)!.unplannedOrder),
                    ),

                    OutlinedButton.icon(
                      onPressed: onCreateOrder,
                      icon: const Icon(Icons.description, size: 16),
                      label: Text(AppLocalizations.of(context)!.orders),
                    ),
                    //if (tradingPoint.hasContract)
                      OutlinedButton.icon(
                        onPressed: tradingPoint.hasContract ? onViewContracts : null,
                        icon: const Icon(Icons.description, size: 16),
                        label: Text(AppLocalizations.of(context)!.contracts),
                      ),

                    OutlinedButton.icon(
                      onPressed: onRefusal,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: Text(AppLocalizations.of(context)!.refusal),
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
  final LocationService? locationService;
  final SalesReqPermissions? permissions;
  const _TradingPointGridTile({
    required this.tp,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    required this.onOpenDetails,
    this.locationService,
    this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _safePhotoUrl(tp);
    return Card(
      // onTap: onOpenDetails,
      // borderRadius: BorderRadius.circular(16),
      elevation: 6,                                // CHANGED: chiroyli soya
      shadowColor: Colors.black.withOpacity(.15),  // CHANGED: yumshoq soya
      surfaceTintColor: Colors.transparent,        // CHANGED: M3 tintni o'chirish
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,


        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(16),
          splashColor: cs.primary.withOpacity(.10),
          highlightColor: cs.primary.withOpacity(.10),

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
                // Add distance info on bottom-right corner of image
                if (locationService != null)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: _buildDistanceOverlay(tp, locationService!),
                  ),
                // Add visit indicators on top-right corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: VisitIndicators(
                    visitToday: tp.visitToday,
                    isVisited: tp.isVisited,
                    visitStepNumber: tp.visitStepNumber,
                  ),
                ),
              ],
            ),
          ),
          // BODY: bitta ustunda ma'lumotlar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScrollableText(tp.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 3),
                const SizedBox(height: 4),
                // _line(Icons.place_outlined, tp.address),
                // const SizedBox(height: 2),
                // _line(Icons.badge_outlined, 'INN: ${tp.inn}'),

                // NEW:
                _lineMultiline(context, Icons.place_outlined, tp.address, maxLines: 2, scrollable: true),     // CHANGED
                const SizedBox(height: 2),
                _lineMultiline(context, Icons.badge_outlined, 'INN: ${tp.inn}', maxLines: 2), // CHANGED
                // Add distance display
                // if (locationService != null) ...[
                //   const SizedBox(height: 2),
                //   _buildDistanceDisplay(context, tp, locationService!),
                // ],
              ],
            ),
          ),
          // const Spacer(),
          const SizedBox(height: 6),
          // // ACTIONS
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          //   child: Wrap(
          //     spacing: 8, runSpacing: 8,
          //     children: [
          //       if (!tp.isVisited) FilledButton.icon(onPressed: onInformVisit, icon: const Icon(Icons.location_on, size: 18), label: const Text('Tashrif')),
          //       FilledButton.tonalIcon(onPressed: onCreateOrder, icon: const Icon(Icons.shopping_cart, size: 18), label: const Text('Buyurtma')),
          //       if (tp.hasContract) OutlinedButton.icon(onPressed: onViewContracts, icon: const Icon(Icons.description, size: 18), label: const Text('Shartnoma')),
          //       OutlinedButton.icon(onPressed: onRefusal, icon: const Icon(Icons.cancel, size: 18), label: const Text('Rad etish')),
          //     ],
          //   ),
          // ),
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

  // ADD: ko‘p qatorli helper
  Widget _lineMultiline(BuildContext context, IconData icon, String text, {int maxLines = 3, bool scrollable = false}) {
    Widget textWidget;
    if (scrollable) {
      textWidget = SizedBox(
        height: maxLines * 20.0, // Approximate height
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: Text(
              text,
              softWrap: true,
            ),
          ),
        ),
      );
    } else {
      textWidget = Text(
        text,
        softWrap: true,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: textWidget,
        ),
      ],
    );
  }

  Widget _buildDistanceDisplay(BuildContext context, TradingPoint tp, LocationService locationService) {
    final distance = locationService.getDistanceToTradingPoint(tp.latitude, tp.longitude);
    if (distance == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Format distance as specified: "2.1km" format
    String distanceText;
    if (distance < 1.0) {
      // For distances under 1km, show in meters but format as km with decimal
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else if (distance < 10.0) {
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else {
      distanceText = '${distance.toStringAsFixed(1)}km';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            distanceText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              fontSize: theme.textTheme.bodySmall?.fontSize ?? 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Build distance overlay for image bottom-right corner
  Widget _buildDistanceOverlay(TradingPoint tp, LocationService locationService) {
    final distance = locationService.getDistanceToTradingPoint(tp.latitude, tp.longitude);
    if (distance == null) return const SizedBox.shrink();

    // Format distance as specified: "2.1km" format
    String distanceText;
    if (distance < 1.0) {
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else if (distance < 10.0) {
      distanceText = '${distance.toStringAsFixed(1)}km';
    } else {
      distanceText = '${distance.toStringAsFixed(1)}km';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        distanceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildScrollableText(String text, {TextStyle? style, int maxLines = 3}) {
    return SizedBox(
      height: maxLines * 20.0, // Approximate height for maxLines
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          text,
          style: style,
          maxLines: maxLines,
          softWrap: true, // Enable word wrapping for vertical scroll
        ),
      ),
    );
  }

}
// ADD: Grid detail oynasi (modal bottom-sheet)
class _TradingPointDetailsSheet extends StatefulWidget {
  final TradingPoint tradingPoint;
  final ScrollController scrollController;
  final VoidCallback onCall;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;
  final SalesReqPermissions? permissions;

  const _TradingPointDetailsSheet({
    required this.tradingPoint,
    required this.scrollController,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    this.permissions,
  });

  @override
  State<_TradingPointDetailsSheet> createState() => _TradingPointDetailsSheetState();
}

class _TradingPointDetailsSheetState extends State<_TradingPointDetailsSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _safePhotoUrl(widget.tradingPoint);

    return Material(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Indicator Line
          SizedBox(
            height: 2,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: _currentPage == 0 ? 0 : MediaQuery.of(context).size.width / 2,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width / 2,
                  child: Container(
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),

          // PageView with two pages
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                // First page: Actions and Map
                _ActionsMapPage(
                  tradingPoint: widget.tradingPoint,
                  onInformVisit: widget.onInformVisit,
                  onCreateOrder: widget.onCreateOrder,
                  onViewContracts: widget.onViewContracts,
                  onRefusal: widget.onRefusal,
                  permissions: widget.permissions,
                ),
                // Second page: Client Details
                _ClientDetailsPage(
                  tradingPoint: widget.tradingPoint,
                  onCall: widget.onCall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Client Details Page
class _ClientDetailsPage extends StatefulWidget {
  final TradingPoint tradingPoint;
  final VoidCallback onCall;

  const _ClientDetailsPage({
    required this.tradingPoint,
    required this.onCall,
  });

  @override
  State<_ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<_ClientDetailsPage> {
  bool _locationPermissionGranted = false;
  MapProvider _defaultMapProvider = MapProvider.google;


  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadDefaultMapProvider();
  }

  /// Validates and returns a valid LatLng, with fallback for invalid coordinates
  LatLng _getValidLatLng(double latitude, double longitude, String clientName) {
    // Check if coordinates are valid (not null, not zero, and within valid ranges)
    const double minLat = -90.0;
    const double maxLat = 90.0;
    const double minLng = -180.0;
    const double maxLng = 180.0;

    // Default fallback coordinates (Tashkent, Uzbekistan)
    const double defaultLat = 41.2995;
    const double defaultLng = 69.2401;

    bool isValid = latitude >= minLat && latitude <= maxLat &&
                   longitude >= minLng && longitude <= maxLng &&
                   latitude != 0.0 && longitude != 0.0;

    if (!isValid) {
      print('Warning: Invalid coordinates for $clientName: lat=$latitude, lng=$longitude. Using default location.');
      return const LatLng(defaultLat, defaultLng);
    }

    return LatLng(latitude, longitude);
  }

  Future<void> _checkLocationPermission() async {
    final permissionManager = sl<PermissionManager>();
    final status = await permissionManager.checkLocationPermission();
    setState(() {
      _locationPermissionGranted = status == AppPermissionStatus.granted;
    });
  }

  /// Load default map provider from settings
  Future<void> _loadDefaultMapProvider() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final savedProvider = prefs.preferences.getString('default_map_provider');

      if (savedProvider != null) {
        setState(() {
          _defaultMapProvider = MapProvider.values.firstWhere(
            (provider) => provider.toString() == savedProvider,
            orElse: () => MapProvider.google,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading default map provider: $e');
      }
      // Keep default value
    }
  }


  /// Build map widget based on selected provider with marker rotation support
  /// This ensures markers remain fixed at their geographic coordinates regardless of map rotation
  Widget _buildMapWidget(LatLng position, String title, String markerId) {
    // Use the default map provider from settings
    switch (_defaultMapProvider) {
      case MapProvider.google:
      // Google Maps — kalit AndroidManifest/Info.plist da.
        final camera = CameraPosition(target: position, zoom: 15);

        return Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: camera,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false, // Disable default button to use custom icons
              compassEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: MarkerId(markerId),
                  position: position,
                  infoWindow: InfoWindow(title: title),
                  // marker tagi pastdan "tiralib" tursin
                  anchor: const Offset(0.5, 1.0),
                ),
              },
              onMapCreated: (controller) {
                // Agar kerak bo'lsa controller'ni saqlab qo'yish mumkin
                // _googleController = controller;
                // (Kalit manifestda bo'lgani uchun bu yerda API init shart emas)
              },
            ),
            // Custom map control icons positioned over the map
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Fullscreen icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.black),
                      onPressed: () {
                        // Navigate to fullscreen map detail page
                        if (_defaultMapProvider == MapProvider.openStreetMap){
                          Navigator.pushNamed(
                            context,
                            '/map-detail-osm-fullscreen',
                            arguments: widget.tradingPoint,
                          );
                        }
                        if (_defaultMapProvider == MapProvider.yandex){
                          Navigator.pushNamed(
                            context,
                            '/map-detail-yandex-fullscreen',
                            arguments: widget.tradingPoint,
                            );
                        }
                        if (_defaultMapProvider == MapProvider.google){
                          Navigator.pushNamed(
                            context,
                            '/map-detail-google-fullscreen',
                            arguments: widget.tradingPoint,
                          );
                        }
                        },
                      tooltip: 'Fullscreen',
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Update coordinates icon (top-right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_location, color: Colors.orange),
                  onPressed: () {
                    // TODO: Open page to update client coordinates and send to server
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update coordinates - functionality to be implemented')),
                    );
                  },
                  tooltip: 'Update coordinates',
                  iconSize: 24,
                ),
              ),
            ),
          ],
        );

      case MapProvider.yandex:
        // Yangi MarkerManager integratsiyasi bilan
        final markers = [
          MapMarker(
            id: markerId,
            point: MapPoint(
              id: markerId,
              latitude: position.latitude,
              longitude: position.longitude,
              title: title,
            ),
            type: MarkerType.default_,
            title: title,
          ),
        ];

        return Stack(
          children: [
            YandexFullMapView(
              latitude: position.latitude,
              longitude: position.longitude,
              markers: markers, // Yangi API
              clusterConfig: const marker_manager.MarkerClusterConfig(
                enableClustering: false, // Bitta marker uchun clustering kerak emas
              ),
              // initHook: ymk_init.initMapkit(apiKey: 'YOUR_REAL_YANDEX_API_KEY'),
            ),
            // Custom map control icons positioned over the map
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Fullscreen icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.black),
                      onPressed: () {
                        // Navigate to fullscreen map detail page
                        Navigator.pushNamed(
                          context,
                          '/map-detail-yandex-fullscreen',
                          arguments: widget.tradingPoint,
                        );
                      },
                      tooltip: 'Fullscreen',
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Update coordinates icon (top-right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_location, color: Colors.orange),
                  onPressed: () {
                    // TODO: Open page to update client coordinates and send to server
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update coordinates - functionality to be implemented')),
                    );
                  },
                  tooltip: 'Update coordinates',
                  iconSize: 24,
                ),
              ),
            ),
          ],
        );

      case MapProvider.openStreetMap:
        // Implement OpenStreetMap widget with flutter_map and offline caching
        try {
          return Stack(
            children: [
              osm.FlutterMap(
                options: osm.MapOptions(
                  initialCenter: osm_latlong.LatLng(position.latitude, position.longitude),
                  initialZoom: 15.0,
                  // Enhanced rotation handling for OSM with proper tracking
                  onPositionChanged: (position, hasGesture) {
                    // No rotation tracking needed - OSM markers are naturally upright
                  },
                ),
                children: [
                  osm.TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const [],
                    userAgentPackageName: 'uz.gg.gloria_marketing',
                    maxZoom: 19,
                    minZoom: 1,
                   // attributionBuilder: (_) => const Text('© OpenStreetMap contributors'),
                    // Add error handling for missing tiles
                    errorTileCallback: (tile, error, stackTrace) {
                      if (kDebugMode) {
                        print('OSM tile error: ${tile.toString()} - $error');
                      }
                    },
                    // Add loading placeholder
                    tileBuilder: (context, tileWidget, tile) {
                      return Stack(
                        children: [
                          tileWidget,
                          // Note: Offline indicator removed for simplicity
                        ],
                      );
                    },
                  ),
                  osm.MarkerLayer(
                    rotate: true,
                    // alignment: Alignment.bottomCenter,
                    markers: [
                      osm.Marker(
                        width: 40.0,
                        height: 40.0,
                        alignment: Alignment.bottomCenter,
                        point: osm_latlong.LatLng(position.latitude, position.longitude),
                        // OSM markers should stay upright regardless of map rotation
                        // No rotation needed - flutter_map markers are automatically fixed
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  // Note: Offline indicator removed for simplicity
                ],
              ),
              // Custom map control icons positioned over the map
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.black),
                        onPressed: () {
                          // Navigate to fullscreen map detail page
                          Navigator.pushNamed(
                            context,
                            '/map-detail-osm-fullscreen',
                            arguments: widget.tradingPoint,
                          );
                        },
                        tooltip: 'Fullscreen',
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Update coordinates icon (top-right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_location, color: Colors.orange),
                    onPressed: () {
                      // TODO: Open page to update client coordinates and send to server
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Update coordinates - functionality to be implemented')),
                      );
                    },
                    tooltip: 'Update coordinates',
                    iconSize: 24,
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          // Fallback if OSM fails
          return const Center(
            child: Text('OpenStreetMap yuklanmadi. Google Maps ishlatiladi.'),
          );
        }
      default:
        // Fallback to Google Maps
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(markerId),
              position: position,
              infoWindow: InfoWindow(title: title),
            ),
          },
          onMapCreated: (controller) {
            // Map controller can be managed here if needed
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map component moved here with marker rotation support
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            child: _locationPermissionGranted
                ? _buildMapWidget(
                    _getValidLatLng(widget.tradingPoint.latitude, widget.tradingPoint.longitude, widget.tradingPoint.name),
                    widget.tradingPoint.name,
                    widget.tradingPoint.id,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Joylashuv ruxsati berilmagan', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
          ),

          Text(
            widget.tradingPoint.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Address
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.tradingPoint.address, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),

          // INN
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('INN: ${widget.tradingPoint.inn}')),
            ],
          ),
          const SizedBox(height: 6),

          // Owner Name
          if (widget.tradingPoint.ownerName.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Egasi: ${widget.tradingPoint.ownerName}')),
              ],
            ),
          const SizedBox(height: 6),

          // Contact Person
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Aloqa: ${widget.tradingPoint.contactPerson}')),
            ],
          ),
          const SizedBox(height: 6),

          // Phone
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onCall,
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  widget.tradingPoint.phone,
                  style: TextStyle(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Responsible Person
          if (widget.tradingPoint.responsiblePerson.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.account_circle_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Mas\'ul: ${widget.tradingPoint.responsiblePerson}')),
              ],
            ),
          const SizedBox(height: 6),

          // Responsible Person Phone
          if (widget.tradingPoint.responsiblePersonPhone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.phone_android_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Mas\'ul tel: ${widget.tradingPoint.responsiblePersonPhone}')),
              ],
            ),
          const SizedBox(height: 6),

          // Trade Point Type
          if (widget.tradingPoint.tradePointType.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Turi: ${widget.tradingPoint.tradePointType}')),
              ],
            ),
          const SizedBox(height: 6),

          // Region and District
          Row(
            children: [
              const Icon(Icons.location_city_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${widget.tradingPoint.region}, ${widget.tradingPoint.district}')),
            ],
          ),
          const SizedBox(height: 6),

          // Signboard
          if (widget.tradingPoint.signboard.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.signpost_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Belgi: ${widget.tradingPoint.signboard}')),
              ],
            ),
          const SizedBox(height: 6),

          // Reference Point
          if (widget.tradingPoint.referencePoint.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.gps_fixed_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Mo\'ljal: ${widget.tradingPoint.referencePoint}')),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dialog for distance validation before allowing visit client
class DistanceValidationDialog extends StatefulWidget {
  final TradingPointWithPermissions tradingPointWithPermissions;
  final LocationService? locationService;
  final VoidCallback onConditionsMet;

  const DistanceValidationDialog({
    super.key,
    required this.tradingPointWithPermissions,
    required this.locationService,
    required this.onConditionsMet,
  });

  @override
  State<DistanceValidationDialog> createState() => _DistanceValidationDialogState();
}

class _DistanceValidationDialogState extends State<DistanceValidationDialog> {
  Timer? _updateTimer;
  double? _currentDistanceKm;
  double? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _updateDistanceAndAccuracy();
    // Update every 2 seconds as required
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _updateDistanceAndAccuracy();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateDistanceAndAccuracy() {
    if (widget.locationService == null) return;

    final distance = widget.locationService!.getDistanceToTradingPoint(
      widget.tradingPointWithPermissions.tradingPoint.latitude,
      widget.tradingPointWithPermissions.tradingPoint.longitude,
    );

    final locationData = widget.locationService!.getStoredLocation();
    final accuracy = locationData?['accuracy'] as double?;

    setState(() {
      _currentDistanceKm = distance;
      _currentAccuracy = accuracy;
    });

    // Check if conditions are now met
    if (_areConditionsMet()) {
      widget.onConditionsMet();
    }
  }

  bool _areConditionsMet() {
    if (_currentDistanceKm == null) return false;
    final distanceMeters = (_currentDistanceKm! * 1000).round();
    final clientZoneAccess = widget.tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;
    return distanceMeters <= clientZoneAccess;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final clientZoneAccess = widget.tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;
    final distanceMeters = _currentDistanceKm != null ? (_currentDistanceKm! * 1000).round() : null;
    final isCompliant = distanceMeters != null && distanceMeters <= clientZoneAccess;
    // final isCompliant = distanceMeters != null && distanceMeters <= clientZoneAccess && clientZoneAccess!=0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCompliant ? Icons.check_circle : Icons.location_off,
            color: isCompliant ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Masofa tekshiruvi',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.tradingPointWithPermissions.tradingPoint.name} ga tashrif uchun masofa talabiga javob berishingiz kerak.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Distance requirement
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Talab qilingan masofa: ${clientZoneAccess}m',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current distance
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                size: 20,
                color: isCompliant ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Joriy masofa: ${distanceMeters != null ? '${distanceMeters}m' : 'Noma\'lum'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCompliant ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // GPS accuracy
          Row(
            children: [
              Icon(Icons.gps_not_fixed, size: 20, color: cs.secondary),
              const SizedBox(width: 8),
              Text(
                'GPS aniqligi: ${_currentAccuracy != null ? '${_currentAccuracy!.toStringAsFixed(1)}m' : 'Noma\'lum'}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar for distance compliance
          if (distanceMeters != null)
            DistanceComplianceProgressBar(
              currentDistance: distanceMeters,
              requiredDistance: clientZoneAccess,
              tradingPointId: widget.tradingPointWithPermissions.tradingPoint.id,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        if (isCompliant)
          FilledButton(
            onPressed: widget.onConditionsMet,
            child: const Text('Davom etish'),
          ),
      ],
    );
  }
}

/// Progress bar widget to visualize distance compliance
class DistanceComplianceProgressBar extends StatelessWidget {
  final int currentDistance;
  final int requiredDistance;
  final String tradingPointId;

  const DistanceComplianceProgressBar({
    super.key,
    required this.currentDistance,
    required this.requiredDistance,
    required this.tradingPointId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate progress (0.0 to 1.0)
    // If current > required, progress is 0 (not compliant)
    // If current <= required, progress is 1 (compliant)
    final isCompliant = currentDistance <= requiredDistance;
    final progress = isCompliant ? 1.0 : 0.0;

    // Generate color based on trading point UID
    final color = _getColorFromUid(tradingPointId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masofa mosligi',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompliant ? color : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isCompliant
              ? 'Masofa talabiga javob beradi'
              : 'Masofa talabiga javob bermaydi',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCompliant ? color : Colors.red,
          ),
        ),
      ],
    );
  }

  /// Generate color based on trading point UID hash
  Color _getColorFromUid(String uid) {
    final hash = uid.hashCode;
    final hue = (hash % 360).toDouble(); // Hue from 0-360
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }
}

// Actions and Map Page
class _ActionsMapPage extends StatefulWidget {
  final TradingPoint tradingPoint;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;
  final SalesReqPermissions? permissions;

  const _ActionsMapPage({
    required this.tradingPoint,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
    this.permissions,
  });

  @override
  State<_ActionsMapPage> createState() => _ActionsMapPageState();
}

class _ActionsMapPageState extends State<_ActionsMapPage> {
  GoogleMapController? _mapController;
  bool _locationPermissionGranted = false;


  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  /// Validates and returns a valid LatLng, with fallback for invalid coordinates
  LatLng _getValidLatLng(double latitude, double longitude, String clientName) {
    // Check if coordinates are valid (not null, not zero, and within valid ranges)
    const double minLat = -90.0;
    const double maxLat = 90.0;
    const double minLng = -180.0;
    const double maxLng = 180.0;

    // Default fallback coordinates (Tashkent, Uzbekistan)
    const double defaultLat = 41.2995;
    const double defaultLng = 69.2401;

    bool isValid = latitude >= minLat && latitude <= maxLat &&
                   longitude >= minLng && longitude <= maxLng &&
                   latitude != 0.0 && longitude != 0.0;

    if (!isValid) {
      print('Warning: Invalid coordinates for $clientName: lat=$latitude, lng=$longitude. Using default location.');
      return const LatLng(defaultLat, defaultLng);
    }

    return LatLng(latitude, longitude);
  }

  Future<void> _checkLocationPermission() async {
    final permissionManager = sl<PermissionManager>();
    final status = await permissionManager.checkLocationPermission();
    setState(() {
      _locationPermissionGranted = status == AppPermissionStatus.granted;
    });
  }
  Future<void> confirmAndCall(BuildContext context, String rawPhone) async {
    // tel: URI uchun raqamni tozalaymiz
    final phone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);

    // Tasdiqlash dialogi
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qo‘ng‘iroq qilish'),
        content: Text('Mijozga qo‘ng‘iroq qilmoqchimisiz?\n$rawPhone'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Bekor qilish')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Qo‘ng‘iroq qilish')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dialer ochilmadi')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = _safePhotoUrl(widget.tradingPoint);

    return Column(
      children: [
        // Header image before actions
        _HeaderImage(url: url, visited: widget.tradingPoint.isVisited),

        // Actions below with marker rotation support
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.permissions?.visit == true && widget.tradingPoint.visitToday == true)
              FilledButton.icon(
                  onPressed:  widget.onInformVisit,
                  icon: const Icon(Icons.storefront, size: 18),
                  label: Text(AppLocalizations.of(context)!.visitClient),
                ),
              if (widget.permissions?.visit == true && widget.permissions?.unplannedOrder == true && widget.tradingPoint.visitToday == false)
              FilledButton.icon(
                onPressed:  widget.onCreateOrder,
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: Text(AppLocalizations.of(context)!.unplannedOrder),
              ),
              OutlinedButton.icon(
                onPressed: widget.onCreateOrder,
                icon: const Icon(Icons.list_alt, size: 18),
                label: Text(AppLocalizations.of(context)!.orders),
              ),
              //if (widget.tradingPoint.hasContract)
                OutlinedButton.icon(
                  onPressed: widget.tradingPoint.hasContract?widget.onViewContracts:null,
                  icon: const Icon(Icons.description, size: 18),
                  label: Text(AppLocalizations.of(context)!.contracts),
                ),

              // TODO: Add reports, debit-credit, graph buttons
              OutlinedButton.icon(
                onPressed: () {}, // TODO: Navigate to reports
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text('Hisobotlar'),
              ),
              OutlinedButton.icon(
                onPressed: () {}, // TODO: Debit-credit
                icon: const Icon(Icons.account_balance, size: 18),
                label: const Text('Debit-Kredit'),
              ),
              OutlinedButton.icon(
                onPressed: () {}, // TODO: Graph
                icon: const Icon(Icons.show_chart, size: 18),
                label: const Text('Grafik'),
              ),
            ],
          ),
        ),
      ],
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
    final h = 250.0;
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
