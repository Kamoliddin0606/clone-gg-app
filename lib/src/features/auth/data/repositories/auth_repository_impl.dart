import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/user_model.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:xml/xml.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;

  AuthRepositoryImpl({required this.apiService});

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    const methodName = 'GetUser';
    const soapAction = 'http://www.sample-package.org#MobileAgents:GetUser';
    
    final soapEnvelope = XmlBuilder();
    soapEnvelope.processing('xml', 'version="1.0" encoding="utf-8"');
    soapEnvelope.element('soap:Envelope',
        attributes: {
          'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:xsd': 'http://www.w3.org/2001/XMLSchema',
          'xmlns:soap': 'http://schemas.xmlsoap.org/soap/envelope/',
        },
        nest: () {
          soapEnvelope.element('soap:Body', nest: () {
            soapEnvelope.element(methodName,
                attributes: {'xmlns': 'http://www.sample-package.org'},
                nest: () {
                  soapEnvelope.element('Login', nest: username);
                  soapEnvelope.element('Password', nest: password);
                });
          });
        });

    final soapRequest = soapEnvelope.buildDocument().toXmlString();
    print("SOAP Request: $soapRequest");

    try {
      final soapResponseString = await apiService.performSoapRequest(soapRequest);
      print("SOAP Response: $soapResponseString");

      final document = XmlDocument.parse(soapResponseString);
      final returnElement = document.findAllElements('m:return').first;

      final codeError = returnElement.findElements('m:CodeError').first.innerText;

      if (codeError == '1') {
        final soapResponseMap = {
          'Code': returnElement.findElements('m:Code').first.innerText,
          'Name': returnElement.findElements('m:Name').first.innerText,
          'Type': returnElement.findElements('m:Type').first.innerText,
          'CodeProject': returnElement.findElements('m:CodeProject').first.innerText,
          'CodeSklad': returnElement.findElements('m:CodeSklad').first.innerText,
        };
        return UserModel.fromSoap(soapResponseMap);
      } else {
        final message = returnElement.findElements('m:Message').first.innerText;
        throw Exception(message);
      }
    } catch (e) {
      print("Error in AuthRepositoryImpl: $e");
      rethrow;
    }
  }
}