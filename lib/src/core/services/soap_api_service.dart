import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

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

  /// Get price types
  Future<List<PriceType>> getPriceTypes({
    required String userCode,
  }) async {
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

      final document = XmlDocument.parse(response.data);
      final priceTypeElements = document.findAllElements('m:PriceType');

      return priceTypeElements.map((priceType) => PriceType(
        code: _getElementText(priceType, 'm:Code') ?? '',
        name: _getElementText(priceType, 'm:Name') ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Narx turlarini olishda xatolik: $e');
    }
  }

  /// Get product prices by price type
  Future<List<ProductPrice>> getProductPrices({
    required String userCode,
  }) async {
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

      final document = XmlDocument.parse(response.data);
      final rowsElements = document.findAllElements('m:Rows');

      return rowsElements.map((row) => ProductPrice(
        priceTypeCode: _getElementText(row, 'm:CodeTypePrice') ?? '',
        productCode: _getElementText(row, 'm:CodeProduct') ?? '',
        price: double.tryParse(_getElementText(row, 'm:Price') ?? '0') ?? 0.0,
      )).toList();
    } catch (e) {
      throw Exception('Mahsulot narxlarini olishda xatolik: $e');
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

      print('[$timestamp] DEBUG API: Response status: ${response.statusCode}');
      print('[$timestamp] DEBUG API: Response data length: ${response.data.length}');

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
      throw Exception('Promosyon ma\'lumotlarini olishda xatolik: $e');
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
}