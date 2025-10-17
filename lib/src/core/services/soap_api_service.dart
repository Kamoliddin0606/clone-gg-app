import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
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
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';

class SoapApiService {
  final Dio _dio;
  final ServerService _serverService;

  SoapApiService(this._dio, this._serverService) {
    _configureDio();
  }

  String get _baseUrl => _serverService.baseUrl;
  
  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add common headers
          options.headers.addAll({
            'Accept': 'application/soap+xml, text/xml, application/xml',
            'Cache-Control': 'no-cache',
          });
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Retry logic for network errors
          if (_shouldRetry(error)) {
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } catch (e) {
              // If retry fails, continue with original error
            }
          }

          // Enhanced error handling
          final errorMessage = _getErrorMessage(error);
          final enhancedError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
          );

          return handler.next(enhancedError);
        },
      ),
    ]);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           (error.type == DioExceptionType.badResponse &&
            error.response?.statusCode == 500);
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please check your credentials.';
        } else if (statusCode == 403) {
          return 'Access forbidden. You do not have permission.';
        } else if (statusCode == 404) {
          return 'Service not found. Please contact support.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Server error (${statusCode}). Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return 'Network error. Please check your internet connection.';
        }
        return 'Unknown error occurred. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get KPI data for agent
  Future<KpiData> getKpiData({
    required String userCode,
    required String password,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetKPI>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:GetKPI>
   </soap:Body>
</soap:Envelope>
''';

    try {
      print("user: $userCode");
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );
      print('KPI data response: ${response.data}');
      final document = XmlDocument.parse(response.data);

      final returnElement = document.findAllElements('m:return').first;
      print('KPI data response: $returnElement');
     
      return KpiData(
        plan: returnElement.findElements('m:TotalPlan').first.innerText,
        fact: returnElement.findElements('m:TotalFact').first.innerText,
        totalPercent: returnElement.findElements('m:TotalPercent').first.innerText,
        totalForecast: returnElement.findElements('m:TotalForecast').first.innerText,
        totalPercentForecastFact: returnElement.findElements('m:TotalPercentForecastFact').first.innerText,
        okb: returnElement.findElements('m:OKB').first.innerText,
        akbPlan: returnElement.findElements('m:AKBPlan').first.innerText,
        akbFact: returnElement.findElements('m:AKBFact').first.innerText,
        akbPercent: returnElement.findElements('m:AKBPercent').first.innerText,
        updateDate: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('KPI ma\'lumotlarini olishda xatolik: $e');
    }
  }

  /// Get clients list for agent
  Future<List<TradingPoint>> getClients({
    required String userCode,
    required String password,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetClients>
         <sam:UserCode>$userCode</sam:UserCode>
      </sam:GetClients>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements.map((row) => TradingPoint(
        id: _getElementText(row, 'm:Code') ?? '',
        name: _getElementText(row, 'm:Name') ?? '',
        address: _getElementText(row, 'm:AdressDelivery') ?? '',
        phone: _getElementText(row, 'm:ContactPersonPhone') ?? '',
        ownerName: _getElementText(row, 'm:ContactPerson') ?? '',
        contactPerson: _getElementText(row, 'm:ContactPerson') ?? '',
        inn: _getElementText(row, 'm:INN') ?? '',
        status: 'active',
        lastVisitDate: '',
        hasOrders: int.tryParse(_getElementText(row, 'm:TheNumberOfOrders') ?? '0') != 0,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: double.tryParse(_getElementText(row, 'm:Latitude') ?? '0') ?? 0.0,
        longitude: double.tryParse(_getElementText(row, 'm:Longitude') ?? '0') ?? 0.0,
        region: '',
        district: '',
        signboard: _getElementText(row, 'm:Signboard') ?? '',
        referencePoint: _getElementText(row, 'm:ReferencePoint') ?? '',
        responsiblePerson: _getElementText(row, 'm:ResponsiblePerson') ?? '',
        responsiblePersonPhone: _getElementText(row, 'm:ResponsiblePersonPhone') ?? '',
        tradePointType: _getElementText(row, 'm:TradePointType') ?? '',
        creditLimit: double.tryParse(_getElementText(row, 'm:CreditLimit') ?? '0') ?? 0.0,
        accumulatedCredit: double.tryParse(_getElementText(row, 'm:AccumulatedCredit') ?? '0') ?? 0.0,
        codeRegion: _getElementText(row, 'm:CodeRegion') ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Mijozlar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get business regions list
  Future<List<BusinessRegion>> getBusinessRegions({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetBusinessRegions>
         <sam:UserCode>$userCode</sam:UserCode>
      </sam:GetBusinessRegions>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements.map((row) => BusinessRegion(
        code: _getElementText(row, 'm:Code') ?? '',
        name: _getElementText(row, 'm:Name') ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Biznes rayonlari ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get user warehouses list
  Future<List<UserWarehouse>> getWarehousesUser({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetWarehousesUser>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:GetWarehousesUser>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final warehouseElements = document.findAllElements('m:Warehouse');

      return warehouseElements.map((warehouse) => UserWarehouse(
        code: _getElementText(warehouse, 'm:Code') ?? '',
        name: _getElementText(warehouse, 'm:Name') ?? '',
        organization: _getElementText(warehouse, 'm:Organization') ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Foydalanuvchi omborlarini olishda xatolik: $e');
    }
  }

  /// Create new business region
  Future<String> createBusinessRegion({
    required String userCode,
    required String code,
    required String name,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:CreateBusinessRegion>
         <sam:UserCode>$userCode</sam:UserCode>
         <sam:Code>$code</sam:Code>
         <sam:Name>$name</sam:Name>
      </sam:CreateBusinessRegion>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final resultElement = document.findAllElements('m:result').firstOrNull;
      return resultElement?.innerText ?? 'Success';
    } catch (e) {
      throw Exception('Biznes rayoni yaratishda xatolik: $e');
    }
  }

  /// Update business region
  Future<String> updateBusinessRegion({
    required String userCode,
    required String code,
    required String name,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:UpdateBusinessRegion>
         <sam:UserCode>$userCode</sam:UserCode>
         <sam:Code>$code</sam:Code>
         <sam:Name>$name</sam:Name>
      </sam:UpdateBusinessRegion>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final resultElement = document.findAllElements('m:result').firstOrNull;
      return resultElement?.innerText ?? 'Success';
    } catch (e) {
      throw Exception('Biznes rayoni yangilashda xatolik: $e');
    }
  }

  /// Delete business region by code
  Future<String> deleteBusinessRegion({
    required String userCode,
    required String code,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:DeleteBusinessRegion>
         <sam:UserCode>$userCode</sam:UserCode>
         <sam:Code>$code</sam:Code>
      </sam:DeleteBusinessRegion>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final resultElement = document.findAllElements('m:result').firstOrNull;
      return resultElement?.innerText ?? 'Success';
    } catch (e) {
      throw Exception('Biznes rayoni o\'chirishda xatolik: $e');
    }
  }

  /// Delete all business regions
  Future<String> deleteAllBusinessRegions({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:DeleteAllBusinessRegions>
         <sam:UserCode>$userCode</sam:UserCode>
      </sam:DeleteAllBusinessRegions>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final resultElement = document.findAllElements('m:result').firstOrNull;
      return resultElement?.innerText ?? 'Success';
    } catch (e) {
      throw Exception('Barcha biznes rayonlarini o\'chirishda xatolik: $e');
    }
  }

  /// Get products list from warehouse
  Future<List<ProductData>> getProducts({
    required String codeProject,
    required String codeSklad,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetProductBalance>
         <sam:CodeProject>$codeProject</sam:CodeProject>
         <sam:CodeSklad>$codeSklad</sam:CodeSklad>
      </sam:GetProductBalance>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);

      // Handle nested structure: ProductBrand -> ProductSeries -> Products
      final products = <ProductData>[];
      final brandElements = document.findAllElements('m:ProductBrand');

      for (final brandElement in brandElements) {
        final brandName = brandElement.innerText;

        // Find all rows under this brand
        final brandParent = brandElement.parent;
        if (brandParent != null) {
          final seriesElements = brandParent.findAllElements('m:ProductSeries');

          for (final seriesElement in seriesElements) {
            final seriesName = seriesElement.innerText;

            // Find all product rows under this series
            final seriesParent = seriesElement.parent;
            if (seriesParent != null) {
              final productRows = seriesParent.findAllElements('m:Rows');

              for (final row in productRows) {
                // Only process rows that have product data
                if (_getElementText(row, 'm:CodeProduct') != null) {
                  products.add(ProductData(
                    code: _getElementText(row, 'm:CodeProduct') ?? '',
                    name: _getElementText(row, 'm:NameProduct') ?? '',
                    unit: '',
                    quantity: 0.0,
                    reserved: double.tryParse(_getElementText(row, 'm:Reserved') ?? '0') ?? 0.0,
                    available: double.tryParse(_getElementText(row, 'm:Aviable') ?? '0') ?? 0.0,
                    category: '',
                    barcode: '',
                    have: int.tryParse(_getElementText(row, 'm:Have') ?? '0') ?? 0,
                    warehouseCode: _getElementText(row, 'm:CodeSklad') ?? '',
                    weight: double.tryParse(_getElementText(row, 'm:Weight') ?? '0') ?? 0.0,
                    capacity: double.tryParse(_getElementText(row, 'm:Capacity') ?? '0') ?? 0.0,
                    vendorCode: _getElementText(row, 'm:VendorCode') ?? '',
                    productBrand: brandName,
                    productSeries: seriesName,
                    codeProject: _getElementText(row, 'm:CodeProject') ?? '',
                  ));
                }
              }
            }
          }
        }
      }

      return products;
    } catch (e) {
      throw Exception('Mahsulotlar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get product balances with brands and series
  Future<Map<String, dynamic>> getProductBalances({
    required String codeProject,
    required String codeSklad,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetProductBalance>
         <sam:CodeProject>$codeProject</sam:CodeProject>
         <sam:CodeSklad>$codeSklad</sam:CodeSklad>
      </sam:GetProductBalance>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);

      final balances = <ProductBalance>[];
      final brands = <ProductBrand>[];
      final series = <ProductSeries>[];

      // Handle nested structure: ProductBrand -> ProductSeries -> Products
      final brandElements = document.findAllElements('m:ProductBrand');

      for (final brandElement in brandElements) {
        final brandName = brandElement.innerText;
        brands.add(ProductBrand(name: brandName));

        // Find all rows under this brand
        final brandParent = brandElement.parent;
        if (brandParent != null) {
          final seriesElements = brandParent.findAllElements('m:ProductSeries');

          for (final seriesElement in seriesElements) {
            final seriesName = seriesElement.innerText;
            series.add(ProductSeries(name: seriesName, brandName: brandName));

            // Find all product rows under this series
            final seriesParent = seriesElement.parent;
            if (seriesParent != null) {
              final productRows = seriesParent.findAllElements('m:Rows');

              for (final row in productRows) {
                // Only process rows that have product data
                if (_getElementText(row, 'm:CodeProduct') != null) {
                  balances.add(ProductBalance(
                    codeSklad: _getElementText(row, 'm:CodeSklad') ?? '',
                    codeProduct: _getElementText(row, 'm:CodeProduct') ?? '',
                    nameProduct: _getElementText(row, 'm:NameProduct') ?? '',
                    have: int.tryParse(_getElementText(row, 'm:Have') ?? '0') ?? 0,
                    reserved: int.tryParse(_getElementText(row, 'm:Reserved') ?? '0') ?? 0,
                    available: int.tryParse(_getElementText(row, 'm:Aviable') ?? '0') ?? 0,
                    weight: double.tryParse(_getElementText(row, 'm:Weight') ?? '0') ?? 0.0,
                    capacity: double.tryParse(_getElementText(row, 'm:Capacity') ?? '0') ?? 0.0,
                    codeProject: _getElementText(row, 'm:CodeProject') ?? '',
                    vendorCode: _getElementText(row, 'm:VendorCode') ?? '',
                    productBrand: brandName,
                    productSeries: seriesName,
                  ));
                }
              }
            }
          }
        }
      }

      return {
        'balances': balances,
        'brands': brands,
        'series': series,
      };
    } catch (e) {
      throw Exception('Mahsulot balanslarini olishda xatolik: $e');
    }
  }

  /// Get price types
  Future<List<PriceType>> getPriceTypes({
    required String userCode,
  }) async {
    if (userCode.isEmpty) {
      throw ArgumentError('UserCode cannot be empty');
    }

    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetPriceTypes>
         <sam:UserCode>$userCode</sam:UserCode>
      </sam:GetPriceTypes>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      if (response.data == null || response.data.toString().isEmpty) {
        throw Exception('Empty response from server');
      }

      final document = XmlDocument.parse(response.data);
      final priceTypeElements = document.findAllElements('m:PriceType');

      if (priceTypeElements.isEmpty) {
        if (kDebugMode) {
          print('No price types found in response');
        }
        return [];
      }

      final priceTypes = <PriceType>[];
      for (final priceTypeElement in priceTypeElements) {
        try {
          final priceType = PriceType(
            code: _getElementText(priceTypeElement, 'm:Code') ?? '',
            name: _getElementText(priceTypeElement, 'm:Name') ?? '',
          );
          priceTypes.add(priceType);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing price type: $e');
          }
          // Continue with other price types instead of failing completely
        }
      }

      return priceTypes;
    } on XmlException catch (e) {
      throw Exception('XML parsing error while getting price types: ${e.message}');
    } on DioException catch (e) {
      throw Exception('Network error while getting price types: ${e.message}');
    } catch (e) {
      if (e is ArgumentError) {
        rethrow; // Re-throw validation errors
      }
      throw Exception('Unexpected error while getting price types: $e');
    }
  }

  /// Get product prices by price type
  Future<List<ProductPrice>> getProductPrices({
    required String userCode,
  }) async {
    if (userCode.isEmpty) {
      throw ArgumentError('UserCode cannot be empty');
    }

    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetPriceList>
         <sam:UserCode>$userCode</sam:UserCode>
      </sam:GetPriceList>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      if (response.data == null || response.data.toString().isEmpty) {
        throw Exception('Empty response from server');
      }

      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      if (rowsElements.isEmpty) {
        if (kDebugMode) {
          print('No product prices found in response');
        }
        return [];
      }

      final productPrices = <ProductPrice>[];
      for (final row in rowsElements) {
        try {
          final productPrice = ProductPrice(
            priceTypeCode: _getElementText(row, 'm:CodeTypePrice') ?? '',
            productCode: _getElementText(row, 'm:CodeProduct') ?? '',
            price: double.tryParse(_getElementText(row, 'm:Price') ?? '0') ?? 0.0,
          );
          productPrices.add(productPrice);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing product price: $e');
          }
          // Continue with other product prices instead of failing completely
        }
      }

      return productPrices;
    } on XmlException catch (e) {
      throw Exception('XML parsing error while getting product prices: ${e.message}');
    } on DioException catch (e) {
      throw Exception('Network error while getting product prices: ${e.message}');
    } catch (e) {
      if (e is ArgumentError) {
        rethrow; // Re-throw validation errors
      }
      throw Exception('Unexpected error while getting product prices: $e');
    }
  }

  /// Get promotions data
  Future<List<PromotionModel>> getPromotions({
    String? authToken,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] DEBUG API: getPromotions called');

    const soapEnvelope = '''
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sam="http://www.sample-package.org">
   <soapenv:Header/>
   <soapenv:Body>
      <sam:getPromo/>
   </soapenv:Body>
</soapenv:Envelope>
''';

    try {

      print('[$timestamp] DEBUG API: Sending SOAP request to $_baseUrl');
      print('[$timestamp] DEBUG API: SOAP Envelope: $soapEnvelope');
      try {
        final response = await _dio.post(
          _baseUrl,
          data: soapEnvelope,
          options: Options(
            headers: {
              'Content-Type': 'application/soap+xml; charset=utf-8',
              'SOAPAction': '',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
          ),
        );
        print('[$timestamp] DEBUG API: Received response from server');
        // Log the auth token if available
        if (authToken != null) {
          print('[$timestamp] DEBUG API: Using auth token: $authToken');
        } else {
          print('[$timestamp] DEBUG API: No auth token provided');
        }
        print("-------------------my check___________________ ${response}");
      } catch (e) {
        print('[$timestamp] DEBUG API: Error printing auth token: $e');
      }
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );
      print('-------------------my check___________________ \n${response}');
      print('[$timestamp] DEBUG API: Response status: ${response.statusCode}');
      print('[$timestamp] DEBUG API: Response data length: ${response.data.length}');

      // Check for HTTP status errors
      final responseData = response.data.toString();
      if (response.statusCode != 200) {
        print('[$timestamp] DEBUG API: HTTP error detected: ${response.statusCode}');

        // Prepare appropriate error message based on status code
        String faultMessage;
        switch (response.statusCode) {
          case 400:
            faultMessage = 'Bad Request: The request was malformed or invalid';
            break;
          case 401:
            faultMessage = 'Unauthorized: Authentication required';
            break;
          case 403:
            faultMessage = 'Forbidden: Access denied';
            break;
          case 404:
            faultMessage = 'Not Found: The requested resource was not found';
            break;
          case 405:
            faultMessage = 'Method Not Allowed: The HTTP method is not supported';
            break;
          case 408:
            faultMessage = 'Request Timeout: The server timed out waiting for the request';
            break;
          case 429:
            faultMessage = 'Too Many Requests: Rate limit exceeded';
            break;
          case 500:
            faultMessage = 'Internal Server Error: An error occurred on the server';
            break;
          case 502:
            faultMessage = 'Bad Gateway: Invalid response from upstream server';
            break;
          case 503:
            faultMessage = 'Service Unavailable: The server is temporarily unavailable';
            break;
          case 504:
            faultMessage = 'Gateway Timeout: The server timed out';
            break;
          default:
            faultMessage = 'HTTP Error ${response.statusCode}: An unexpected error occurred';
        }

        // Try to extract SOAP fault details if present
        try {
          final document = XmlDocument.parse(responseData);
          final faultElement = document.findAllElements('soap:Fault').firstOrNull ??
                              document.findAllElements('Fault').firstOrNull;
          if (faultElement != null) {
            final faultString = faultElement.findAllElements('faultstring').firstOrNull?.innerText ??
                               faultElement.findAllElements('detail').firstOrNull?.innerText ??
                               'Unknown SOAP fault';
            faultMessage = 'SOAP Fault (${response.statusCode}): $faultString';
          }
        } catch (e) {
          print('[$timestamp] DEBUG API: Error parsing fault details: $e');
          // Keep the HTTP status-based message
        }

        // Log the error
        print('[$timestamp] ERROR API: $faultMessage');
        print('[$timestamp] ERROR API: Status Code: ${response.statusCode}');
        print('[$timestamp] ERROR API: Full response: $responseData');

        // Throw SoapFaultException to be caught by the outer catch block
        throw SoapFaultException(faultMessage, responseData);
      }

      final document = XmlDocument.parse(response.data);
      print('[$timestamp] DEBUG API: Parsed XML document');
      debugPrint('Document data: ${document.toString()}');

      final returnElement = document.findAllElements('m:return').first;
      final rowElements = returnElement.findAllElements('m:row').where((row) =>
        row.children.isNotEmpty && row.findElements('m:code').isNotEmpty);
      print('[$timestamp] DEBUG API: Found ${rowElements.length} row elements');

      final promotions = rowElements.map((element) {
        print('[$timestamp] DEBUG API: Parsing promotion from XML element');
        return PromotionModel.fromXml(element);
      }).toList();

      print('[$timestamp] DEBUG API: Successfully parsed ${promotions.length} promotions');
      return promotions;
    } catch (e) {
      print('[$timestamp] DEBUG API: Error in getPromotions: $e');

      // Check if this is a method not found error (common on some servers like Garnier)
      if (e.toString().contains('method') ||
          e.toString().contains('not found') ||
          e.toString().contains('available') ||
          e.toString().contains('500')) {
        print('[$timestamp] DEBUG API: getPromo method not available on this server, returning empty list');
        return []; // Return empty list instead of throwing
      }

      throw Exception('Promosyon ma\'lumotlarini olishda xatolik: $e');
    }
  }

  /// Get all client contracts
  Future<List<ClientContract>> getAllContracts({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetAllContracts>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:GetAllContracts>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements.map((row) => ClientContract(
        codeContract: _getElementText(row, 'm:CodeContract') ?? '',
        dateOfContract: _parseDate(_getElementText(row, 'm:DateOfContract')),
        sumOfContract: double.tryParse(_getElementText(row, 'm:SumOfContract') ?? '0') ?? 0.0,
        termOfContract: _parseDate(_getElementText(row, 'm:TermOfContract')),
        typeContract: _getElementText(row, 'm:TypeContract'),
        numbReference: _getElementText(row, 'm:NumbReference'),
        numbCertificate: _getElementText(row, 'm:NumbCertificate'),
        termReference: _parseDate(_getElementText(row, 'm:TermReference')),
        termCertificate: _parseDate(_getElementText(row, 'm:TermCertificate')),
        numbPassport: _getElementText(row, 'm:NumbPassport'),
        termPassport: _parseDate(_getElementText(row, 'm:TermPassport')),
        certificateUnlimited: int.tryParse(_getElementText(row, 'm:CertificateUnlimited') ?? '0') ?? 0,
        codeDistrict: _getElementText(row, 'm:CodeDistrict'),
        nameDistrict: _getElementText(row, 'm:NameDistrict'),
        codeProject: _getElementText(row, 'm:CodeProject'),
        codeClient: _getElementText(row, 'm:CodeClient') ?? '',
        active: _getElementText(row, 'm:Active')?.toLowerCase() == 'true',
        status: _getElementText(row, 'm:Status') ?? 'Неизвестно',
      )).toList();
    } catch (e) {
      throw Exception('Shartnomalar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get report by period
  Future<Map<String, dynamic>> getReportByPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
  }) async
  {
    final soapEnvelope = '''
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
        <soap:Header/>
        <soap:Body>
          <sam:GetReportByPeriod>
            <sam:UserCode>$userCode</sam:UserCode>
            <sam:DateStart>$dateStart</sam:DateStart>
            <sam:DateEnd>$dateEnd</sam:DateEnd>
          </sam:GetReportByPeriod>
        </soap:Body>
      </soap:Envelope>
      ''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final returnElement = document.findAllElements('m:return').first;

      // Parse main report data
      final countAKB = int.tryParse(_getElementText(returnElement, 'CountAKB') ?? '0') ?? 0;
      final countOKB = int.tryParse(_getElementText(returnElement, 'CountOKB') ?? '0') ?? 0;
      final cash = double.tryParse(_getElementText(returnElement, 'Cash') ?? '0') ?? 0.0;
      final transfer = double.tryParse(_getElementText(returnElement, 'Transfer') ?? '0') ?? 0.0;
      final sum = double.tryParse(_getElementText(returnElement, 'Sum') ?? '0') ?? 0.0;
      final countVisited = int.tryParse(_getElementText(returnElement, 'CountVisited') ?? '0') ?? 0;
      final dateStartParsed = _getElementText(returnElement, 'DateStart') ?? dateStart;
      final dateEndParsed = _getElementText(returnElement, 'DateEnd') ?? dateEnd;

      final mainReport = MainReport(
        userCode: userCode,
        dateStart: DateTime.parse(dateStartParsed),
        dateEnd: DateTime.parse(dateEndParsed),
        countAKB: countAKB,
        countOKB: countOKB,
        cash: cash,
        transfer: transfer,
        sum: sum,
        countVisited: countVisited,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Parse business region reports
      final businessRegionReports = <BusinessRegionReport>[];
      final businessRegionElements = returnElement.findAllElements('BusinessRegionReportRow');
      for (final element in businessRegionElements) {
        final code = _getElementText(element, 'Code') ?? '';
        final name = _getElementText(element, 'Name') ?? '';
        final akb = int.tryParse(_getElementText(element, 'AKB') ?? '0') ?? 0;

        if (code.isNotEmpty) {
          businessRegionReports.add(BusinessRegionReport(
            mainReportId: 0, // Will be set when saving
            code: code,
            name: name,
            akb: akb,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      // Parse AKB by categories
      final akbByCategories = <AKBByCategory>[];
      final akbCategoryElements = returnElement.findAllElements('AKBByCotegoriesRow');
      for (final element in akbCategoryElements) {
        final code = _getElementText(element, 'Code') ?? '';
        final name = _getElementText(element, 'Name') ?? '';
        final akb = int.tryParse(_getElementText(element, 'AKB') ?? '0') ?? 0;

        if (code.isNotEmpty) {
          akbByCategories.add(AKBByCategory(
            mainReportId: 0, // Will be set when saving
            code: code,
            name: name,
            akb: akb,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      return {
        'mainReport': mainReport,
        'businessRegionReports': businessRegionReports,
        'akbByCategories': akbByCategories,
      };
    } catch (e) {
      throw Exception('Hisobot ma\'lumotlarini olishda xatolik: $e');
    }
  }

  /// Helper method to parse date strings
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '0001-01-01') {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get element text
  String? _getElementText(XmlElement parent, String elementName) {
    try {
      final elements = parent.findElements(elementName);
      return elements.isNotEmpty ? elements.first.innerText : null;
    } catch (e) {
      return null;
    }
  }

  /// Get order status list
  Future<List<OrderStatus>> getOrderStatusList({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getOrderStatusList>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:getOrderStatusList>
   </soap:Body>
</soap:Envelope>
''';
    //print(soapEnvelope);
    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );
      //print('buyurtmalar statuslari soap holatda: ${response.data}');
      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Row');

      return rowsElements.map((row) => OrderStatus(
        message: _getElementText(row, 'm:message') ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Buyurtma statuslari ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get order list
  Future<List<Order>> getOrderList({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetOrderList>
         <sam:CodeAgent>$userCode</sam:CodeAgent>
      </sam:GetOrderList>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );
      print('buyurtmalar royxati soap holatda: ${response.data}');
      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements.map((row) => Order(
        numOrder: _getElementText(row, 'm:NumOrder') ?? '',
        dateOrder: DateTime.parse(_getElementText(row, 'm:DateOrder') ?? DateTime.now().toIso8601String()),
        captionOrder: _getElementText(row, 'm:CaptionOrder') ?? '',
        typePriceCode: _getElementText(row, 'm:TypePrice') ?? '',
        status: int.tryParse(_getElementText(row, 'm:Status') ?? '0') ?? 0,
        commentSupervisor: _getElementText(row, 'm:CommentSupervisor'),
        commentForwarder: _getElementText(row, 'm:CommentForwarder'),
        commentAgent: _getElementText(row, 'm:CommentAgent'),
        total: double.tryParse(_getElementText(row, 'm:Total') ?? '0') ?? 0.0,
        clientCode: _getElementText(row, 'm:ClientCode') ?? '',
        clientName: _getElementText(row, 'm:ClientName') ?? '',
        codeOrg: _getElementText(row, 'm:CodeOrg') ?? '',
        mainStatus: _getElementText(row, 'm:mainStatus') ?? '',
        courierName: _getElementText(row, 'm:courierName'),
        courierCar: _getElementText(row, 'm:courierCar'),
        server: true, // Server-sourced data
      )).toList();
    } catch (e) {
      throw Exception('Buyurtmalar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get sales representative permissions
  Future<Map<String, dynamic>> getSalesReqPermissions({
    required String userCode,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getSalesReqPermissions>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:getSalesReqPermissions>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final returnElement = document.findAllElements('m:return').first;
      print(returnElement.toString());
      // Parse main permissions
      final skipTINduplicateCheck = _getElementText(returnElement, 'm:SkipTINduplicateCheck')?.toLowerCase() == 'true';
      final allowCreationWithoutTIN = _getElementText(returnElement, 'm:AllowCreationWithoutTIN')?.toLowerCase() == 'true';
      final allowCreatingPointOfSale = _getElementText(returnElement, 'm:AllowCreatingPointOfSale')?.toLowerCase() == 'true';
      final visit = _getElementText(returnElement, 'm:Visit')?.toLowerCase() == 'true';
      final strictSequence = _getElementText(returnElement, 'm:StrictSequence')?.toLowerCase() == 'true';
      final unplannedOrder = _getElementText(returnElement, 'm:UnplannedOrder')?.toLowerCase() == 'true';
      final plannedRoute = _getElementText(returnElement, 'm:PlannedRoute')?.toLowerCase() == 'true';

      // Parse visit steps
      final visitSteps = <Map<String, dynamic>>[];
      final stepElements = returnElement.findAllElements('m:StepList');
      for (final stepElement in stepElements) {
        final stepCode = int.tryParse(_getElementText(stepElement, 'm:stepCode') ?? '0') ?? 0;
        final stepName = _getElementText(stepElement, 'm:stepName') ?? '';
        final stepRequired = _getElementText(stepElement, 'm:stepRequired')?.toLowerCase() == 'true';

        visitSteps.add({
          'stepCode': stepCode,
          'stepName': stepName,
          'stepRequired': stepRequired,
        });
      }
      print({
        'permissions': {
          'userCode': userCode,
          'skipTINduplicateCheck': skipTINduplicateCheck,
          'allowCreationWithoutTIN': allowCreationWithoutTIN,
          'allowCreatingPointOfSale': allowCreatingPointOfSale,
          'visit': visit,
          'strictSequence': strictSequence,
          'unplannedOrder': unplannedOrder,
          'plannedRoute': plannedRoute,
        },
        'visitSteps': visitSteps,
      });
      return {
        'permissions': {
          'userCode': userCode,
          'skipTINduplicateCheck': skipTINduplicateCheck,
          'allowCreationWithoutTIN': allowCreationWithoutTIN,
          'allowCreatingPointOfSale': allowCreatingPointOfSale,
          'visit': visit,
          'strictSequence': strictSequence,
          'unplannedOrder': unplannedOrder,
          'plannedRoute': plannedRoute,
        },
        'visitSteps': visitSteps,
      };
    } catch (e) {
      throw Exception('Agent ruxsatlarini olishda xatolik: $e');
    }
  }

  /// Get order details
  Future<OrderDetail> getOrderDetails({
    required String numberOrder,
    required String orderDate1,
    required String orderDate2,
  }) async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetOrderDetailsnew>
         <sam:NumberOrder>$numberOrder</sam:NumberOrder>
         <sam:OrderDate1>$orderDate1</sam:OrderDate1>
         <sam:OrderDate2>$orderDate2</sam:OrderDate2>
      </sam:GetOrderDetailsnew>
   </soap:Body>
</soap:Envelope>
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
        ),
      );

      final document = XmlDocument.parse(response.data);
      final returnElement = document.findAllElements('m:return').first;

      // Parse main order details
      final credit = _getElementText(returnElement, 'm:Credit')?.toLowerCase() == 'true';
      final codePrice = _getElementText(returnElement, 'm:CodePrice') ?? '';
      final dateOrderStr = _getElementText(returnElement, 'm:DateOrder') ?? '';
      final dateOrder = DateTime.parse(dateOrderStr);
      final codeSklad = _getElementText(returnElement, 'm:CodeSklad') ?? '';
      final commentSupervisor = _getElementText(returnElement, 'm:CommentSupervisor');
      final commentForwarder = _getElementText(returnElement, 'm:CommentForwarder');
      final commentAgent = _getElementText(returnElement, 'm:CommentAgent');
      final shippingDateStr = _getElementText(returnElement, 'm:ShippingDate') ?? '';
      final shippingDate = DateTime.parse(shippingDateStr);
      final orderType = int.tryParse(_getElementText(returnElement, 'm:OrderType') ?? '0') ?? 0;
      final codeOrg = _getElementText(returnElement, 'm:CodeOrg') ?? '';

      // Parse product rows
      final productRows = <OrderDetailProduct>[];
      final productRowsElement = returnElement.findAllElements('m:ProductRows').firstOrNull;
      if (productRowsElement != null) {
        final rowsElements = productRowsElement.findAllElements('m:Rows');
        for (final row in rowsElements) {
          final product = OrderDetailProduct(
            codeProduct: _getElementText(row, 'm:CodeProduct') ?? '',
            nameProduct: _getElementText(row, 'm:NameProduct') ?? '',
            amount: int.tryParse(_getElementText(row, 'm:Amount') ?? '0') ?? 0,
            price: double.tryParse(_getElementText(row, 'm:Price') ?? '0') ?? 0.0,
            total: double.tryParse(_getElementText(row, 'm:Total') ?? '0') ?? 0.0,
            discountRate: double.tryParse(_getElementText(row, 'm:DiscountRate') ?? '0') ?? 0.0,
            weight: double.tryParse(_getElementText(row, 'm:Weight') ?? '0') ?? 0.0,
            capacity: double.tryParse(_getElementText(row, 'm:Capacity') ?? '0') ?? 0.0,
          );
          productRows.add(product);
        }
      }

      // Parse credit details list (payments)
      final creditDetailsList = <OrderPayment>[];
      final creditDetailsElement = returnElement.findAllElements('m:CreditDetailsList').firstOrNull;
      if (creditDetailsElement != null) {
        final rowsElements = creditDetailsElement.findAllElements('m:Rows');
        for (final row in rowsElements) {
          final payment = OrderPayment(
            dateOfPayment: _getElementText(row, 'm:DateOfPayment') ?? '',
            total: double.tryParse(_getElementText(row, 'm:Total') ?? '0') ?? 0.0,
          );
          creditDetailsList.add(payment);
        }
      }

      return OrderDetail(
        numOrder: numberOrder,
        credit: credit,
        codePrice: codePrice,
        dateOrder: dateOrder,
        codeSklad: codeSklad,
        commentSupervisor: commentSupervisor,
        commentForwarder: commentForwarder,
        commentAgent: commentAgent,
        shippingDate: shippingDateStr,
        orderType: orderType,
        codeOrg: codeOrg,
        productRows: productRows,
        creditDetailsList: creditDetailsList,
      );
    } catch (e) {
      throw Exception('Buyurtma tafsilotlarini olishda xatolik: $e');
    }
  }
}