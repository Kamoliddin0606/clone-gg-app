import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';

class SoapApiService {
  final Dio _dio;
  static const String _baseUrl = 'http://109.94.175.104:5443/EVYAP_UT/EVYAP_UT.1cws';

  SoapApiService(this._dio);

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