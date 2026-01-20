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
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/contract_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/district_contracting.dart';
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
    final soapEnvelope =
        '''
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
      if (kDebugMode) print("user: $userCode");
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
      if (kDebugMode) print('KPI data response: ${response.data}');
      final document = XmlDocument.parse(response.data);

      final returnElement = document.findAllElements('m:return').first;
      if (kDebugMode) print('KPI data response: $returnElement');

      return KpiData(
        plan: returnElement.findElements('m:TotalPlan').first.innerText,
        fact: returnElement.findElements('m:TotalFact').first.innerText,
        totalPercent: returnElement
            .findElements('m:TotalPercent')
            .first
            .innerText,
        totalForecast: returnElement
            .findElements('m:TotalForecast')
            .first
            .innerText,
        totalPercentForecastFact: returnElement
            .findElements('m:TotalPercentForecastFact')
            .first
            .innerText,
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
    final soapEnvelope =
        '''
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

      return rowsElements
          .map(
            (row) => TradingPoint(
              id: _getElementText(row, 'm:Code') ?? '',
              name: _getElementText(row, 'm:Name') ?? '',
              address: _getElementText(row, 'm:AdressDelivery') ?? '',
              phone: _getElementText(row, 'm:ContactPersonPhone') ?? '',
              ownerName: _getElementText(row, 'm:ContactPerson') ?? '',
              contactPerson: _getElementText(row, 'm:ContactPerson') ?? '',
              inn: _getElementText(row, 'm:INN') ?? '',
              status: 'active',
              lastVisitDate: '',
              hasOrders:
                  int.tryParse(
                    _getElementText(row, 'm:TheNumberOfOrders') ?? '0',
                  ) !=
                  0,
              hasContracts: false,
              isVisited: false,
              hasContract: false,
              latitude:
                  double.tryParse(_getElementText(row, 'm:Latitude') ?? '0') ??
                  0.0,
              longitude:
                  double.tryParse(_getElementText(row, 'm:Longitude') ?? '0') ??
                  0.0,
              region: '',
              district: '',
              signboard: _getElementText(row, 'm:Signboard') ?? '',
              referencePoint: _getElementText(row, 'm:ReferencePoint') ?? '',
              responsiblePerson:
                  _getElementText(row, 'm:ResponsiblePerson') ?? '',
              responsiblePersonPhone:
                  _getElementText(row, 'm:ResponsiblePersonPhone') ?? '',
              tradePointType: _getElementText(row, 'm:TradePointType') ?? '',
              creditLimit:
                  double.tryParse(
                    _getElementText(row, 'm:CreditLimit') ?? '0',
                  ) ??
                  0.0,
              accumulatedCredit:
                  double.tryParse(
                    _getElementText(row, 'm:AccumulatedCredit') ?? '0',
                  ) ??
                  0.0,
              codeRegion: _getElementText(row, 'm:CodeRegion') ?? '',
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Mijozlar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get business regions list
  Future<List<BusinessRegion>> getBusinessRegions({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
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

      return rowsElements
          .map(
            (row) => BusinessRegion(
              code: _getElementText(row, 'm:Code') ?? '',
              name: _getElementText(row, 'm:Name') ?? '',
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Biznes rayonlari ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get user warehouses list
  Future<List<UserWarehouse>> getWarehousesUser({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
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

      return warehouseElements
          .map(
            (warehouse) => UserWarehouse(
              code: _getElementText(warehouse, 'm:Code') ?? '',
              name: _getElementText(warehouse, 'm:Name') ?? '',
              organization: _getElementText(warehouse, 'm:Organization') ?? '',
            ),
          )
          .toList();
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
    final soapEnvelope =
        '''
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
    final soapEnvelope =
        '''
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
    final soapEnvelope =
        '''
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
  Future<String> deleteAllBusinessRegions({required String userCode}) async {
    final soapEnvelope =
        '''
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
    final soapEnvelope =
        '''
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
                  products.add(
                    ProductData(
                      code: _getElementText(row, 'm:CodeProduct') ?? '',
                      name: _getElementText(row, 'm:NameProduct') ?? '',
                      unit: '',
                      quantity: 0.0,
                      reserved:
                          double.tryParse(
                            _getElementText(row, 'm:Reserved') ?? '0',
                          ) ??
                          0.0,
                      available:
                          double.tryParse(
                            _getElementText(row, 'm:Aviable') ?? '0',
                          ) ??
                          0.0,
                      category: '',
                      barcode: '',
                      have:
                          int.tryParse(_getElementText(row, 'm:Have') ?? '0') ??
                          0,
                      warehouseCode: _getElementText(row, 'm:CodeSklad') ?? '',
                      weight:
                          double.tryParse(
                            _getElementText(row, 'm:Weight') ?? '0',
                          ) ??
                          0.0,
                      capacity:
                          double.tryParse(
                            _getElementText(row, 'm:Capacity') ?? '0',
                          ) ??
                          0.0,
                      vendorCode: _getElementText(row, 'm:VendorCode') ?? '',
                      productBrand: brandName,
                      productSeries: seriesName,
                      codeProject: _getElementText(row, 'm:CodeProject') ?? '',
                    ),
                  );
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
    final soapEnvelope =
        '''
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
                  balances.add(
                    ProductBalance(
                      codeSklad: _getElementText(row, 'm:CodeSklad') ?? '',
                      codeProduct: _getElementText(row, 'm:CodeProduct') ?? '',
                      nameProduct: _getElementText(row, 'm:NameProduct') ?? '',
                      have:
                          int.tryParse(_getElementText(row, 'm:Have') ?? '0') ??
                          0,
                      reserved:
                          int.tryParse(
                            _getElementText(row, 'm:Reserved') ?? '0',
                          ) ??
                          0,
                      available:
                          int.tryParse(
                            _getElementText(row, 'm:Aviable') ?? '0',
                          ) ??
                          0,
                      weight:
                          double.tryParse(
                            _getElementText(row, 'm:Weight') ?? '0',
                          ) ??
                          0.0,
                      capacity:
                          double.tryParse(
                            _getElementText(row, 'm:Capacity') ?? '0',
                          ) ??
                          0.0,
                      codeProject: _getElementText(row, 'm:CodeProject') ?? '',
                      vendorCode: _getElementText(row, 'm:VendorCode') ?? '',
                      productBrand: brandName,
                      productSeries: seriesName,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      return {'balances': balances, 'brands': brands, 'series': series};
    } catch (e) {
      throw Exception('Mahsulot balanslarini olishda xatolik: $e');
    }
  }

  /// Get price types
  Future<List<PriceType>> getPriceTypes({required String userCode}) async {
    if (userCode.isEmpty) {
      throw ArgumentError('UserCode cannot be empty');
    }

    final soapEnvelope =
        '''
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
      throw Exception(
        'XML parsing error while getting price types: ${e.message}',
      );
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

    final soapEnvelope =
        '''
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
            price:
                double.tryParse(_getElementText(row, 'm:Price') ?? '0') ?? 0.0,
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
      throw Exception(
        'XML parsing error while getting product prices: ${e.message}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Network error while getting product prices: ${e.message}',
      );
    } catch (e) {
      if (e is ArgumentError) {
        rethrow; // Re-throw validation errors
      }
      throw Exception('Unexpected error while getting product prices: $e');
    }
  }

  /// Get promotions data
  Future<List<PromotionModel>> getPromotions({String? authToken}) async {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG API: getPromotions called');

    const soapEnvelope = '''
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sam="http://www.sample-package.org">
   <soapenv:Header/>
   <soapenv:Body>
      <sam:getPromo/>
   </soapenv:Body>
</soapenv:Envelope>
''';

    try {
      if (kDebugMode) {
        print('[$timestamp] DEBUG API: Sending SOAP request to $_baseUrl');
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
          validateStatus: (status) => true,
        ),
      );
      if (kDebugMode) {
        print('-------------------my check___________________ \n${response}');
        print(
          '[$timestamp] DEBUG API: Response status: ${response.statusCode}',
        );
        print(
          '[$timestamp] DEBUG API: Response data length: ${response.data.length}',
        );
      }

      // Check for SOAP Fault or HTTP status errors
      // Fault tekshirish - statusCode qanday bo'lishidan qat'i nazar
      final responseData = response.data.toString();
      if (responseData.contains('Fault') || response.statusCode != 200) {
        if (kDebugMode)
          print(
            '[$timestamp] DEBUG API: HTTP error detected: ${response.statusCode}',
          );

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
            faultMessage =
                'Method Not Allowed: The HTTP method is not supported';
            break;
          case 408:
            faultMessage =
                'Request Timeout: The server timed out waiting for the request';
            break;
          case 429:
            faultMessage = 'Too Many Requests: Rate limit exceeded';
            break;
          case 500:
            faultMessage =
                'Internal Server Error: An error occurred on the server';
            break;
          case 502:
            faultMessage = 'Bad Gateway: Invalid response from upstream server';
            break;
          case 503:
            faultMessage =
                'Service Unavailable: The server is temporarily unavailable';
            break;
          case 504:
            faultMessage = 'Gateway Timeout: The server timed out';
            break;
          default:
            faultMessage =
                'HTTP Error ${response.statusCode}: An unexpected error occurred';
        }

        // Try to extract SOAP fault details if present
        try {
          final document = XmlDocument.parse(responseData);
          final faultElement =
              document.findAllElements('soap:Fault').firstOrNull ??
              document.findAllElements('Fault').firstOrNull;
          if (faultElement != null) {
            final faultString =
                faultElement
                    .findAllElements('faultstring')
                    .firstOrNull
                    ?.innerText ??
                faultElement.findAllElements('detail').firstOrNull?.innerText ??
                'Unknown SOAP fault';
            faultMessage = 'SOAP Fault (${response.statusCode}): $faultString';
          }
        } catch (e) {
          if (kDebugMode)
            print('[$timestamp] DEBUG API: Error parsing fault details: $e');
          // Keep the HTTP status-based message
        }

        // Log the error
        if (kDebugMode) {
          print('[$timestamp] ERROR API: $faultMessage');
          print('[$timestamp] ERROR API: Status Code: ${response.statusCode}');
          print('[$timestamp] ERROR API: Full response: $responseData');
        }

        // Throw SoapFaultException to be caught by the outer catch block
        throw SoapFaultException(faultMessage, responseData);
      }

      final document = XmlDocument.parse(response.data);
      if (kDebugMode) print('[$timestamp] DEBUG API: Parsed XML document');
      debugPrint('Document data: ${document.toString()}');

      final returnElement = document.findAllElements('m:return').first;
      final rowElements = returnElement
          .findAllElements('m:row')
          .where(
            (row) =>
                row.children.isNotEmpty &&
                row.findElements('m:code').isNotEmpty,
          );
      if (kDebugMode)
        print(
          '[$timestamp] DEBUG API: Found ${rowElements.length} row elements',
        );

      final promotions = rowElements.map((element) {
        if (kDebugMode)
          print('[$timestamp] DEBUG API: Parsing promotion from XML element');
        return PromotionModel.fromXml(element);
      }).toList();

      if (kDebugMode)
        print(
          '[$timestamp] DEBUG API: Successfully parsed ${promotions.length} promotions',
        );
      return promotions;
    } on SoapFaultException catch (e) {
      // SOAP Fault xatosi - bo'sh ro'yxat qaytarish va davom etish
      if (kDebugMode) {
        print('[$timestamp] DEBUG API: SOAP Fault detected: ${e.message}');
        print('[$timestamp] DEBUG API: Returning empty promotions list');
      }
      return [];
    } catch (e) {
      if (kDebugMode)
        print('[$timestamp] DEBUG API: Error in getPromotions: $e');

      // Check if this is a method not found error or Fault (common on some servers)
      if (e.toString().contains('method') ||
          e.toString().contains('not found') ||
          e.toString().contains('available') ||
          e.toString().contains('Fault') ||
          e.toString().contains('500')) {
        if (kDebugMode)
          print(
            '[$timestamp] DEBUG API: getPromo method not available on this server, returning empty list',
          );
        return []; // Return empty list instead of throwing
      }

      if (kDebugMode)
        print('[$timestamp] DEBUG API: Unexpected error in getPromotions: $e');
      return []; // Har qanday xatolikda bo'sh ro'yxat qaytarish
    }
  }

  /// Get all client contracts
  Future<List<ClientContract>> getAllContracts({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
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

      return rowsElements
          .map(
            (row) => ClientContract(
              codeContract: _getElementText(row, 'm:CodeContract') ?? '',
              dateOfContract: _parseDate(
                _getElementText(row, 'm:DateOfContract'),
              ),
              sumOfContract:
                  double.tryParse(
                    _getElementText(row, 'm:SumOfContract') ?? '0',
                  ) ??
                  0.0,
              termOfContract: _parseDate(
                _getElementText(row, 'm:TermOfContract'),
              ),
              typeContract: _getElementText(row, 'm:TypeContract'),
              numbReference: _getElementText(row, 'm:NumbReference'),
              numbCertificate: _getElementText(row, 'm:NumbCertificate'),
              termReference: _parseDate(
                _getElementText(row, 'm:TermReference'),
              ),
              termCertificate: _parseDate(
                _getElementText(row, 'm:TermCertificate'),
              ),
              numbPassport: _getElementText(row, 'm:NumbPassport'),
              termPassport: _parseDate(_getElementText(row, 'm:TermPassport')),
              certificateUnlimited:
                  int.tryParse(
                    _getElementText(row, 'm:CertificateUnlimited') ?? '0',
                  ) ??
                  0,
              codeDistrict: _getElementText(row, 'm:CodeDistrict'),
              nameDistrict: _getElementText(row, 'm:NameDistrict'),
              codeProject: _getElementText(row, 'm:CodeProject'),
              codeClient: _getElementText(row, 'm:CodeClient') ?? '',
              active: _getElementText(row, 'm:Active')?.toLowerCase() == 'true',
              status: _getElementText(row, 'm:Status') ?? 'Неизвестно',
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Shartnomalar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get report by period
  Future<Map<String, dynamic>> getReportByPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
  }) async {
    final soapEnvelope =
        '''
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
      final countAKB =
          int.tryParse(_getElementText(returnElement, 'CountAKB') ?? '0') ?? 0;
      final countOKB =
          int.tryParse(_getElementText(returnElement, 'CountOKB') ?? '0') ?? 0;
      final cash =
          double.tryParse(_getElementText(returnElement, 'Cash') ?? '0') ?? 0.0;
      final transfer =
          double.tryParse(_getElementText(returnElement, 'Transfer') ?? '0') ??
          0.0;
      final sum =
          double.tryParse(_getElementText(returnElement, 'Sum') ?? '0') ?? 0.0;
      final countVisited =
          int.tryParse(_getElementText(returnElement, 'CountVisited') ?? '0') ??
          0;
      final dateStartParsed =
          _getElementText(returnElement, 'DateStart') ?? dateStart;
      final dateEndParsed =
          _getElementText(returnElement, 'DateEnd') ?? dateEnd;

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
      final businessRegionElements = returnElement.findAllElements(
        'BusinessRegionReportRow',
      );
      for (final element in businessRegionElements) {
        final code = _getElementText(element, 'Code') ?? '';
        final name = _getElementText(element, 'Name') ?? '';
        final akb = int.tryParse(_getElementText(element, 'AKB') ?? '0') ?? 0;

        if (code.isNotEmpty) {
          businessRegionReports.add(
            BusinessRegionReport(
              mainReportId: 0, // Will be set when saving
              code: code,
              name: name,
              akb: akb,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      // Parse AKB by categories
      final akbByCategories = <AKBByCategory>[];
      final akbCategoryElements = returnElement.findAllElements(
        'AKBByCotegoriesRow',
      );
      for (final element in akbCategoryElements) {
        final code = _getElementText(element, 'Code') ?? '';
        final name = _getElementText(element, 'Name') ?? '';
        final akb = int.tryParse(_getElementText(element, 'AKB') ?? '0') ?? 0;

        if (code.isNotEmpty) {
          akbByCategories.add(
            AKBByCategory(
              mainReportId: 0, // Will be set when saving
              code: code,
              name: name,
              akb: akb,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
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
    if (dateString == null ||
        dateString.isEmpty ||
        dateString == '0001-01-01') {
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

  /// Helper method to format DateTime to YYYYMMDD string format
  /// This method converts a DateTime object to a string in the format required by the server API
  /// Format: YYYYMMDD (e.g., "20251203" for December 3, 2025)
  /// Used for CreateDate and ShippingDate fields in setOrder XML requests
  String _formatDateForApi(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Get order status list
  Future<List<OrderStatus>> getOrderStatusList({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
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

      return rowsElements
          .map(
            (row) =>
                OrderStatus(message: _getElementText(row, 'm:message') ?? ''),
          )
          .toList();
    } catch (e) {
      throw Exception('Buyurtma statuslari ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Generate SOAP request XML for setOrder method (for debugging/display purposes)
  String generateSetOrderSoapRequest(CreateOrder order) {
    final productsXml = order.products
        .map((product) {
          return '''
      <sam:Rows>
        <sam:CodeSklad>${order.codeSklad}</sam:CodeSklad>
        <sam:CodeProduct>${product.codeProduct}</sam:CodeProduct>       
        <sam:Amount>${product.amount}</sam:Amount>
        <sam:Price>${product.price}</sam:Price>
        <sam:Total>${product.total}</sam:Total>
        <sam:Weight>${product.weight}</sam:Weight>
        <sam:Capacity>${product.capacity}</sam:Capacity>
        <sam:PaymentType>${product.paymentType}</sam:PaymentType>
        <sam:DiscountSum>${product.discountSum}</sam:DiscountSum>
        <sam:DiscountRate>${product.discountRate}</sam:DiscountRate>
        <sam:GiftAmount>${product.giftAmount}</sam:GiftAmount>
      </sam:Rows>''';
        })
        .join('\n');

    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
  <soap:Header/>
  <soap:Body>
    <sam:SetOrder>
      <sam:CodeAgent>${order.codeAgent}</sam:CodeAgent>
      <sam:CodeClient>${order.codeClient}</sam:CodeClient>
      <sam:CodePrice>${order.codePrice}</sam:CodePrice>
      <sam:Payment>${order.payment}</sam:Payment>
      <!-- ShippingDate formatted as YYYYMMDD string (e.g., "20251203") as required by server API -->
      <sam:ShippingDate>${_formatDateForApi(order.shippingDate)}</sam:ShippingDate>
      <sam:CommentSupervisor>${order.commentSupervisor ?? ''}</sam:CommentSupervisor>
      <sam:CommentForwarder>${order.commentForwarder ?? ''}</sam:CommentForwarder>
      <sam:Comment>${order.comment ?? ''}</sam:Comment>
      <!-- CreateDate formatted as YYYYMMDD string (e.g., "20251203") as required by server API -->
      <sam:CreateDate>${_formatDateForApi(order.createDate)}</sam:CreateDate>
      <sam:Longitude>${order.longitude}</sam:Longitude>
      <sam:Latitude>${order.latitude}</sam:Latitude>
      <sam:Weight>${order.weight}</sam:Weight>
      <sam:Capacity>${order.capacity}</sam:Capacity>
      <sam:Credit>${order.credit ? 1 : 0}</sam:Credit>
      <sam:CodeProject>${order.codeProject}</sam:CodeProject>
      <sam:OrderType>${order.orderType}</sam:OrderType>
      <sam:CodeOrg>${order.codeOrg}</sam:CodeOrg>
      <sam:CodeSklad>${order.codeSklad}</sam:CodeSklad>
      <sam:CodeContract>${order.codeContract ?? ''}</sam:CodeContract>
      
      <sam:ProductsList>
        $productsXml
      </sam:ProductsList>
    </sam:SetOrder>
  </soap:Body>
</soap:Envelope>''';

    return soapEnvelope.trim();
  }

  /// Get order list
  Future<List<Order>> getOrderList({required String userCode}) async {
    final soapEnvelope =
        '''
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
      if (kDebugMode)
        print('buyurtmalar royxati soap holatda: ${response.data}');
      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements
          .map(
            (row) => Order(
              numOrder: _getElementText(row, 'm:NumOrder') ?? '',
              dateOrder: DateTime.parse(
                _getElementText(row, 'm:DateOrder') ??
                    DateTime.now().toIso8601String(),
              ),
              captionOrder: _getElementText(row, 'm:CaptionOrder') ?? '',
              typePriceCode: _getElementText(row, 'm:TypePrice') ?? '',
              status:
                  int.tryParse(_getElementText(row, 'm:Status') ?? '0') ?? 0,
              commentSupervisor: _getElementText(row, 'm:CommentSupervisor'),
              commentForwarder: _getElementText(row, 'm:CommentForwarder'),
              commentAgent: _getElementText(row, 'm:CommentAgent'),
              total:
                  double.tryParse(_getElementText(row, 'm:Total') ?? '0') ??
                  0.0,
              clientCode: _getElementText(row, 'm:ClientCode') ?? '',
              clientName: _getElementText(row, 'm:ClientName') ?? '',
              codeOrg: _getElementText(row, 'm:CodeOrg') ?? '',
              mainStatus: _getElementText(row, 'm:mainStatus') ?? '',
              courierName: _getElementText(row, 'm:courierName'),
              courierCar: _getElementText(row, 'm:courierCar'),
              server: true, // Server-sourced data
              promo: _getElementText(row, 'm:Promo')?.toLowerCase() == 'true',
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Buyurtmalar ro\'yxatini olishda xatolik: $e');
    }
  }

  /// Get sales representative permissions
  Future<Map<String, dynamic>> getSalesReqPermissions({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
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
      if (kDebugMode) {
        print(returnElement.toString());
      }
      // Parse main permissions

      final userCoded = _getElementText(returnElement, 'm:userCode');
      if (kDebugMode) {
        print('userCode: $userCoded');
        print('userCode: $userCode');
      }
      final skipTINduplicateCheck =
          _getElementText(
            returnElement,
            'm:SkipTINduplicateCheck',
          )?.toLowerCase() ==
          'true';
      final allowCreationWithoutTIN =
          _getElementText(
            returnElement,
            'm:AllowCreationWithoutTIN',
          )?.toLowerCase() ==
          'true';
      final allowCreatingPointOfSale =
          _getElementText(
            returnElement,
            'm:AllowCreatingPointOfSale',
          )?.toLowerCase() ==
          'true';
      final visit =
          _getElementText(returnElement, 'm:Visit')?.toLowerCase() == 'true';
      final strictSequence =
          _getElementText(returnElement, 'm:StrictSequence')?.toLowerCase() ==
          'true';
      final unplannedOrder =
          _getElementText(returnElement, 'm:UnplannedOrder')?.toLowerCase() ==
          'true';
      final plannedRoute =
          _getElementText(returnElement, 'm:PlannedRoute')?.toLowerCase() ==
          'true';
      final editClientCoordinates =
          _getElementText(
            returnElement,
            'm:EditСlientСoordinates',
          )?.toLowerCase() ==
          'true';
      final clientZoneAccess =
          int.tryParse(
            _getElementText(returnElement, 'm:ClientZoneAccess') ?? '0',
          ) ??
          0;
      final locationUpdateInterval =
          int.tryParse(
            _getElementText(returnElement, 'm:LocationUpdateInterval') ?? '0',
          ) ??
          0;

      // Parse visit steps
      final visitSteps = <Map<String, dynamic>>[];
      final stepElements = returnElement.findAllElements('m:StepList');

      for (final stepElement in stepElements) {
        final stepCode =
            int.tryParse(_getElementText(stepElement, 'm:stepCode') ?? '0') ??
            0;
        final stepName = _getElementText(stepElement, 'm:stepName') ?? '';
        final stepRequired =
            _getElementText(stepElement, 'm:stepRequired')?.toLowerCase() ==
            'true';

        visitSteps.add({
          'stepCode': stepCode,
          'stepName': stepName,
          'stepRequired': stepRequired,
        });
      }
      if (kDebugMode) {
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
            'editClientCoordinates': editClientCoordinates,
            'clientZoneAccess': clientZoneAccess,
            'locationUpdateInterval': locationUpdateInterval,
          },
          'visitSteps': visitSteps,
        });
      }
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
          'editClientCoordinates': editClientCoordinates,
          'clientZoneAccess': clientZoneAccess,
          'locationUpdateInterval': locationUpdateInterval,
        },
        'visitSteps': visitSteps,
      };
    } catch (e) {
      throw Exception('Agent ruxsatlarini olishda xatolik: $e');
    }
  }

  /// Get planned route list for a user
  Future<List<Map<String, dynamic>>> getPlannedRouteList({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getPlannedRouteList>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:getPlannedRouteList>
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
      final returnElement = document.findAllElements('m:return').firstOrNull;

      if (returnElement == null) {
        // Empty response - return empty list
        return [];
      }

      // Parse row elements
      final rowElements = returnElement.findAllElements('m:row');
      final routes = <Map<String, dynamic>>[];

      for (final row in rowElements) {
        final route = {
          'codeWeekday':
              int.tryParse(_getElementText(row, 'm:codeWeekday') ?? '0') ?? 0,
          'weekDay': _getElementText(row, 'm:WeekDay') ?? '',
          'codeClient': _getElementText(row, 'm:CodeClient') ?? '',
          'clientName': _getElementText(row, 'm:ClientName') ?? '',
        };
        routes.add(route);
      }

      return routes;
    } catch (e) {
      throw Exception(
        'Rejalashtirilgan marshrutlar ro\'yxatini olishda xatolik: $e',
      );
    }
  }

  /// Get map tokens (Yandex and Google) from server
  /// Returns a map containing yandexToken and googleToken
  /// If tokens are not set on server, returns empty strings
  Future<Map<String, String>> getMapTokens() async {
    final soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getMapTokens>
         
      </sam:getMapTokens>
   </soap:Body>
</soap:Envelope>
''';

    try {
      if (kDebugMode) {
        //print('SOAP API: Requesting map tokens for user: $userCode');
      }

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

      if (kDebugMode) {
        print('SOAP API: Map tokens response received');
      }

      final document = XmlDocument.parse(response.data);
      final returnElement = document.findAllElements('m:return').first;

      // Parse tokens from response
      final yandexToken = _getElementText(returnElement, 'm:yandexToken') ?? '';
      final googleToken = _getElementText(returnElement, 'm:googleToken') ?? '';

      final tokens = {'yandexToken': yandexToken, 'googleToken': googleToken};

      if (kDebugMode) {
        print(
          'SOAP API: Retrieved map tokens - Yandex: ${yandexToken.isNotEmpty ? 'Present' : 'Empty'}, Google: ${googleToken.isNotEmpty ? 'Present' : 'Empty'}',
        );
      }

      return tokens;
    } catch (e) {
      if (kDebugMode) {
        print('SOAP API: Error retrieving map tokens: $e');
      }
      throw Exception('Xarita tokenlarini olishda xatolik: $e');
    }
  }

  /// Update client coordinates
  /// This method sends updated coordinates to the server for a specific client
  /// Returns success message or throws exception on failure
  /// Uses setClientLocation SOAP method with new parameter structure
  Future<String> updateClientCoordinates({
    required String userCode,
    required String clientCode,
    required double latitude,
    required double longitude,
  }) async {
    // Validate input parameters
    if (userCode.isEmpty) {
      throw ArgumentError('UserCode cannot be empty');
    }
    if (clientCode.isEmpty) {
      throw ArgumentError('ClientCode cannot be empty');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90 degrees');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180 degrees');
    }

    final soapEnvelope =
        '''
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
           <soap:Header/>
           <soap:Body>
              <sam:setClientLocation>
                 <sam:clientCode>$clientCode</sam:clientCode>
                 <sam:Longitude>$longitude</sam:Longitude>
                 <sam:Latitude>$latitude</sam:Latitude>
              </sam:setClientLocation>
           </soap:Body>
        </soap:Envelope>
        ''';

    try {
      if (kDebugMode) {
        print(
          'SOAP API: Updating client coordinates for client $clientCode: lat=$latitude, lng=$longitude',
        );
      }

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
      final returnElement = document.findAllElements('m:return').firstOrNull;

      // Check if return element is empty (client not found or write error)
      if (returnElement == null || returnElement.children.isEmpty) {
        if (kDebugMode) {
          print(
            'SOAP API: Client coordinates update failed - empty return element (client not found or write error)',
          );
        }
        throw Exception(
          'Mijoz topilmadi yoki koordinatalarni yozishda xatolik yuz berdi',
        );
      }

      // Parse successful response
      final responseClientCode = _getElementText(returnElement, 'm:clientCode');
      final responseLongitude = _getElementText(returnElement, 'm:Longitude');
      final responseLatitude = _getElementText(returnElement, 'm:Latitude');

      if (responseClientCode == null ||
          responseLongitude == null ||
          responseLatitude == null) {
        if (kDebugMode) {
          print(
            'SOAP API: Client coordinates update failed - missing response data',
          );
        }
        throw Exception('Server javobi to\'liq emas');
      }

      if (kDebugMode) {
        print(
          'SOAP API: Client coordinates update successful: client=$responseClientCode, lat=$responseLatitude, lng=$responseLongitude',
        );
      }

      return 'Muvaffaqiyatli yangilandi';
    } catch (e) {
      if (kDebugMode) {
        print('SOAP API: Error updating client coordinates: $e');
      }
      throw Exception('Mijoz kordinatalarini yangilashda xatolik: $e');
    }
  }

  /// Get order details
  Future<OrderDetail> getOrderDetails({
    required String numberOrder,
    required String orderDate1,
    required String orderDate2,
  }) async {
    final soapEnvelope =
        '''
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
      final credit =
          _getElementText(returnElement, 'm:Credit')?.toLowerCase() == 'true';
      final codePrice = _getElementText(returnElement, 'm:CodePrice') ?? '';
      final dateOrderStr = _getElementText(returnElement, 'm:DateOrder') ?? '';
      final dateOrder = DateTime.parse(dateOrderStr);
      final codeSklad = _getElementText(returnElement, 'm:CodeSklad') ?? '';
      final commentSupervisor = _getElementText(
        returnElement,
        'm:CommentSupervisor',
      );
      final commentForwarder = _getElementText(
        returnElement,
        'm:CommentForwarder',
      );
      final commentAgent = _getElementText(returnElement, 'm:CommentAgent');
      final shippingDateStr =
          _getElementText(returnElement, 'm:ShippingDate') ?? '';
      final shippingDate = DateTime.parse(shippingDateStr);
      final orderType =
          int.tryParse(_getElementText(returnElement, 'm:OrderType') ?? '0') ??
          0;
      final codeOrg = _getElementText(returnElement, 'm:CodeOrg') ?? '';

      // Parse product rows - only add products with non-zero price
      final productRows = <OrderDetailProduct>[];
      final productRowsElement = returnElement
          .findAllElements('m:ProductRows')
          .firstOrNull;
      if (productRowsElement != null) {
        final rowsElements = productRowsElement.findAllElements('m:Rows');
        for (final row in rowsElements) {
          final price =
              double.tryParse(_getElementText(row, 'm:Price') ?? '0') ?? 0.0;
          // Skip products with negative price only - allow zero price products
          if (price < 0) {
            if (kDebugMode) {
              print(
                'SOAP API: Skipping product with negative price: ${_getElementText(row, 'm:CodeProduct')}',
              );
            }
            continue;
          }
          // Get price type from product row or use order's price type as default
          final productPriceTypeCode =
              _getElementText(row, 'm:CodePrice') ?? codePrice;
          final productPriceTypeName =
              _getElementText(row, 'm:NamePrice') ?? '';
          final product = OrderDetailProduct(
            codeProduct: _getElementText(row, 'm:CodeProduct') ?? '',
            nameProduct: _getElementText(row, 'm:NameProduct') ?? '',
            amount: int.tryParse(_getElementText(row, 'm:Amount') ?? '0') ?? 0,
            price: price,
            total:
                double.tryParse(_getElementText(row, 'm:Total') ?? '0') ?? 0.0,
            discountRate:
                double.tryParse(
                  _getElementText(row, 'm:DiscountRate') ?? '0',
                ) ??
                0.0,
            weight:
                double.tryParse(_getElementText(row, 'm:Weight') ?? '0') ?? 0.0,
            capacity:
                double.tryParse(_getElementText(row, 'm:Capacity') ?? '0') ??
                0.0,
            priceTypeCode: productPriceTypeCode,
            priceTypeName: productPriceTypeName,
          );
          productRows.add(product);
        }
      }

      // Parse credit details list (payments)
      final creditDetailsList = <OrderPayment>[];
      final creditDetailsElement = returnElement
          .findAllElements('m:CreditDetailsList')
          .firstOrNull;
      if (creditDetailsElement != null) {
        final rowsElements = creditDetailsElement.findAllElements('m:Rows');
        for (final row in rowsElements) {
          final payment = OrderPayment(
            dateOfPayment: _getElementText(row, 'm:DateOfPayment') ?? '',
            total:
                double.tryParse(_getElementText(row, 'm:Total') ?? '0') ?? 0.0,
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

  /// Send create order to server via SetOrder API
  /// This method sends a local order to the server for processing
  Future<Map<String, dynamic>> setOrder({required CreateOrder order}) async {
    // Build the SOAP envelope based on the provided XML structure
    final productsXml = order.products
        .map(
          (product) =>
              '''
      <sam:Rows>
         <sam:CodeSklad>${product.codeSklad}</sam:CodeSklad>
         <sam:CodeProduct>${product.codeProduct}</sam:CodeProduct>
         <sam:Amount>${product.amount}</sam:Amount>
         <sam:Price>${product.price}</sam:Price>
         <sam:Total>${product.total}</sam:Total>
         <sam:Weight>${product.weight}</sam:Weight>
         <sam:Capacity>${product.capacity}</sam:Capacity>
         <sam:PaymentType>${product.paymentType}</sam:PaymentType>
         <sam:DiscountSum>${product.discountSum}</sam:DiscountSum>
         <sam:DiscountRate>${product.discountRate}</sam:DiscountRate>
         <sam:GiftAmount>${product.giftAmount}</sam:GiftAmount>
      </sam:Rows>
    ''',
        )
        .join();

    final competitiveIntelligenceXml = order.competitiveIntelligence
        .map(
          (ci) =>
              '''
      <sam:Rows>
         <sam:Competitor>${ci.competitor}</sam:Competitor>
         <sam:Product>${ci.product}</sam:Product>
         <sam:Price>${ci.price}</sam:Price>
      </sam:Rows>
    ''',
        )
        .join();

    // Generate XML for credit details with dates formatted as YYYYMMDD strings
    // DateOfPayment is formatted using _formatDateForApi to match server API requirements
    final creditDetailsXml = order.creditDetails
        .map(
          (cd) =>
              '''
      <sam:Rows>
         <!-- DateOfPayment formatted as YYYYMMDD string (e.g., "20251203") as required by server API -->
         <sam:DateOfPayment>${_formatDateForApi(cd.dateOfPayment)}</sam:DateOfPayment>
         <sam:Total>${cd.total}</sam:Total>
      </sam:Rows>
    ''',
        )
        .join();

    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:SetOrder>
         <sam:CodeAgent>${order.codeAgent}</sam:CodeAgent>
         <sam:CodeClient>${order.codeClient}</sam:CodeClient>
         <sam:CodePrice>${order.codePrice}</sam:CodePrice>
         <sam:Payment>${order.payment}</sam:Payment>
         <sam:ProductsList>
            $productsXml
         </sam:ProductsList>
         <sam:ShippingDate>${_formatDateForApi(order.shippingDate)}</sam:ShippingDate>
         <sam:CommentSupervisor>${order.commentSupervisor ?? ''}</sam:CommentSupervisor>
         <sam:CommentForwarder>${order.commentForwarder ?? ''}</sam:CommentForwarder>
         <sam:Comment>${order.comment ?? ''}</sam:Comment>
         <sam:CompetitiveIintelligenceList>
            $competitiveIntelligenceXml
         </sam:CompetitiveIintelligenceList>
         <sam:CreateDate>${_formatDateForApi(order.createDate)}</sam:CreateDate>
         <sam:Longitude>${order.longitude}</sam:Longitude>
         <sam:Latitude>${order.latitude}</sam:Latitude>
         <sam:Weight>${order.weight}</sam:Weight>
         <sam:Capacity>${order.capacity}</sam:Capacity>
         <sam:Credit>${order.credit ? 'true' : 'false'}</sam:Credit>
         <sam:CodeProject>${order.codeProject}</sam:CodeProject>
         <sam:CreditDetails>
            $creditDetailsXml
         </sam:CreditDetails>
         <sam:OrderType>${order.orderType}</sam:OrderType>
         <sam:CodeOrg>${order.codeOrg}</sam:CodeOrg>
         <sam:CodeSklad>${order.codeSklad}</sam:CodeSklad>
         <sam:CodeContract>${order.codeContract ?? ''}</sam:CodeContract>

      </sam:SetOrder>
   </soap:Body>
</soap:Envelope>
''';

    try {
      if (kDebugMode) {
        print('SOAP API: Sending SetOrder request for order ${order.id}');
        print('SOAP API: SetOrder field values:');
        print(
          '  codeAgent: "${order.codeAgent}" (length: ${order.codeAgent.length})',
        );
        print(
          '  codeClient: "${order.codeClient}" (length: ${order.codeClient.length})',
        );
        print(
          '  codePrice: "${order.codePrice}" (length: ${order.codePrice.length})',
        );
        print(
          '  payment: "${order.payment}" (length: ${order.payment.length})',
        );
        print(
          '  codeProject: "${order.codeProject}" (length: ${order.codeProject.length})',
        );
        print('  orderType: ${order.orderType}');
        print(
          '  codeOrg: "${order.codeOrg}" (length: ${order.codeOrg.length})',
        );
        print(
          '  codeSklad: "${order.codeSklad}" (length: ${order.codeSklad.length})',
        );
        print(
          '  codeContract: "${order.codeContract ?? ''}" (length: ${(order.codeContract ?? '').length})',
        );
        print('  hasPromo: ${order.hasPromo}');
        print('  products count: ${order.products.length}');
      }

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
      final returnElement = document.findAllElements('m:return').firstOrNull;

      if (returnElement == null) {
        throw Exception('Server javobi bo\'sh');
      }

      // Parse response fields as per API specification
      final code =
          int.tryParse(_getElementText(returnElement, 'm:Code') ?? '0') ?? 0;
      final message = _getElementText(returnElement, 'm:Message') ?? '';
      final codeOrder = _getElementText(returnElement, 'm:CodeOrder') ?? '';
      final rows = _getElementText(returnElement, 'm:Rows') ?? '';

      if (kDebugMode) {
        print(
          'SOAP API: SetOrder response - Code: $code, Message: $message, CodeOrder: $codeOrder',
        );
      }

      return {
        'success': code == 0, // Code 0 indicates success
        'code': code,
        'message': message,
        'codeOrder': codeOrder,
        'rows': rows,
        'orderId': order.id,
      };
    } catch (e) {
      if (kDebugMode) {
        print('SOAP API: Error sending SetOrder request: $e');
      }
      throw Exception('Buyurtmani serverga yuborishda xatolik: $e');
    }
  }

  /// Get organizations by user code
  /// This method retrieves organizations associated with a specific user code
  /// Returns a list of UserOrganization objects
  Future<List<UserOrganization>> getOrganizationsByUserCode({
    required String userCode,
  }) async {
    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetOrganizationByUserCode>
         <sam:CodeUser>$userCode</sam:CodeUser>
      </sam:GetOrganizationByUserCode>
   </soap:Body>
</soap:Envelope>
''';

    try {
      if (kDebugMode) {
        print('SOAP API: Requesting organizations for user: $userCode');
      }

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

      if (kDebugMode) {
        print('SOAP API: Organizations response received');
      }

      final document = XmlDocument.parse(response.data);
      final returnElement = document.findAllElements('m:return').first;

      // Parse organizations from response
      final organizationElements = returnElement.findAllElements(
        'm:Organizations',
      );
      final organizations = <UserOrganization>[];

      for (final orgElement in organizationElements) {
        final code = _getElementText(orgElement, 'm:Code');
        final name = _getElementText(orgElement, 'm:Name');

        if (code != null &&
            code.isNotEmpty &&
            name != null &&
            name.isNotEmpty) {
          organizations.add(
            UserOrganization(
              code: code,
              name: name,
              userCode: userCode,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      if (kDebugMode) {
        print(
          'SOAP API: Successfully parsed ${organizations.length} organizations for user $userCode',
        );
      }

      return organizations;
    } catch (e) {
      if (kDebugMode) {
        print(
          'SOAP API: Error retrieving organizations for user $userCode: $e',
        );
      }
      throw Exception('Foydalanuvchi tashkilotlarini olishda xatolik: $e');
    }
  }

  // ===========================================================================
  // DEVICE & ACCOUNT ACCESS CHECK
  // ===========================================================================

  /// Check device and account access on startup
  ///
  /// Bu metod ilova ishga tushganda qurilma va account bog'liqligini tekshiradi.
  /// Server ALLOW yoki BLOCK qaytaradi.
  ///
  /// Parameters:
  /// - [userId] - Foydalanuvchi identifikatori (userCode)
  /// - [localUuid] - Local UUID (flutter_secure_storage dan)
  /// - [appDeviceId] - Qurilma identifikatori (androidId/identifierForVendor)
  /// - [platform] - Platforma (Android/iOS)
  /// - [brand] - Brend (Samsung, Xiaomi, Apple)
  /// - [model] - Model (Galaxy S21, iPhone 13)
  /// - [osVersion] - OS versiyasi
  /// - [sdk] - SDK versiyasi (faqat Android)
  /// - [appVersion] - Ilova versiyasi
  /// - [deviceFingerprint] - Device fingerprint (Android)
  Future<Map<String, dynamic>> checkAccessOnStartup({
    required String userId,
    required String localUuid,
    String? appDeviceId,
    required String platform,
    required String brand,
    required String model,
    required String osVersion,
    String? sdk,
    required String appVersion,
    String? deviceFingerprint,
  }) async {
    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:CheckAccessOnStartup>
         <sam:UserId>$userId</sam:UserId>
         <sam:LocalUUID>$localUuid</sam:LocalUUID>
         <sam:AppDeviceId>${appDeviceId ?? ''}</sam:AppDeviceId>
         <sam:Platform>$platform</sam:Platform>
         <sam:Brand>$brand</sam:Brand>
         <sam:Model>$model</sam:Model>
         <sam:OSVersion>$osVersion</sam:OSVersion>
         <sam:SDK>${sdk ?? ''}</sam:SDK>
         <sam:AppVersion>$appVersion</sam:AppVersion>
         <sam:DeviceFingerprint>${deviceFingerprint ?? ''}</sam:DeviceFingerprint>
      </sam:CheckAccessOnStartup>
   </soap:Body>
</soap:Envelope>
''';

    try {
      if (kDebugMode) {
        print(
          'SOAP API: CheckAccessOnStartup for user: $userId, platform: $platform',
        );
      }

      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
          validateStatus: (status) => true,
        ),
      );

      if (kDebugMode) {
        print(
          'SOAP API: CheckAccessOnStartup response received, statusCode: ${response.statusCode}',
        );
      }

      final responseData = response.data?.toString() ?? '';

      // Fault tekshirish - statusCode qanday bo'lishidan qat'i nazar
      if (responseData.contains('Fault') || response.statusCode != 200) {
        String? soapFaultMessage;
        try {
          if (responseData.contains('Fault')) {
            final faultDoc = XmlDocument.parse(responseData);
            soapFaultMessage =
                faultDoc
                    .findAllElements('soap:Text')
                    .firstOrNull
                    ?.innerText
                    .trim() ??
                faultDoc
                    .findAllElements('faultstring')
                    .firstOrNull
                    ?.innerText
                    .trim();
          }
        } catch (_) {}

        if (kDebugMode) {
          print(
            'SOAP API: CheckAccessOnStartup server error ${response.statusCode}: $soapFaultMessage',
          );
        }

        return {
          'status': 'ALLOW',
          'riskScore': 0,
          'reason': null,
          'message':
              soapFaultMessage ?? 'Server xatosi: ${response.statusCode}',
        };
      }

      final document = XmlDocument.parse(responseData);
      final returnElement = document.findAllElements('m:return').firstOrNull;

      if (returnElement == null) {
        // Agar server javob bermasa, default ALLOW qaytarish
        if (kDebugMode) {
          print('SOAP API: No return element found, defaulting to ALLOW');
        }
        return {
          'status': 'ALLOW',
          'riskScore': 0,
          'reason': null,
          'message': null,
        };
      }

      // Parse response
      final status = _getElementText(returnElement, 'm:Status') ?? 'ALLOW';
      final riskScoreText = _getElementText(returnElement, 'm:RiskScore');
      final reason = _getElementText(returnElement, 'm:Reason');
      final message = _getElementText(returnElement, 'm:Message');

      if (kDebugMode) {
        print(
          'SOAP API: CheckAccessOnStartup result - Status: $status, RiskScore: $riskScoreText, Reason: $reason',
        );
      }

      return {
        'status': status,
        'riskScore': riskScoreText != null ? int.tryParse(riskScoreText) : null,
        'reason': reason,
        'message': message,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('SOAP API: DioException in CheckAccessOnStartup: ${e.message}');
        print('SOAP API: Response: ${e.response?.data}');
      }

      // Server 500 xatosi - metod mavjud emas yoki server xatosi
      // Bu holatda foydalanuvchini bloklash emas, davom etish kerak
      if (e.response?.statusCode == 500) {
        if (kDebugMode) {
          print(
            'SOAP API: Server error 500, defaulting to ALLOW (method may not exist on server)',
          );
        }
        return {
          'status': 'ALLOW',
          'riskScore': 0,
          'reason': null,
          'message': 'Server xatosi - tekshiruv o\'tkazib yuborildi',
        };
      }

      // Tarmoq xatosi (connection timeout, no internet)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        if (kDebugMode) {
          print(
            'SOAP API: Network error, defaulting to ALLOW for offline mode',
          );
        }
        return {
          'status': 'ALLOW',
          'riskScore': 0,
          'reason': null,
          'message': 'Offline rejim - tekshiruv o\'tkazib yuborildi',
        };
      }

      // Boshqa xatolar uchun ham ALLOW qaytarish
      // Foydalanuvchini bloklash emas
      if (kDebugMode) {
        print('SOAP API: Other DioException, defaulting to ALLOW');
      }
      return {
        'status': 'ALLOW',
        'riskScore': 0,
        'reason': null,
        'message': 'Xatolik - tekshiruv o\'tkazib yuborildi',
      };
    } catch (e) {
      if (kDebugMode) {
        print('SOAP API: Error in CheckAccessOnStartup: $e');
      }
      // Har qanday xatolikda foydalanuvchini bloklash emas
      return {
        'status': 'ALLOW',
        'riskScore': 0,
        'reason': null,
        'message': 'Xatolik - tekshiruv o\'tkazib yuborildi',
      };
    }
  }

  /// Get contract types from server
  Future<List<ContractType>> getTypeOfContract() async {
    if (kDebugMode) print('SOAP API: getTypeOfContract called');

    const soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetTypeOfContract/>
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
          validateStatus: (status) => true,
        ),
      );

      final responseData = response.data?.toString() ?? '';

      if (responseData.contains('Fault') || response.statusCode != 200) {
        if (kDebugMode)
          print('SOAP API: getTypeOfContract error ${response.statusCode}');
        return [];
      }

      final document = XmlDocument.parse(responseData);

      // Parse contract types similar to other methods - find m:return first, then m:Rows
      final returnElement = document.findAllElements('m:return').firstOrNull;
      if (returnElement == null) {
        if (kDebugMode)
          print('SOAP API: getTypeOfContract - no return element found');
        return [];
      }

      final rowElements = returnElement.findAllElements('m:Rows');
      if (kDebugMode)
        print(
          'SOAP API: getTypeOfContract found ${rowElements.length} contract types',
        );

      return rowElements
          .map(
            (row) => ContractType(
              code: _getElementText(row, 'm:Code') ?? '',
              name: _getElementText(row, 'm:Name') ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('SOAP API: getTypeOfContract error: $e');
      return [];
    }
  }

  /// Get cities district contracting data
  Future<List<DistrictContracting>> getCitiesDistrictContracting({
    required String codeUser,
    required String codeProject,
  }) async {
    if (kDebugMode)
      print(
        'SOAP API: getCitiesDistrictContracting for user: $codeUser, project: $codeProject',
      );

    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:PS_GetCitiesDistrictContracting>
         <sam:CodeUser>$codeUser</sam:CodeUser>
         <sam:CodeProject>$codeProject</sam:CodeProject>
      </sam:PS_GetCitiesDistrictContracting>
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
      final returnElement = document.findAllElements('m:return').firstOrNull;

      if (returnElement == null) {
        if (kDebugMode)
          print('SOAP API: getCitiesDistrictContracting no return element');
        return [];
      }

      final rowElements = returnElement.findAllElements('m:Rows');
      if (kDebugMode)
        print(
          'SOAP API: getCitiesDistrictContracting found ${rowElements.length} districts',
        );

      return rowElements
          .map(
            (row) => DistrictContracting(
              codeDistrict: _getElementText(row, 'm:CodeDistrict') ?? '',
              nameDistrict: _getElementText(row, 'm:NameDistrict') ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('SOAP API: getCitiesDistrictContracting error: $e');
      return [];
    }
  }

  /// Create a new contract
  Future<Map<String, dynamic>> setContract({
    required String dateOfContract,
    required String codeUser,
    required String codeClient,
    required double sumOfContract,
    String? termReference,
    String? termCertificate,
    String? numbReference,
    String? numbCertificate,
    required String typeOfContract,
    String? numbPassport,
    String? termPassport,
    bool certificateUnlimited = false,
    String? psCodeProject,
    String? psCodeDistrict,
    String? psNameDistrict,
  }) async {
    if (kDebugMode) print('SOAP API: setContract for client: $codeClient');

    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:SetContract>
         <sam:DateOfContract>$dateOfContract</sam:DateOfContract>
         <sam:CodeUser>$codeUser</sam:CodeUser>
         <sam:CodeClient>$codeClient</sam:CodeClient>
         <sam:SumOfContract>$sumOfContract</sam:SumOfContract>
         <sam:TermReference>${termReference ?? ''}</sam:TermReference>
         <sam:TermCertificate>${termCertificate ?? ''}</sam:TermCertificate>
         <sam:NumbReference>${numbReference ?? ''}</sam:NumbReference>
         <sam:NumbCertificate>${numbCertificate ?? ''}</sam:NumbCertificate>
         <sam:TypeOfContract>$typeOfContract</sam:TypeOfContract>
         <sam:NumbPassport>${numbPassport ?? ''}</sam:NumbPassport>
         <sam:TermPassport>${termPassport ?? ''}</sam:TermPassport>
         <sam:CertificateUnlimited>${certificateUnlimited ? 1 : 0}</sam:CertificateUnlimited>
         <sam:PS_CodeProject>${psCodeProject ?? ''}</sam:PS_CodeProject>
         <sam:PS_CodeDistrict>${psCodeDistrict ?? ''}</sam:PS_CodeDistrict>
         <sam:PS_NameDistrict>${psNameDistrict ?? ''}</sam:PS_NameDistrict>
      </sam:SetContract>
   </soap:Body>
</soap:Envelope>
''';

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════════');
      print('SOAP REQUEST - SetContract');
      print('═══════════════════════════════════════════════════════════════');
      print(soapEnvelope);
      print('═══════════════════════════════════════════════════════════════');
    }

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
          validateStatus: (status) => true,
        ),
      );

      final responseData = response.data?.toString() ?? '';

      if (responseData.contains('Fault') || response.statusCode != 200) {
        String? faultMsg;
        try {
          if (responseData.contains('Fault')) {
            final doc = XmlDocument.parse(responseData);
            faultMsg =
                doc
                    .findAllElements('soap:Text')
                    .firstOrNull
                    ?.innerText
                    .trim() ??
                doc
                    .findAllElements('faultstring')
                    .firstOrNull
                    ?.innerText
                    .trim();
          }
        } catch (_) {}
        return {
          'success': false,
          'message': faultMsg ?? 'Server xatosi: ${response.statusCode}',
        };
      }

      final document = XmlDocument.parse(responseData);
      final returnElement = document.findAllElements('m:return').firstOrNull;
      final contractCode = returnElement != null
          ? (_getElementText(returnElement, 'm:CodeContract') ??
                _getElementText(returnElement, 'm:Code') ??
                returnElement.innerText.trim())
          : null;

      return {
        'success': true,
        'message': 'Shartnoma yaratildi',
        'contractCode': contractCode,
      };
    } catch (e) {
      if (kDebugMode) print('SOAP API: setContract error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a new client (trading point)
  /// Based on SetClient SOAP method
  /// Returns success status, message, and client code if successful
  Future<Map<String, dynamic>> setClient({
    required String name,
    required String signboard,
    required String inn,
    required String tradePointType,
    required String contactPerson,
    required String contactPersonPhone,
    required String address,
    required String addressDelivery,
    required String referencePoint,
    required String responsiblePersonPhone,
    required double longitude,
    required double latitude,
    required String codeUser,
    required String codeRegion,
    String? director,
    String? mfo,
    String? bankAccount,
  }) async {
    if (kDebugMode) print('SOAP API: setClient - Creating new client: $name');

    final soapEnvelope =
        '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:SetClient>
         <sam:Name>$name</sam:Name>
         <sam:Signboard>$signboard</sam:Signboard>
         <sam:INN>$inn</sam:INN>
         <sam:TradePointType>$tradePointType</sam:TradePointType>
         <sam:ContactPerson>$contactPerson</sam:ContactPerson>
         <sam:ContactPersonPhone>$contactPersonPhone</sam:ContactPersonPhone>
         <sam:Adress>$address</sam:Adress>
         <sam:AdressDelivery>$addressDelivery</sam:AdressDelivery>
         <sam:ReferencePoint>$referencePoint</sam:ReferencePoint>
         <sam:ResponsiblePersonPhone>$responsiblePersonPhone</sam:ResponsiblePersonPhone>
         <sam:Longitude>$longitude</sam:Longitude>
         <sam:Latitude>$latitude</sam:Latitude>
         <sam:CodeUser>$codeUser</sam:CodeUser>
         <sam:CodeRegion>$codeRegion</sam:CodeRegion>
         <sam:Director>${director ?? ''}</sam:Director>
         <sam:MFO>${mfo ?? ''}</sam:MFO>
         <sam:BankAccount>${bankAccount ?? ''}</sam:BankAccount>
      </sam:SetClient>
   </soap:Body>
</soap:Envelope>
''';

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════════');
      print('SOAP REQUEST - SetClient');
      print('═══════════════════════════════════════════════════════════════');
      print(soapEnvelope);
      print('═══════════════════════════════════════════════════════════════');
    }

    try {
      final response = await _dio.post(
        _baseUrl,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
          validateStatus: (status) => true,
        ),
      );

      final responseData = response.data?.toString() ?? '';

      if (kDebugMode) {
        print(
          '═══════════════════════════════════════════════════════════════',
        );
        print('SOAP RESPONSE - SetClient');
        print(
          '═══════════════════════════════════════════════════════════════',
        );
        print(responseData);
        print(
          '═══════════════════════════════════════════════════════════════',
        );
      }

      if (responseData.contains('Fault') || response.statusCode != 200) {
        String? faultMsg;
        try {
          if (responseData.contains('Fault')) {
            final doc = XmlDocument.parse(responseData);
            faultMsg =
                doc
                    .findAllElements('soap:Text')
                    .firstOrNull
                    ?.innerText
                    .trim() ??
                doc
                    .findAllElements('faultstring')
                    .firstOrNull
                    ?.innerText
                    .trim() ??
                doc.findAllElements('m:Text').firstOrNull?.innerText.trim();
          }
        } catch (_) {}
        return {
          'success': false,
          'message': faultMsg ?? 'Server xatosi: ${response.statusCode}',
        };
      }

      final document = XmlDocument.parse(responseData);
      final returnElement = document.findAllElements('m:return').firstOrNull;

      // Try to extract client code from response
      String? clientCode;
      if (returnElement != null) {
        clientCode =
            _getElementText(returnElement, 'm:CodeClient') ??
            _getElementText(returnElement, 'm:Code') ??
            returnElement.innerText.trim();
      }

      return {
        'success': true,
        'message': 'Mijoz muvaffaqiyatli yaratildi',
        'clientCode': clientCode,
      };
    } catch (e) {
      if (kDebugMode) print('SOAP API: setClient error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get server time with automatic URL failover for time verification.
  ///
  /// Tries URLs in priority order: domain → IP1 → IP2.
  /// Uses short timeouts for fast failover when servers are unavailable.
  ///
  /// @returns DateTime from server
  /// @throws ServerTimeException if all servers fail
  Future<DateTime> getServerTime() async {
    const soapEnvelope = '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetServerTime/>
   </soap:Body>
</soap:Envelope>
''';

    final urls = _serverService.allUrls;
    String? lastError;

    // Try each URL with short timeout for fast failover
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];

      try {
        if (kDebugMode) {
          print('[SoapApiService] Getting server time from URL[$i]: $url');
        }

        final response = await _dio.post(
          url,
          data: soapEnvelope,
          options: Options(
            headers: {
              'Content-Type': 'application/soap+xml; charset=utf-8',
              'SOAPAction': '',
            },
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        final responseData = response.data?.toString() ?? '';

        // Check for SOAP Fault
        if (responseData.contains('Fault') || response.statusCode != 200) {
          lastError =
              _extractSoapFault(responseData) ??
              'Server time request failed with status: ${response.statusCode}';
          if (kDebugMode)
            print('[SoapApiService] SOAP Fault from $url: $lastError');
          continue;
        }

        // Parse server time from response
        final serverTime = _parseServerTimeResponse(responseData);

        // Update working URL on success
        await _serverService.setWorkingUrl(url);

        if (kDebugMode) {
          print(
            '[SoapApiService] Server time obtained: $serverTime (from URL[$i])',
          );
        }

        return serverTime;
      } on DioException catch (e) {
        lastError = _getErrorMessage(e);
        if (kDebugMode) {
          print('[SoapApiService] URL[$i] failed: $lastError');
        }
        continue;
      } on FormatException catch (e) {
        lastError = 'Parse error: ${e.message}';
        if (kDebugMode)
          print('[SoapApiService] URL[$i] parse error: $lastError');
        continue;
      } catch (e) {
        lastError = e.toString();
        if (kDebugMode) print('[SoapApiService] URL[$i] error: $lastError');
        continue;
      }
    }

    // All URLs failed
    throw ServerTimeException(
      'All servers unavailable. Last error: ${lastError ?? "Unknown"}',
    );
  }

  /// Extracts SOAP fault message from response XML.
  String? _extractSoapFault(String responseData) {
    if (!responseData.contains('Fault')) return null;
    try {
      final doc = XmlDocument.parse(responseData);
      return doc.findAllElements('soap:Text').firstOrNull?.innerText.trim() ??
          doc.findAllElements('faultstring').firstOrNull?.innerText.trim();
    } catch (_) {
      return null;
    }
  }

  /// Parses server time from SOAP response XML.
  DateTime _parseServerTimeResponse(String responseData) {
    final document = XmlDocument.parse(responseData);
    final dateTimeElement = document.findAllElements('m:DateTime').firstOrNull;

    if (dateTimeElement == null) {
      throw const FormatException('DateTime element not found in response');
    }

    return DateTime.parse(dateTimeElement.innerText.trim());
  }
}

/// Exception thrown when server time retrieval fails
class ServerTimeException implements Exception {
  final String message;

  const ServerTimeException(this.message);

  @override
  String toString() => 'ServerTimeException: $message';
}
