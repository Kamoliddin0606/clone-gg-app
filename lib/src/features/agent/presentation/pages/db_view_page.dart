import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
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
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';

class DbViewPage extends StatefulWidget {
  const DbViewPage({super.key});

  @override
  State<DbViewPage> createState() => _DbViewPageState();
}

class _DbViewPageState extends State<DbViewPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiDatabaseService _dbService = sl<ApiDatabaseService>();

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

  final List<String> _tableNames = [
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
    'Promotions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tableNames.length, vsync: this);
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
        _safeLoadData(() => _dbService.getPromotions(), 'Promotions'),
      ];

      final results = await Future.wait(futures);

      if (kDebugMode) {
        print('DEBUG: All data loading completed, updating state');
      }

      setState(() {
        _kpiData = _safeCast<KpiData>(results[0]);
        _clients = _safeCast<TradingPoint>(results[1]);
        _products = _safeCast<ProductData>(results[2]);
        _priceTypes = _safeCast<PriceType>(results[3]);
        _productPrices = _safeCast<ProductPrice>(results[4]);
        _businessRegions = _safeCast<BusinessRegion>(results[5]);
        _userWarehouses = _safeCast<UserWarehouse>(results[6]);
        _productBalances = _safeCast<ProductBalance>(results[7]);
        _productBrands = _safeCast<ProductBrand>(results[8]);
        _productSeries = _safeCast<ProductSeries>(results[9]);
        _clientContracts = _safeCast<ClientContract>(results[10]);
        _mainReports = _safeCast<MainReport>(results[11]);
        _businessRegionReports = _safeCast<BusinessRegionReport>(results[12]);
        _akbByCategories = _safeCast<AKBByCategory>(results[13]);
        _orders = _safeCast<Order>(results[14]);
        _orderStatuses = _safeCast<OrderStatus>(results[15]);
        _orderDetails = _safeCast<OrderDetail>(results[16]);
        _promotions = _safeCast<PromotionModel>(results[17]);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database View'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tableNames.map((name) => Tab(text: name)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Yangilash',
          ),
        ],
      ),
      body: _isLoading
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
                    _buildDataTable(_promotions, _getPromotionsColumns()),
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
    }

    return DataRow(cells: cells);
  }

  List<DataColumn> _getKpiColumns() => [
        const DataColumn(label: Text('Plan')),
        const DataColumn(label: Text('Fact')),
        const DataColumn(label: Text('Total %')),
        const DataColumn(label: Text('Forecast')),
        const DataColumn(label: Text('Forecast %')),
        const DataColumn(label: Text('OKB')),
        const DataColumn(label: Text('AKB Plan')),
        const DataColumn(label: Text('AKB Fact')),
        const DataColumn(label: Text('AKB %')),
        const DataColumn(label: Text('Update Date')),
      ];

  List<DataColumn> _getClientsColumns() => [
        const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Name')),
        const DataColumn(label: Text('Address')),
        const DataColumn(label: Text('Phone')),
        const DataColumn(label: Text('Owner')),
        const DataColumn(label: Text('Contact')),
        const DataColumn(label: Text('INN')),
        const DataColumn(label: Text('Status')),
        const DataColumn(label: Text('Last Visit')),
        const DataColumn(label: Text('Has Orders')),
        const DataColumn(label: Text('Has Contracts')),
        const DataColumn(label: Text('Is Visited')),
        const DataColumn(label: Text('Has Contract')),
        const DataColumn(label: Text('Coordinates')),
        const DataColumn(label: Text('Region')),
        const DataColumn(label: Text('District')),
        const DataColumn(label: Text('Signboard')),
        const DataColumn(label: Text('Reference Point')),
        const DataColumn(label: Text('Responsible')),
        const DataColumn(label: Text('Resp. Phone')),
        const DataColumn(label: Text('Trade Type')),
        const DataColumn(label: Text('Credit Limit')),
        const DataColumn(label: Text('Accumulated Credit')),
        const DataColumn(label: Text('Code Region')),
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
}