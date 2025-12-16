import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_detail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/planned_route.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class DbViewPage extends StatefulWidget {
  const DbViewPage({super.key});

  @override
  State<DbViewPage> createState() => _DbViewPageState();
}

class _DbViewPageState extends State<DbViewPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiDatabaseService _dbService = sl<ApiDatabaseService>();
  final SharedPreferencesService _prefsService = sl<SharedPreferencesService>();
  final DatabaseHelper _dbHelper = sl<DatabaseHelper>();

  // Permission state variables
  bool _isCheckingPermission = false;
  bool _hasStoragePermission = false;

  // Data holders for each table
  List<KpiData> _kpiData = [];
  List<TradingPoint> _clients = [];
  List<ProductData> _products = [];
  List<PriceType> _priceTypes = [];
  List<ProductPrice> _productPrices = [];
  List<BusinessRegion> _businessRegions = [];
  List<UserWarehouse> _userWarehouses = [];
  List<ProductBalance> _productBalances = [];
  List<ProductBrand> _productBrands = [];
  List<ProductSeries> _productSeries = [];
  List<ClientContract> _clientContracts = [];
  List<MainReport> _mainReports = [];
  List<BusinessRegionReport> _businessRegionReports = [];
  List<AKBByCategory> _akbByCategories = [];
  List<Order> _orders = [];
  List<OrderStatus> _orderStatuses = [];
  List<OrderDetail> _orderDetails = [];
  List<PromotionModel> _promotions = [];
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic> _preferences = {};
  List<Map<String, dynamic>> _orderDetailProducts = [];
  List<Map<String, dynamic>> _orderPayments = [];
  List<Map<String, dynamic>> _couriers = [];
  List<Map<String, dynamic>> _courierCars = [];
  List<SalesReqPermissions> _salesReqPermissions = [];
  List<VisitStep> _visitSteps = [];
  List<VisitData> _visitStepsData = [];
  List<VisitData> _orderDraftData = [];
  List<PlannedRoute> _plannedRoutes = [];
  List<Thumbnail> _thumbnails = [];
  List<VisitPlan> _visitPlans = [];
  List<VisitPlanList> _visitPlanLists = [];

  bool _isLoading = true;
  String? _errorMessage;

  /// Safe casting helper method to handle null values from database queries
  List<T> _safeCast<T>(dynamic value) {
    if (value == null) {
      if (kDebugMode) {
        print('DEBUG: Null value received for type $T, returning empty list');
      }
      return [];
    }
    if (value is List<T>) {
      return value;
    }
    if (kDebugMode) {
      print('DEBUG: Unexpected type ${value.runtimeType} for $T, returning empty list');
    }
    return [];
  }

  /// Initialize storage permissions
  /// Check if storage permission is granted and request if needed
  Future<void> _initializePermissions() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Initializing storage permissions');
      }

      setState(() => _isCheckingPermission = true);

      // Check current permission status
      final status = await Permission.storage.status;

      if (status.isGranted) {
        _hasStoragePermission = true;
        if (kDebugMode) {
          print('DEBUG: Storage permission already granted');
        }
      } else if (status.isDenied) {
        // Request permission
        if (kDebugMode) {
          print('DEBUG: Storage permission denied, requesting...');
        }
        final result = await Permission.storage.request();
        _hasStoragePermission = result.isGranted;

        if (result.isPermanentlyDenied) {
          // Show settings dialog if permanently denied
          if (mounted) {
            await _showPermissionSettingsDialog();
          }
        }
      } else if (status.isPermanentlyDenied) {
        // Show settings dialog
        if (mounted) {
          await _showPermissionSettingsDialog();
        }
      }

      if (kDebugMode) {
        print('DEBUG: Storage permission status: $_hasStoragePermission');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error initializing permissions: $e');
      }
      _hasStoragePermission = false;
    } finally {
      if (mounted) {
        setState(() => _isCheckingPermission = false);
      }
    }
  }

  /// Show dialog to guide user to app settings for permission
  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fayl saqlash uchun ruxsat kerak'),
        content: const Text(
          'Buyurtma ma\'lumotlarini lokal papkaga saqlash uchun fayl tizimiga kirish ruxsati zarur. '
          'Iltimos, ilova sozlamalaridan fayl kirish ruxsatini bering.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keyinroq'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Sozlamalarga o\'tish'),
          ),
        ],
      ),
    );
  }

  /// Check storage permission before file operations
  /// Returns true if permission is granted, false otherwise
  Future<bool> _checkStoragePermission() async {
    if (_hasStoragePermission) {
      return true;
    }

    // Re-check permission status
    final status = await Permission.storage.status;
    if (status.isGranted) {
      _hasStoragePermission = true;
      return true;
    }

    // Request permission if denied
    if (status.isDenied) {
      final result = await Permission.storage.request();
      _hasStoragePermission = result.isGranted;
      return _hasStoragePermission;
    }

    // Show settings dialog if permanently denied
    if (status.isPermanentlyDenied) {
      await _showPermissionSettingsDialog();
      return false;
    }

    return false;
  }

  /// Save order draft data to file with permission checking
  /// Uses path_provider to get appropriate directory and checks permissions
  Future<void> _saveOrderDraftToFile() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Starting order draft save process');
      }

      // Check storage permission first
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fayl saqlash uchun ruxsat berilmadi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get appropriate directory
      Directory? directory;
      String fileName;
      String filePath;

      if (Platform.isAndroid) {
        // For Android, use Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
        fileName = 'orderdraft_${DateTime.now().millisecondsSinceEpoch}.txt';
        filePath = '${directory.path}/$fileName';
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
        fileName = 'orderdraft_${DateTime.now().millisecondsSinceEpoch}.txt';
        filePath = '${directory.path}/$fileName';
      } else {
        // For other platforms, use documents directory
        directory = await getApplicationDocumentsDirectory();
        fileName = 'orderdraft_${DateTime.now().millisecondsSinceEpoch}.txt';
        filePath = '${directory.path}/$fileName';
      }

      if (kDebugMode) {
        print('DEBUG: Saving to directory: ${directory.path}');
        print('DEBUG: File path: $filePath');
      }

      // Create JSON data
      final jsonData = jsonEncode(_orderDraftData.map((e) => e.parsedDataContent).toList());

      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      if (kDebugMode) {
        print('DEBUG: File saved successfully');
      }

      // Show success message with file info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buyurtma ma\'lumotlari saqlandi:\n$fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ochish',
              textColor: Colors.white,
              onPressed: () => _openSavedFile(filePath),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error saving order draft: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fayl saqlashda xatolik: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Open the saved file using open_file package
  Future<void> _openSavedFile(String filePath) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Opening file: $filePath');
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        if (kDebugMode) {
          print('DEBUG: Failed to open file: ${result.message}');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Faylni ochib bo\'lmadi: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error opening file: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Faylni ochishda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final List<String> _tableNames = [
    'Users',
    'Preferences',
    'KPI Data',
    'Clients',
    'Products',
    'Price Types',
    'Product Prices',
    'Business Regions',
    'User Warehouses',
    'Product Balances',
    'Product Brands',
    'Product Series',
    'Client Contracts',
    'Main Reports',
    'Business Region Reports',
    'AKB by Categories',
    'Orders',
    'Order Statuses',
    'Order Details',
    'Order Detail Products',
    'Order Payments',
    'Couriers',
    'Courier Cars',
    'Promotions',
    'Sales Req Permissions',
    'Visit Steps',
    'Visit Steps Data',
    'Order Draft Data',
    'Order Draft Products',
    'Planned Routes',
    'Thumbnails',
    'Visit Plans',
    'Visit Plan Lists',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tableNames.length, vsync: this);
    _initializePermissions();
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (kDebugMode) {
      print('DEBUG: Starting _loadAllData()');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all data concurrently with individual error handling
      final futures = [
        _safeLoadData(() => _dbHelper.getAllUsers(), 'Users'),
        _safeLoadData(() => _loadPreferencesData(), 'Preferences'),
        _safeLoadData(() => _dbService.getKpiData(''), 'KPI Data'),
        _safeLoadData(() => _dbService.getClients(), 'Clients'),
        _safeLoadData(() => _dbService.getProducts(), 'Products'),
        _safeLoadData(() => _dbService.getPriceTypes(), 'Price Types'),
        _safeLoadData(() => _dbService.getProductPrices(), 'Product Prices'),
        _safeLoadData(() => _dbService.getBusinessRegions(), 'Business Regions'),
        _safeLoadData(() => _dbService.getUserWarehouses(), 'User Warehouses'),
        _safeLoadData(() => _dbService.getProductBalances(), 'Product Balances'),
        _safeLoadData(() => _dbService.getProductBrands(), 'Product Brands'),
        _safeLoadData(() => _dbService.getProductSeries(), 'Product Series'),
        _safeLoadData(() => _dbService.getClientContracts(), 'Client Contracts'),
        _safeLoadData(() => _dbService.getMainReports(), 'Main Reports'),
        _safeLoadData(() => _dbService.getBusinessRegionReports(), 'Business Region Reports'),
        _safeLoadData(() => _dbService.getAKBByCategories(), 'AKB by Categories'),
        _safeLoadData(() => _dbService.getOrders(), 'Orders'),
        _safeLoadData(() => _dbService.getOrderStatuses(), 'Order Statuses'),
        _safeLoadData(() => _dbService.getOrderDetails(), 'Order Details'),
        _safeLoadData(() => _loadOrderDetailProducts(), 'Order Detail Products'),
        _safeLoadData(() => _loadOrderPayments(), 'Order Payments'),
        _safeLoadData(() => _loadCouriers(), 'Couriers'),
        _safeLoadData(() => _loadCourierCars(), 'Courier Cars'),
        _safeLoadData(() => _dbService.getPromotions(), 'Promotions'),
        _safeLoadData(() => _dbService.getAllSalesReqPermissions(), 'Sales Req Permissions'),
        _safeLoadData(() => _loadVisitSteps(), 'Visit Steps'),
        _safeLoadData(() => _loadVisitStepsData(), 'Visit Steps Data'),
        _safeLoadData(() => _loadOrderDraftData(), 'Order Draft Data'),
        _safeLoadData(() => _dbService.getAllPlannedRoutes(), 'Planned Routes'),
        _safeLoadData(() => _dbService.getThumbnails(), 'Thumbnails'),
        _safeLoadData(() => _dbService.getVisitPlans(), 'Visit Plans'),
        _safeLoadData(() => _dbService.getVisitPlanLists(), 'Visit Plan Lists'),
      ];

      final results = await Future.wait(futures);
      print('results prefs: ${results}');
      if (kDebugMode) {
        print('DEBUG: All data loading completed, updating state');
      }

      setState(() {
        _users = _safeCast<Map<String, dynamic>>(results[0]);
        _preferences = _safeCast<Map<String, dynamic>>(results[1]).isNotEmpty ? results[1] : {};
        _kpiData = _safeCast<KpiData>(results[2]);
        _clients = _safeCast<TradingPoint>(results[3]);
        _products = _safeCast<ProductData>(results[4]);
        _priceTypes = _safeCast<PriceType>(results[5]);
        _productPrices = _safeCast<ProductPrice>(results[6]);
        _businessRegions = _safeCast<BusinessRegion>(results[7]);
        _userWarehouses = _safeCast<UserWarehouse>(results[8]);
        _productBalances = _safeCast<ProductBalance>(results[9]);
        _productBrands = _safeCast<ProductBrand>(results[10]);
        _productSeries = _safeCast<ProductSeries>(results[11]);
        _clientContracts = _safeCast<ClientContract>(results[12]);
        _mainReports = _safeCast<MainReport>(results[13]);
        _businessRegionReports = _safeCast<BusinessRegionReport>(results[14]);
        _akbByCategories = _safeCast<AKBByCategory>(results[15]);
        _orders = _safeCast<Order>(results[16]);
        _orderStatuses = _safeCast<OrderStatus>(results[17]);
        _orderDetails = _safeCast<OrderDetail>(results[18]);
        _orderDetailProducts = _safeCast<Map<String, dynamic>>(results[19]);
        _orderPayments = _safeCast<Map<String, dynamic>>(results[20]);
        _couriers = _safeCast<Map<String, dynamic>>(results[21]);
        _courierCars = _safeCast<Map<String, dynamic>>(results[22]);
        _promotions = _safeCast<PromotionModel>(results[23]);
        _salesReqPermissions = _safeCast<SalesReqPermissions>(results[24]);
        if (kDebugMode) {
          print('DEBUG: Loaded ${_salesReqPermissions.length} SalesReqPermissions');
          if (_salesReqPermissions.isNotEmpty) {
            final sample = _salesReqPermissions.first;
            print('DEBUG: Sample SalesReqPermissions - userCode: ${sample.userCode}, clientZoneAccess: ${sample.clientZoneAccess}, locationUpdateInterval: ${sample.locationUpdateInterval}');
          }
        }
        _visitSteps = _safeCast<VisitStep>(results[25]);
        _visitStepsData = _safeCast<VisitData>(results[26]);
        _orderDraftData = _safeCast<VisitData>(results[27]);
        _plannedRoutes = _safeCast<PlannedRoute>(results[28]);
        _thumbnails = _safeCast<Thumbnail>(results[29]);
        _visitPlans = _safeCast<VisitPlan>(results[30]);
        _visitPlanLists = _safeCast<VisitPlanList>(results[31]);
        _isLoading = false;
      });

      if (kDebugMode) {
        print('DEBUG: State updated successfully');
        print('DEBUG: Data counts - KPI: ${_kpiData.length}, Clients: ${_clients.length}, Products: ${_products.length}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error in _loadAllData: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }

      setState(() {
        _errorMessage = 'Ma\'lumotlarni yuklashda xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.\nXatolik: $e';
        _isLoading = false;
      });
    }
  }

  /// Safely load data with error handling for individual database calls
  Future<dynamic> _safeLoadData(Future<dynamic> Function() dataLoader, String dataType) async {
    try {
      final result = await dataLoader();
      if (kDebugMode) {
        print('DEBUG: Successfully loaded $dataType');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading $dataType: $e');
      }
      // Return null instead of throwing to allow other data to load
      return null;
    }
  }

  /// Load preferences data from SharedPreferences
  Future<Map<String, dynamic>> _loadPreferencesData() async {
    try {
      return {
        'userCode': _prefsService.getUserCode(),
        'userName': _prefsService.getUserName(),
        'warehouseCode': _prefsService.getWarehouseCode(),
        'codeProject': _prefsService.getCodeProject(),
        'telegramID': _prefsService.getTelegramID(),
        'chatID': _prefsService.getChatID(),
        'topicID': _prefsService.getTopicID(),
        'serverName': _prefsService.getServerName(),
        'baseUrl': _prefsService.getBaseUrl(),
        'languageCode': _prefsService.getLanguageCode(),
        'isOfflineMode': _prefsService.isOfflineMode(),
        'isReportSentToTelegram': _prefsService.isReportSentToTelegram(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading preferences data: $e');
      }
      return {};
    }
  }

  /// Load order detail products from database
  Future<List<Map<String, dynamic>>> _loadOrderDetailProducts() async {
    try {
      final db = await _dbService.database;
      return await db.query('order_detail_products');
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading order detail products: $e');
      }
      return [];
    }
  }

  /// Load order payments from database
  Future<List<Map<String, dynamic>>> _loadOrderPayments() async {
    try {
      final db = await _dbService.database;
      return await db.query('order_payments');
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading order payments: $e');
      }
      return [];
    }
  }

  /// Load couriers from database
  Future<List<Map<String, dynamic>>> _loadCouriers() async {
    try {
      final db = await _dbService.database;
      return await db.query('couriers');
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading couriers: $e');
      }
      return [];
    }
  }

  /// Load courier cars from database
  Future<List<Map<String, dynamic>>> _loadCourierCars() async {
    try {
      final db = await _dbService.database;
      return await db.query('courier_cars');
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading courier cars: $e');
      }
      return [];
    }
  }

  /// Load visit steps from database
  Future<List<VisitStep>> _loadVisitSteps() async {
    try {
      final db = await _dbService.database;
      final results = await db.query('visit_steps');
      return results.map((row) => VisitStep.fromMap(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading visit steps: $e');
      }
      return [];
    }
  }

  /// Load visit steps data from database
  /// This method fetches all visit step data records from the visit_steps_data table
  /// and converts them to VisitData model objects for display in the UI.
  /// Returns an empty list if an error occurs during loading.
  Future<List<VisitData>> _loadVisitStepsData() async {
    try {
      final db = await _dbService.database;
      final results = await db.query('visit_steps_data');
      return results.map((row) => VisitData.fromMap(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading visit steps data: $e');
      }
      return [];
    }
  }

  /// Load thumbnails from database
  /// This method fetches all thumbnail records from the thumbnails table
  /// and converts them to Thumbnail model objects for display in the UI.
  /// Returns an empty list if an error occurs during loading.
  Future<List<Thumbnail>> _loadThumbnails() async {
    try {
      final thumbnails = await _dbService.getThumbnails();
      if (kDebugMode) {
        print('DEBUG: Loaded ${thumbnails.length} thumbnails');
      }
      return thumbnails;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading thumbnails: $e');
      }
      return [];
    }
  }

  /// Load visit plans from database
  /// This method fetches all visit plan records from the visit_plans table
  /// and converts them to VisitPlan model objects for display in the UI.
  /// Returns an empty list if an error occurs during loading.
  Future<List<VisitPlan>> _loadVisitPlans() async {
    try {
      final visitPlans = await _dbService.getVisitPlans();
      if (kDebugMode) {
        print('DEBUG: Loaded ${visitPlans.length} visit plans');
      }
      return visitPlans;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading visit plans: $e');
      }
      return [];
    }
  }

  /// Load visit plan lists from database
  /// This method fetches all visit plan list records from the visit_plan_lists table
  /// and converts them to VisitPlanList model objects for display in the UI.
  /// Returns an empty list if an error occurs during loading.
  Future<List<VisitPlanList>> _loadVisitPlanLists() async {
    try {
      final visitPlanLists = await _dbService.getVisitPlanLists();
      if (kDebugMode) {
        print('DEBUG: Loaded ${visitPlanLists.length} visit plan lists');
      }
      return visitPlanLists;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading visit plan lists: $e');
      }
      return [];
    }
  }

  /// Load order draft data from database
   /// This method fetches visit step data records from the visit_steps_data table
   /// where data_type is 'order_draft' and converts them to VisitData model objects
   /// for display in the UI. Returns an empty list if an error occurs during loading.
   Future<List<VisitData>> _loadOrderDraftData() async {
     try {
       final db = await _dbService.database;
       final results = await db.query(
         'visit_steps_data',
         where: 'data_type = ?',
         whereArgs: ['order_draft'],
       );
       return results.map((row) => VisitData.fromMap(row)).toList();
     } catch (e) {
       if (kDebugMode) {
         print('DEBUG: Error loading order draft data: $e');
       }
       return [];
     }
   }

   /// Extract order draft products from order draft data
   /// This method parses the JSON content of order draft VisitData objects
   /// and extracts the products array for display in a separate tab.
   /// Returns a list of maps representing the products with error handling.
   List<Map<String, dynamic>> _extractOrderDraftProducts() {
     final List<Map<String, dynamic>> products = [];

     try {
       for (final draft in _orderDraftData) {
         final parsedData = draft.parsedDataContent;
         final draftProducts = parsedData['products'] as List<dynamic>? ?? [];

         for (final product in draftProducts) {
           if (product is Map<String, dynamic>) {
             // Add draft metadata to each product for context
             final productWithContext = Map<String, dynamic>.from(product);
             productWithContext['draft_visit_id'] = draft.visitId;
             productWithContext['draft_client_code'] = draft.clientCode;
             productWithContext['draft_timestamp'] = draft.timestamp.toIso8601String();
             products.add(productWithContext);
           }
         }
       }

       if (kDebugMode) {
         print('DEBUG: Extracted ${products.length} products from ${_orderDraftData.length} order drafts');
       }
     } catch (e) {
       if (kDebugMode) {
         print('DEBUG: Error extracting order draft products: $e');
       }
     }

     return products;
   }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.databaseView),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tableNames.map((name) => Tab(text: name)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isCheckingPermission ? null : () => _saveOrderDraftToFile(),
            tooltip: 'Save Order Draft',
          ),
        ],
      ),
      body: _isLoading || _isCheckingPermission
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDataTable(_users, _getUsersColumns()),
                    _buildPreferencesTable(),
                    _buildDataTable(_kpiData, _getKpiColumns()),
                    _buildDataTable(_clients, _getClientsColumns()),
                    _buildDataTable(_products, _getProductsColumns()),
                    _buildDataTable(_priceTypes, _getPriceTypesColumns()),
                    _buildDataTable(_productPrices, _getProductPricesColumns()),
                    _buildDataTable(_businessRegions, _getBusinessRegionsColumns()),
                    _buildDataTable(_userWarehouses, _getUserWarehousesColumns()),
                    _buildDataTable(_productBalances, _getProductBalancesColumns()),
                    _buildDataTable(_productBrands, _getProductBrandsColumns()),
                    _buildDataTable(_productSeries, _getProductSeriesColumns()),
                    _buildDataTable(_clientContracts, _getClientContractsColumns()),
                    _buildDataTable(_mainReports, _getMainReportsColumns()),
                    _buildDataTable(_businessRegionReports, _getBusinessRegionReportsColumns()),
                    _buildDataTable(_akbByCategories, _getAkbByCategoriesColumns()),
                    _buildDataTable(_orders, _getOrdersColumns()),
                    _buildDataTable(_orderStatuses, _getOrderStatusesColumns()),
                    _buildDataTable(_orderDetails, _getOrderDetailsColumns()),
                    _buildDataTable(_orderDetailProducts, _getOrderDetailProductsColumns()),
                    _buildDataTable(_orderPayments, _getOrderPaymentsColumns()),
                    _buildDataTable(_couriers, _getCouriersColumns()),
                    _buildDataTable(_courierCars, _getCourierCarsColumns()),
                    _buildDataTable(_promotions, _getPromotionsColumns()),
                    _buildDataTable(_salesReqPermissions, _getSalesReqPermissionsColumns()),
                    _buildDataTable(_visitSteps, _getVisitStepsColumns()),
                    _buildDataTable(_visitStepsData, _getVisitStepsDataColumns()),
                    _buildDataTable(_orderDraftData, _getOrderDraftDataColumns()),
                    _buildDataTable(_extractOrderDraftProducts(), _getOrderDraftProductsColumns()),
                    _buildDataTable(_plannedRoutes, _getPlannedRoutesColumns()),
                    _buildDataTable(_thumbnails, _getThumbnailsColumns()),
                    _buildDataTable(_visitPlans, _getVisitPlansColumns()),
                    _buildDataTable(_visitPlanLists, _getVisitPlanListsColumns()),
                  ],
                ),
    );
  }

  Widget _buildDataTable<T>(List<T> data, List<DataColumn> columns) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: data.map((item) => _buildDataRow(item, columns)).toList(),
          columnSpacing: 16,
          horizontalMargin: 16,
          headingRowHeight: 56,
          dataRowHeight: 48,
        ),
      ),
    );
  }

  Widget _buildPreferencesTable() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: Text('Localization not available'));
    }
    final preferencesList = _preferences.entries.map((entry) => {'key': entry.key, 'value': entry.value}).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.preferenceKey)),
            DataColumn(label: Text(l10n.value)),
          ],
          rows: preferencesList.map((pref) => DataRow(cells: [
            DataCell(Text(pref['key'].toString())),
            DataCell(Text(pref['value']?.toString() ?? 'null')),
          ])).toList(),
          columnSpacing: 16,
          horizontalMargin: 16,
          headingRowHeight: 56,
          dataRowHeight: 48,
        ),
      ),
    );
  }

  DataRow _buildDataRow<T>(T item, List<DataColumn> columns) {
    final cells = <DataCell>[];

    // This is a simplified approach - in a real implementation,
    // you'd need to map each item to its corresponding cell values
    // based on the table structure

    if (item is KpiData) {
      cells.addAll([
        DataCell(Text(item.plan)),
        DataCell(Text(item.fact)),
        DataCell(Text(item.totalPercent)),
        DataCell(Text(item.totalForecast)),
        DataCell(Text(item.totalPercentForecastFact)),
        DataCell(Text(item.okb.toString())),
        DataCell(Text(item.akbPlan.toString())),
        DataCell(Text(item.akbFact.toString())),
        DataCell(Text(item.akbPercent)),
        DataCell(Text(item.updateDate)),
      ]);
    } else if (item is TradingPoint) {
      cells.addAll([
        DataCell(Text(item.id)),
        DataCell(Text(item.name)),
        DataCell(Text(item.address)),
        DataCell(Text(item.phone ?? '')),
        DataCell(Text(item.ownerName)),
        DataCell(Text(item.contactPerson)),
        DataCell(Text(item.inn ?? '')),
        DataCell(Text(item.status)),
        DataCell(Text(item.lastVisitDate)),
        DataCell(Text(item.hasOrders.toString())),
        DataCell(Text(item.hasContracts.toString())),
        DataCell(Text(item.isVisited.toString())),
        DataCell(Text(item.hasContract.toString())),
        DataCell(Text('${item.latitude}, ${item.longitude}')),
        DataCell(Text(item.region ?? '')),
        DataCell(Text(item.district ?? '')),
        DataCell(Text(item.signboard ?? '')),
        DataCell(Text(item.referencePoint ?? '')),
        DataCell(Text(item.responsiblePerson ?? '')),
        DataCell(Text(item.responsiblePersonPhone ?? '')),
        DataCell(Text(item.tradePointType ?? '')),
        DataCell(Text(item.creditLimit.toString())),
        DataCell(Text(item.accumulatedCredit.toString())),
        DataCell(Text(item.codeRegion ?? '')),
      ]);
    } else if (item is ProductData) {
      cells.addAll([
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
        DataCell(Text(item.unit ?? '')),
        DataCell(Text(item.quantity.toString())),
        DataCell(Text(item.reserved.toString())),
        DataCell(Text(item.available.toString())),
        DataCell(Text(item.category ?? '')),
        DataCell(Text(item.barcode ?? '')),
        DataCell(Text(item.have.toString())),
        DataCell(Text(item.warehouseCode)),
        DataCell(Text(item.weight.toString())),
        DataCell(Text(item.capacity.toString())),
        DataCell(Text(item.vendorCode)),
        DataCell(Text(item.productBrand)),
        DataCell(Text(item.productSeries)),
        DataCell(Text(item.codeProject)),
      ]);
    } else if (item is PriceType) {
      cells.addAll([
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
      ]);
    } else if (item is ProductPrice) {
      cells.addAll([
        DataCell(Text(item.priceTypeCode)),
        DataCell(Text(item.productCode)),
        DataCell(Text(item.price.toString())),
      ]);
    } else if (item is BusinessRegion) {
      cells.addAll([
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
      ]);
    } else if (item is UserWarehouse) {
      cells.addAll([
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
        DataCell(Text(item.organization)),
      ]);
    } else if (item is ProductBalance) {
      cells.addAll([
        DataCell(Text(item.codeSklad)),
        DataCell(Text(item.codeProduct)),
        DataCell(Text(item.nameProduct)),
        DataCell(Text(item.have.toString())),
        DataCell(Text(item.reserved.toString())),
        DataCell(Text(item.available.toString())),
        DataCell(Text(item.weight.toString())),
        DataCell(Text(item.capacity.toString())),
        DataCell(Text(item.codeProject)),
        DataCell(Text(item.vendorCode)),
        DataCell(Text(item.productBrand)),
        DataCell(Text(item.productSeries)),
      ]);
    } else if (item is ProductBrand) {
      cells.addAll([
        DataCell(Text(item.name)),
      ]);
    } else if (item is ProductSeries) {
      cells.addAll([
        DataCell(Text(item.name)),
        DataCell(Text(item.brandName)),
      ]);
    } else if (item is ClientContract) {
      cells.addAll([
        DataCell(Text(item.codeContract)),
        DataCell(Text(item.dateOfContract?.toString() ?? '')),
        DataCell(Text(item.sumOfContract.toString())),
        DataCell(Text(item.termOfContract?.toString() ?? '')),
        DataCell(Text(item.typeContract ?? '')),
        DataCell(Text(item.numbReference ?? '')),
        DataCell(Text(item.numbCertificate ?? '')),
        DataCell(Text(item.termReference?.toString() ?? '')),
        DataCell(Text(item.termCertificate?.toString() ?? '')),
        DataCell(Text(item.numbPassport ?? '')),
        DataCell(Text(item.termPassport?.toString() ?? '')),
        DataCell(Text(item.certificateUnlimited.toString())),
        DataCell(Text(item.codeDistrict ?? '')),
        DataCell(Text(item.nameDistrict ?? '')),
        DataCell(Text(item.codeProject ?? '')),
        DataCell(Text(item.codeClient)),
        DataCell(Text(item.active.toString())),
        DataCell(Text(item.status)),
      ]);
    } else if (item is MainReport) {
      cells.addAll([
        DataCell(Text(item.userCode)),
        DataCell(Text(item.dateStart.toString())),
        DataCell(Text(item.dateEnd.toString())),
        DataCell(Text(item.countAKB.toString())),
        DataCell(Text(item.countOKB.toString())),
        DataCell(Text(item.cash.toString())),
        DataCell(Text(item.transfer.toString())),
        DataCell(Text(item.sum.toString())),
        DataCell(Text(item.countVisited.toString())),
      ]);
    } else if (item is BusinessRegionReport) {
      cells.addAll([
        DataCell(Text(item.mainReportId?.toString() ?? '')),
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
        DataCell(Text(item.akb.toString())),
      ]);
    } else if (item is AKBByCategory) {
      cells.addAll([
        DataCell(Text(item.mainReportId?.toString() ?? '')),
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
        DataCell(Text(item.akb.toString())),
      ]);
    } else if (item is Order) {
      cells.addAll([
        DataCell(Text(item.numOrder)),
        DataCell(Text(item.dateOrder.toString())),
        DataCell(Text(item.captionOrder)),
        DataCell(Text(item.typePriceCode)),
        DataCell(Text(item.status.toString())),
        DataCell(Text(item.commentSupervisor ?? '')),
        DataCell(Text(item.commentForwarder ?? '')),
        DataCell(Text(item.commentAgent ?? '')),
        DataCell(Text(item.total.toString())),
        DataCell(Text(item.clientCode)),
        DataCell(Text(item.clientName)),
        DataCell(Text(item.codeOrg)),
        DataCell(Text(item.mainStatus ?? '')),
        DataCell(Text(item.courierName ?? '')),
        DataCell(Text(item.courierCar ?? '')),
      ]);
    } else if (item is OrderStatus) {
      cells.addAll([
        DataCell(Text(item.message)),
      ]);
    } else if (item is OrderDetail) {
      cells.addAll([
        DataCell(Text(item.numOrder)),
        DataCell(Text(item.credit.toString())),
        DataCell(Text(item.codePrice)),
        DataCell(Text(item.dateOrder.toString())),
        DataCell(Text(item.codeSklad)),
        DataCell(Text(item.commentSupervisor ?? '')),
        DataCell(Text(item.commentForwarder ?? '')),
        DataCell(Text(item.commentAgent ?? '')),
        DataCell(Text(item.shippingDate ?? '')),
        DataCell(Text(item.orderType.toString())),
        DataCell(Text(item.codeOrg)),
      ]);
    } else if (item is Map<String, dynamic>) {
      // Handle order_detail_products, order_payments, couriers, courier_cars tables
      // Check which table this data belongs to based on available keys
      if (item.containsKey('product_code')) {
        // Order Detail Products table
        cells.addAll([
          DataCell(Text(item['id']?.toString() ?? '')),
          DataCell(Text(item['order_detail_id']?.toString() ?? '')),
          DataCell(Text(item['product_code']?.toString() ?? '')),
          DataCell(Text(item['product_name']?.toString() ?? '')),
          DataCell(Text(item['amount']?.toString() ?? '')),
          DataCell(Text(item['price']?.toString() ?? '')),
          DataCell(Text(item['total']?.toString() ?? '')),
          DataCell(Text(item['discount_rate']?.toString() ?? '')),
          DataCell(Text(item['weight']?.toString() ?? '')),
          DataCell(Text(item['capacity']?.toString() ?? '')),
          DataCell(Text(item['created_at']?.toString() ?? '')),
          DataCell(Text(item['updated_at']?.toString() ?? '')),
        ]);
      } else if (item.containsKey('date_of_payment')) {
        // Order Payments table
        cells.addAll([
          DataCell(Text(item['id']?.toString() ?? '')),
          DataCell(Text(item['order_detail_id']?.toString() ?? '')),
          DataCell(Text(item['date_of_payment']?.toString() ?? '')),
          DataCell(Text(item['total']?.toString() ?? '')),
          DataCell(Text(item['created_at']?.toString() ?? '')),
          DataCell(Text(item['updated_at']?.toString() ?? '')),
        ]);
      } else if (item.containsKey('name') && item.containsKey('car')) {
        // Couriers table
        cells.addAll([
          DataCell(Text(item['id']?.toString() ?? '')),
          DataCell(Text(item['name']?.toString() ?? '')),
          DataCell(Text(item['car']?.toString() ?? '')),
          DataCell(Text(item['created_at']?.toString() ?? '')),
          DataCell(Text(item['updated_at']?.toString() ?? '')),
        ]);
      } else if (item.containsKey('car') && !item.containsKey('name')) {
        // Courier Cars table
        cells.addAll([
          DataCell(Text(item['id']?.toString() ?? '')),
          DataCell(Text(item['car']?.toString() ?? '')),
          DataCell(Text(item['created_at']?.toString() ?? '')),
          DataCell(Text(item['updated_at']?.toString() ?? '')),
        ]);
      } else if (item.containsKey('draft_visit_id')) {
        // Handle order draft products table (extracted from order draft JSON)
        cells.addAll([
          DataCell(Text(item['draft_visit_id']?.toString() ?? '')), // Draft Visit ID
          DataCell(Text(item['draft_client_code']?.toString() ?? '')), // Client Code
          DataCell(Text(item['codeProduct']?.toString() ?? '')), // Product Code
          DataCell(Text(item['vendorCode']?.toString() ?? '')), // Vendor Code
          DataCell(Text(item['amount']?.toString() ?? '')), // Amount
          DataCell(Text(item['price']?.toString() ?? '')), // Price
          DataCell(Text(item['total']?.toString() ?? '')), // Total
          DataCell(Text(item['weight']?.toString() ?? '')), // Weight
          DataCell(Text(item['capacity']?.toString() ?? '')), // Capacity
          DataCell(Text(item['paymentType']?.toString() ?? '')), // Payment Type
          DataCell(Text(item['discountSum']?.toString() ?? '')), // Discount Sum
          DataCell(Text(item['discountRate']?.toString() ?? '')), // Discount Rate
          DataCell(Text(item['giftAmount']?.toString() ?? '')), // Gift Amount
          DataCell(Text(item['promo']?.toString() ?? '')), // Promo
          DataCell(Text(item['draft_timestamp']?.toString() ?? '')), // Draft Timestamp
        ]);
      } else {
        // Handle users table (Map<String, dynamic>)
        cells.addAll([
          DataCell(Text(item['id']?.toString() ?? '')),
          DataCell(Text(item['code']?.toString() ?? '')),
          DataCell(Text(item['username']?.toString() ?? '')),
          DataCell(Text(item['password']?.toString() ?? '')),
          DataCell(Text(item['name']?.toString() ?? '')),
          DataCell(Text(item['role']?.toString() ?? '')),
          DataCell(Text(item['warehouse_code']?.toString() ?? '')),
          DataCell(Text(item['code_project']?.toString() ?? '')),
          DataCell(Text(item['base_url']?.toString() ?? '')),
          DataCell(Text(item['telegram_id']?.toString() ?? '')),
          DataCell(Text(item['chat_id']?.toString() ?? '')),
          DataCell(Text(item['topic_id']?.toString() ?? '')),
          DataCell(Text(item['created_at']?.toString() ?? '')),
          DataCell(Text(item['updated_at']?.toString() ?? '')),
        ]);
      }
    } else if (item is PromotionModel) {
      cells.addAll([
        DataCell(Text(item.code)),
        DataCell(Text(item.name)),
        DataCell(Text(item.type)),
        DataCell(Text(item.minPromoProductCount.toString())),
        DataCell(Text(item.bonusCount.toString())),
        DataCell(Text(item.dateStart.toString())),
        DataCell(Text(item.dateEnd.toString())),
        DataCell(Text(item.lastSynced?.toString() ?? '')),
        DataCell(Text(item.isActive.toString())),
      ]);
    } else if (item is SalesReqPermissions) {
      if (kDebugMode) {
        print('DEBUG: Building SalesReqPermissions row for user: ${item.userCode}, clientZoneAccess: ${item.clientZoneAccess}, locationUpdateInterval: ${item.locationUpdateInterval}');
      }
      cells.addAll([
        DataCell(Text(item.id?.toString() ?? '')),
        DataCell(Text(item.userCode)),
        DataCell(Text(item.skipTINduplicateCheck.toString())),
        DataCell(Text(item.allowCreationWithoutTIN.toString())),
        DataCell(Text(item.allowCreatingPointOfSale.toString())),
        DataCell(Text(item.visit.toString())),
        DataCell(Text(item.strictSequence.toString())),
        DataCell(Text(item.unplannedOrder.toString())),
        DataCell(Text(item.editClientCoordinates.toString())),
        DataCell(Text(item.plannedRoute.toString())),
        DataCell(Text(item.clientZoneAccess.toString())),
        DataCell(Text(item.locationUpdateInterval.toString())),
        DataCell(Text(item.visitSteps.length.toString())),
        DataCell(Text(item.createdAt?.toString() ?? '')),
        DataCell(Text(item.updatedAt?.toString() ?? '')),
      ]);
    } else if (item is VisitStep) {
      cells.addAll([
        DataCell(Text(item.id?.toString() ?? '')),
        DataCell(Text(item.salesReqPermissionsId?.toString() ?? '')),
        DataCell(Text(item.stepCode.toString())),
        DataCell(Text(item.stepName)),
        DataCell(Text(item.stepRequired.toString())),
        DataCell(Text(item.createdAt?.toString() ?? '')),
        DataCell(Text(item.updatedAt?.toString() ?? '')),
      ]);
    } else if (item is VisitData) {
      if (columns.length == 18) {
        // Order Draft Data table - parse JSON content for specific fields
        try {
          final parsedData = item.parsedDataContent;
          final products = parsedData['products'] as List<dynamic>? ?? [];
          final notes = parsedData['notes']?.toString() ?? '';

          cells.addAll([
            DataCell(Text(item.id?.toString() ?? '')), // Primary key
            DataCell(Text(item.visitId)), // Visit session identifier
            DataCell(Text(item.clientCode)), // Client being visited
            DataCell(Text(item.stepName)), // Step name for reference
            DataCell(Text(parsedData['selectedOrganization']?.toString() ?? '')), // Organization
            DataCell(Text(parsedData['selectedWarehouse']?.toString() ?? '')), // Warehouse
            DataCell(Text(parsedData['selectedPriceType']?.toString() ?? '')), // Price Type
            DataCell(Text(products.length.toString())), // Products Count
            DataCell(Text(parsedData['weight']?.toString() ?? '')), // Total Weight
            DataCell(Text(parsedData['capacity']?.toString() ?? '')), // Total Capacity
            DataCell(Text(notes.length > 50 ? '${notes.substring(0, 50)}...' : notes)), // Notes (truncated)
            DataCell(Text(parsedData['codeAgent']?.toString() ?? '')), // Agent Code
            DataCell(Text(parsedData['longitude']?.toString() ?? '')), // Longitude
            DataCell(Text(parsedData['latitude']?.toString() ?? '')), // Latitude
            DataCell(Text(parsedData['codeProject']?.toString() ?? '')), // Project Code
            DataCell(Text(parsedData['hasPromo']?.toString() ?? '')), // Has Promo
            DataCell(Text(item.timestamp.toString())), // Creation timestamp
            DataCell(Text(item.isSynced.toString())), // Sync status
          ]);
        } catch (e) {
          // Fallback if parsing fails
          if (kDebugMode) {
            print('DEBUG: Error parsing order draft data: $e');
          }
          cells.addAll([
            DataCell(Text(item.id?.toString() ?? '')),
            DataCell(Text(item.visitId)),
            DataCell(Text(item.clientCode)),
            DataCell(Text(item.stepName)),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(const Text('Parse Error')),
            DataCell(Text(item.timestamp.toString())),
            DataCell(Text(item.isSynced.toString())),
          ]);
        }
      } else {
        // General Visit Steps Data table
        // Truncate data_content if it's too long for display
        final truncatedContent = item.dataContent.length > 50
            ? '${item.dataContent.substring(0, 50)}...'
            : item.dataContent;

        cells.addAll([
          DataCell(Text(item.id?.toString() ?? '')), // Primary key
          DataCell(Text(item.visitId)), // Visit session identifier
          DataCell(Text(item.clientCode)), // Client being visited
          DataCell(Text(item.stepCode.toString())), // Step identifier
          DataCell(Text(item.stepName)), // Step name for reference
          DataCell(Text(item.dataType)), // Type of data (photo, form, order, audit, note)
          DataCell(Text(truncatedContent)), // JSON data content (truncated for display)
          DataCell(Text(item.timestamp.toString())), // Creation timestamp
          DataCell(Text(item.isSynced.toString())), // Sync status
          DataCell(Text(item.syncedAt?.toString() ?? '')), // Last sync timestamp
          DataCell(Text(item.syncError ?? '')), // Sync error message if any
        ]);
      }
    } else if (item is PlannedRoute) {
      cells.addAll([
        DataCell(Text(item.id.toString())),
        DataCell(Text(item.userCode)),
        DataCell(Text(item.codeWeekday.toString())),
        DataCell(Text(item.weekDay)),
        DataCell(Text(item.codeClient)),
        DataCell(Text(item.clientName)),
        DataCell(Text(item.createdAt.toString())),
        DataCell(Text(item.updatedAt.toString())),
      ]);
    } else if (item is Thumbnail) {
      cells.addAll([
        DataCell(Text(item.id?.toString() ?? '')),
        DataCell(Text(item.entityType)),
        DataCell(Text(item.entityId.toString())),
        DataCell(Text(item.code1c)),
        DataCell(Text(item.entityName)),
        DataCell(Text(item.thumbnailUrl)),
        DataCell(Text(item.thumbnailDimensions['width']?.toString() ?? '')),
        DataCell(Text(item.thumbnailDimensions['height']?.toString() ?? '')),
        DataCell(Text(item.thumbnailDimensions['format']?.toString() ?? '')),
        DataCell(Text(item.thumbnailDimensions['size']?.toString() ?? '')),
        DataCell(Text(item.originalDimensions['width']?.toString() ?? '')),
        DataCell(Text(item.originalDimensions['height']?.toString() ?? '')),
        DataCell(Text(item.originalDimensions['format']?.toString() ?? '')),
        DataCell(Text(item.originalDimensions['size']?.toString() ?? '')),
        DataCell(Text(item.isMain.toString())),
        DataCell(Text(item.category ?? '')),
        DataCell(Text(item.note ?? '')),
        DataCell(Text(item.statusCode ?? '')),
        DataCell(Text(item.statusName ?? '')),
        DataCell(Text(item.sourceName ?? '')),
        DataCell(Text(item.sourceType ?? '')),
        DataCell(Text(item.createdAt.toIso8601String())),
        DataCell(Text(item.updatedAt?.toIso8601String() ?? '')),
      ]);
    } else if (item is VisitPlan) {
      cells.addAll([
        DataCell(Text(item.id?.toString() ?? '')),
        DataCell(Text(item.mainReportId.toString())),
        DataCell(Text(item.clientCode)),
        DataCell(Text(item.clientName)),
        DataCell(Text(item.plannedDate)),
        DataCell(Text(item.actualVisitDate ?? '')),
        DataCell(Text(item.isCompleted.toString())),
        DataCell(Text(item.notes ?? '')),
        DataCell(Text(item.createdAt?.toIso8601String() ?? '')),
        DataCell(Text(item.updatedAt?.toIso8601String() ?? '')),
      ]);
    } else if (item is VisitPlanList) {
      cells.addAll([
        DataCell(Text(item.id?.toString() ?? '')),
        DataCell(Text(item.visitPlanId.toString())),
        DataCell(Text(item.productCode)),
        DataCell(Text(item.productName)),
        DataCell(Text(item.plannedQuantity.toString())),
        DataCell(Text(item.actualQuantity?.toString() ?? '')),
        DataCell(Text(item.notes ?? '')),
        DataCell(Text(item.createdAt?.toIso8601String() ?? '')),
        DataCell(Text(item.updatedAt?.toIso8601String() ?? '')),
      ]);
    }

    return DataRow(cells: cells);
  }

  List<DataColumn> _getUsersColumns() => [
        DataColumn(label: Text(AppLocalizations.of(context)?.id ?? 'ID')),
        DataColumn(label: Text(AppLocalizations.of(context)?.code ?? 'Code')),
        DataColumn(label: Text(AppLocalizations.of(context)?.username ?? 'Username')),
        DataColumn(label: Text(AppLocalizations.of(context)?.password ?? 'Password')),
        DataColumn(label: Text(AppLocalizations.of(context)?.name ?? 'Name')),
        DataColumn(label: Text(AppLocalizations.of(context)?.role ?? 'Role')),
        DataColumn(label: Text(AppLocalizations.of(context)?.warehouseCode ?? 'Warehouse Code')),
        DataColumn(label: Text(AppLocalizations.of(context)?.codeProject ?? 'Code Project')),
        DataColumn(label: Text(AppLocalizations.of(context)?.baseUrl ?? 'Base URL')),
        DataColumn(label: Text(AppLocalizations.of(context)?.telegramId ?? 'Telegram ID')),
        DataColumn(label: Text(AppLocalizations.of(context)?.chatId ?? 'Chat ID')),
        DataColumn(label: Text(AppLocalizations.of(context)?.topicId ?? 'Topic ID')),
        DataColumn(label: Text(AppLocalizations.of(context)?.createdAt ?? 'Created At')),
        DataColumn(label: Text(AppLocalizations.of(context)?.updatedAt ?? 'Updated At')),
      ];

  List<DataColumn> _getKpiColumns() => [
        DataColumn(label: Text(AppLocalizations.of(context)?.plan ?? 'Plan')),
        DataColumn(label: Text(AppLocalizations.of(context)?.fact ?? 'Fact')),
        DataColumn(label: Text(AppLocalizations.of(context)?.totalPercent ?? 'Total Percent')),
        DataColumn(label: Text(AppLocalizations.of(context)?.forecast ?? 'Forecast')),
        DataColumn(label: Text(AppLocalizations.of(context)?.forecastPercent ?? 'Forecast Percent')),
        DataColumn(label: Text(AppLocalizations.of(context)?.okb ?? 'OKB')),
        DataColumn(label: Text(AppLocalizations.of(context)?.akbPlan ?? 'AKB Plan')),
        DataColumn(label: Text(AppLocalizations.of(context)?.akbFact ?? 'AKB Fact')),
        DataColumn(label: Text(AppLocalizations.of(context)?.akbPercent ?? 'AKB Percent')),
        DataColumn(label: Text(AppLocalizations.of(context)?.updateDate ?? 'Update Date')),
      ];

  List<DataColumn> _getClientsColumns() => [
        DataColumn(label: Text(AppLocalizations.of(context)?.id ?? 'ID')),
        DataColumn(label: Text(AppLocalizations.of(context)?.name ?? 'Name')),
        DataColumn(label: Text(AppLocalizations.of(context)?.address ?? 'Address')),
        DataColumn(label: Text(AppLocalizations.of(context)?.phone ?? 'Phone')),
        DataColumn(label: Text(AppLocalizations.of(context)?.ownerName ?? 'Owner Name')),
        DataColumn(label: Text(AppLocalizations.of(context)?.contactPerson ?? 'Contact Person')),
        DataColumn(label: Text(AppLocalizations.of(context)?.inn ?? 'INN')),
        DataColumn(label: Text(AppLocalizations.of(context)?.status ?? 'Status')),
        DataColumn(label: Text(AppLocalizations.of(context)?.lastVisitDate ?? 'Last Visit Date')),
        DataColumn(label: Text(AppLocalizations.of(context)?.hasOrders ?? 'Has Orders')),
        DataColumn(label: Text(AppLocalizations.of(context)?.hasContracts ?? 'Has Contracts')),
        DataColumn(label: Text(AppLocalizations.of(context)?.isVisited ?? 'Is Visited')),
        DataColumn(label: Text(AppLocalizations.of(context)?.hasContract ?? 'Has Contract')),
        DataColumn(label: Text(AppLocalizations.of(context)?.coordinates ?? 'Coordinates')),
        DataColumn(label: Text(AppLocalizations.of(context)?.region ?? 'Region')),
        DataColumn(label: Text(AppLocalizations.of(context)?.district ?? 'District')),
        DataColumn(label: Text(AppLocalizations.of(context)?.signboard ?? 'Signboard')),
        DataColumn(label: Text(AppLocalizations.of(context)?.referencePoint ?? 'Reference Point')),
        DataColumn(label: Text(AppLocalizations.of(context)?.responsiblePerson ?? 'Responsible Person')),
        DataColumn(label: Text(AppLocalizations.of(context)?.responsiblePersonPhone ?? 'Responsible Person Phone')),
        DataColumn(label: Text(AppLocalizations.of(context)?.tradePointType ?? 'Trade Point Type')),
        DataColumn(label: Text(AppLocalizations.of(context)?.creditLimit ?? 'Credit Limit')),
        DataColumn(label: Text(AppLocalizations.of(context)?.accumulatedCredit ?? 'Accumulated Credit')),
        DataColumn(label: Text(AppLocalizations.of(context)?.codeRegion ?? 'Code Region')),
      ];

  List<DataColumn> _getProductsColumns() => [
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Unit')),
        const DataColumn(label: Text('Quantity')),
        const DataColumn(label: Text('Reserved')),
        const DataColumn(label: Text('Available')),
        const DataColumn(label: Text('Category')),
        const DataColumn(label: Text('Barcode')),
        const DataColumn(label: Text('Have')),
        const DataColumn(label: Text('Warehouse')),
        const DataColumn(label: Text('Weight')),
        const DataColumn(label: Text('Capacity')),
        const DataColumn(label: Text('Vendor Code')),
        const DataColumn(label: Text('Brand')),
        const DataColumn(label: Text('Series')),
        const DataColumn(label: Text('Project')),
      ];

  List<DataColumn> _getPriceTypesColumns() => [
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
      ];

  List<DataColumn> _getProductPricesColumns() => [
        const DataColumn(label: Text('Price Type')),
        const DataColumn(label: Text('Product Code')),
        const DataColumn(label: Text('Price')),
      ];

  List<DataColumn> _getBusinessRegionsColumns() => [
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
      ];

  List<DataColumn> _getUserWarehousesColumns() => [
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Organization')),
      ];

  List<DataColumn> _getProductBalancesColumns() => [
        const DataColumn(label: Text('Warehouse')),
        const DataColumn(label: Text('Product')),
        const DataColumn(label: Text('Product Name')),
        const DataColumn(label: Text('Have')),
        const DataColumn(label: Text('Reserved')),
        const DataColumn(label: Text('Available')),
        const DataColumn(label: Text('Weight')),
        const DataColumn(label: Text('Capacity')),
        const DataColumn(label: Text('Project')),
        const DataColumn(label: Text('Vendor Code')),
        const DataColumn(label: Text('Brand')),
        const DataColumn(label: Text('Series')),
      ];

  List<DataColumn> _getProductBrandsColumns() => [
        const DataColumn(label: Text('Name')),
      ];

  List<DataColumn> _getProductSeriesColumns() => [
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Brand')),
      ];

  List<DataColumn> _getClientContractsColumns() => [
        const DataColumn(label: Text('Contract Code')),
        const DataColumn(label: Text('Date')),
        const DataColumn(label: Text('Sum')),
        const DataColumn(label: Text('Term')),
        const DataColumn(label: Text('Type')),
        const DataColumn(label: Text('Reference')),
        const DataColumn(label: Text('Certificate')),
        const DataColumn(label: Text('Ref Term')),
        const DataColumn(label: Text('Cert Term')),
        const DataColumn(label: Text('Passport')),
        const DataColumn(label: Text('Pass Term')),
        const DataColumn(label: Text('Unlimited')),
        const DataColumn(label: Text('District Code')),
        const DataColumn(label: Text('District Name')),
        const DataColumn(label: Text('Project')),
        const DataColumn(label: Text('Client Code')),
        const DataColumn(label: Text('Active')),
        const DataColumn(label: Text('Status')),
      ];

  List<DataColumn> _getMainReportsColumns() => [
        const DataColumn(label: Text('User Code')),
        const DataColumn(label: Text('Start Date')),
        const DataColumn(label: Text('End Date')),
        const DataColumn(label: Text('AKB Count')),
        const DataColumn(label: Text('OKB Count')),
        const DataColumn(label: Text('Cash')),
        const DataColumn(label: Text('Transfer')),
        const DataColumn(label: Text('Sum')),
        const DataColumn(label: Text('Visited Count')),
      ];

  List<DataColumn> _getBusinessRegionReportsColumns() => [
        const DataColumn(label: Text('Main Report ID')),
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('AKB')),
      ];

  List<DataColumn> _getAkbByCategoriesColumns() => [
        const DataColumn(label: Text('Main Report ID')),
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('AKB')),
      ];

  List<DataColumn> _getOrdersColumns() => [
        const DataColumn(label: Text('Order Number')),
        const DataColumn(label: Text('Date')),
        const DataColumn(label: Text('Caption')),
        const DataColumn(label: Text('Price Type')),
        const DataColumn(label: Text('Status')),
        const DataColumn(label: Text('Supervisor Comment')),
        const DataColumn(label: Text('Forwarder Comment')),
        const DataColumn(label: Text('Agent Comment')),
        const DataColumn(label: Text('Total')),
        const DataColumn(label: Text('Client Code')),
        const DataColumn(label: Text('Client Name')),
        const DataColumn(label: Text('Organization')),
        const DataColumn(label: Text('Main Status')),
        const DataColumn(label: Text('Courier')),
        const DataColumn(label: Text('Courier Car')),
      ];

  List<DataColumn> _getOrderStatusesColumns() => [
        const DataColumn(label: Text('Message')),
      ];

  List<DataColumn> _getOrderDetailsColumns() => [
        const DataColumn(label: Text('Order Number')),
        const DataColumn(label: Text('Credit')),
        const DataColumn(label: Text('Price Code')),
        const DataColumn(label: Text('Order Date')),
        const DataColumn(label: Text('Warehouse')),
        const DataColumn(label: Text('Supervisor Comment')),
        const DataColumn(label: Text('Forwarder Comment')),
        const DataColumn(label: Text('Agent Comment')),
        const DataColumn(label: Text('Shipping Date')),
        const DataColumn(label: Text('Order Type')),
        const DataColumn(label: Text('Organization')),
      ];

  List<DataColumn> _getOrderDetailProductsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Order Detail ID')),
        const DataColumn(label: Text('Product Code')),
        const DataColumn(label: Text('Product Name')),
        const DataColumn(label: Text('Amount')),
        const DataColumn(label: Text('Price')),
        const DataColumn(label: Text('Total')),
        const DataColumn(label: Text('Discount Rate')),
        const DataColumn(label: Text('Weight')),
        const DataColumn(label: Text('Capacity')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getOrderPaymentsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Order Detail ID')),
        const DataColumn(label: Text('Date of Payment')),
        const DataColumn(label: Text('Total')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getCouriersColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Car')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getCourierCarsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Car')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getPromotionsColumns() => [
        const DataColumn(label: Text('Code')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Type')),
        const DataColumn(label: Text('Min Products')),
        const DataColumn(label: Text('Bonus Count')),
        const DataColumn(label: Text('Start Date')),
        const DataColumn(label: Text('End Date')),
        const DataColumn(label: Text('Last Synced')),
        const DataColumn(label: Text('Active')),
      ];

  List<DataColumn> _getSalesReqPermissionsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('User Code')),
        const DataColumn(label: Text('Skip TIN Duplicate')),
        const DataColumn(label: Text('Allow Creation Without TIN')),
        const DataColumn(label: Text('Allow Creating POS')),
        const DataColumn(label: Text('Visit')),
        const DataColumn(label: Text('Strict Sequence')),
        const DataColumn(label: Text('Unplanned Order')),
        const DataColumn(label: Text('Edit Client Coordinates')),
        const DataColumn(label: Text('Planned Route')),
        const DataColumn(label: Text('Client Zone Access')),
        const DataColumn(label: Text('Location Update Interval')),
        const DataColumn(label: Text('Visit Steps Count')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getVisitStepsColumns() => [
    const DataColumn(label: Text('ID')),
    const DataColumn(label: Text('Permissions ID')),
    const DataColumn(label: Text('Step Code')),
    const DataColumn(label: Text('Step Name')),
    const DataColumn(label: Text('Required')),
    const DataColumn(label: Text('Created At')),
    const DataColumn(label: Text('Updated At')),
  ];

  /// Define column headers for the Visit Steps Data table
  /// Displays all relevant fields from the visit_steps_data database table
  List<DataColumn> _getVisitStepsDataColumns() => [
    const DataColumn(label: Text('ID')), // Primary key
    const DataColumn(label: Text('Visit ID')), // Visit session identifier
    const DataColumn(label: Text('Client Code')), // Client being visited
    const DataColumn(label: Text('Step Code')), // Step identifier
    const DataColumn(label: Text('Step Name')), // Step name for reference
    const DataColumn(label: Text('Data Type')), // Type of data stored
    const DataColumn(label: Text('Data Content')), // JSON data content
    const DataColumn(label: Text('Timestamp')), // Creation timestamp
    const DataColumn(label: Text('Is Synced')), // Synchronization status
    const DataColumn(label: Text('Synced At')), // Last sync timestamp
    const DataColumn(label: Text('Sync Error')), // Error message if sync failed
  ];

  /// Define column headers for the Order Draft Data table
   /// Displays order draft specific fields from the visit_steps_data table where data_type = 'order_draft'
   List<DataColumn> _getOrderDraftDataColumns() => [
     const DataColumn(label: Text('ID')), // Primary key
     const DataColumn(label: Text('Visit ID')), // Visit session identifier
     const DataColumn(label: Text('Client Code')), // Client being visited
     const DataColumn(label: Text('Step Name')), // Step name for reference
     const DataColumn(label: Text('Organization')), // Selected organization display name
     const DataColumn(label: Text('Warehouse')), // Selected warehouse display name
     const DataColumn(label: Text('Price Type')), // Selected price type display name
     const DataColumn(label: Text('Products Count')), // Number of products in the order
     const DataColumn(label: Text('Total Weight')), // Calculated total weight
     const DataColumn(label: Text('Total Capacity')), // Calculated total capacity
     const DataColumn(label: Text('Notes')), // Additional notes
     const DataColumn(label: Text('Agent Code')), // Agent who created the draft
     const DataColumn(label: Text('Longitude')), // GPS longitude coordinate
     const DataColumn(label: Text('Latitude')), // GPS latitude coordinate
     const DataColumn(label: Text('Project Code')), // Project code
     const DataColumn(label: Text('Has Promo')), // Whether order has promotional items
     const DataColumn(label: Text('Timestamp')), // Creation timestamp
     const DataColumn(label: Text('Is Synced')), // Synchronization status
   ];

   /// Define column headers for the Order Draft Products table
   /// Displays product details extracted from order draft JSON data
   List<DataColumn> _getOrderDraftProductsColumns() => [
     const DataColumn(label: Text('Draft Visit ID')), // Visit ID from parent draft
     const DataColumn(label: Text('Client Code')), // Client code from parent draft
     const DataColumn(label: Text('Product Code')), // Product code
     const DataColumn(label: Text('Vendor Code')), // Vendor/supplier code
     const DataColumn(label: Text('Amount')), // Quantity
     const DataColumn(label: Text('Price')), // Unit price
     const DataColumn(label: Text('Total')), // Total price (price × amount)
     const DataColumn(label: Text('Weight')), // Product weight
     const DataColumn(label: Text('Capacity')), // Product capacity/volume
     const DataColumn(label: Text('Payment Type')), // Payment type code
     const DataColumn(label: Text('Discount Sum')), // Fixed discount amount
     const DataColumn(label: Text('Discount Rate')), // Discount percentage
     const DataColumn(label: Text('Gift Amount')), // Number of gift items
     const DataColumn(label: Text('Promo')), // Whether product is promotional
     const DataColumn(label: Text('Draft Timestamp')), // When the draft was created
   ];

  List<DataColumn> _getPlannedRoutesColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('User Code')),
        const DataColumn(label: Text('Weekday Code')),
        const DataColumn(label: Text('Weekday')),
        const DataColumn(label: Text('Client Code')),
        const DataColumn(label: Text('Client Name')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getThumbnailsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Entity Type')),
        const DataColumn(label: Text('Entity ID')),
        const DataColumn(label: Text('Code 1C')),
        const DataColumn(label: Text('Entity Name')),
        const DataColumn(label: Text('Thumbnail URL')),
        const DataColumn(label: Text('Thumbnail Width')),
        const DataColumn(label: Text('Thumbnail Height')),
        const DataColumn(label: Text('Thumbnail Format')),
        const DataColumn(label: Text('Thumbnail Size')),
        const DataColumn(label: Text('Original Width')),
        const DataColumn(label: Text('Original Height')),
        const DataColumn(label: Text('Original Format')),
        const DataColumn(label: Text('Original Size')),
        const DataColumn(label: Text('Is Main')),
        const DataColumn(label: Text('Category')),
        const DataColumn(label: Text('Note')),
        const DataColumn(label: Text('Status Code')),
        const DataColumn(label: Text('Status Name')),
        const DataColumn(label: Text('Source Name')),
        const DataColumn(label: Text('Source Type')),
        const DataColumn(label: Text('Created At Server')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getVisitPlansColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Main Report ID')),
        const DataColumn(label: Text('Client Code')),
        const DataColumn(label: Text('Client Name')),
        const DataColumn(label: Text('Planned Date')),
        const DataColumn(label: Text('Actual Visit Date')),
        const DataColumn(label: Text('Is Completed')),
        const DataColumn(label: Text('Notes')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];

  List<DataColumn> _getVisitPlanListsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Visit Plan ID')),
        const DataColumn(label: Text('Product Code')),
        const DataColumn(label: Text('Product Name')),
        const DataColumn(label: Text('Planned Quantity')),
        const DataColumn(label: Text('Actual Quantity')),
        const DataColumn(label: Text('Notes')),
        const DataColumn(label: Text('Created At')),
        const DataColumn(label: Text('Updated At')),
      ];
}