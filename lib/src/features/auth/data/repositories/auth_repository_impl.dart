import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/user_model.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/config/feature_flags.dart';
import 'package:gloria_marketing_flutter/src/core/utils/version_utils.dart';
import 'package:xml/xml.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;
  final ServerService serverService;

  AuthRepositoryImpl({required this.apiService, required this.serverService});

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
    String? appVersion,
  }) async {
    // Use GetUserEx if feature flag is enabled, otherwise use legacy GetUser
    final methodName = FeatureFlags.useGetUserEx ? 'GetUserEx' : 'GetUser';
    
    // Get app version if using GetUserEx and version not provided
    String? versionFormatted;
    if (FeatureFlags.useGetUserEx) {
      if (appVersion != null) {
        // Use provided version
        versionFormatted = VersionUtils.toThreeDigitFormat(appVersion);
      } else {
        // Get version from package info
        versionFormatted = await VersionUtils.getAppVersionFormatted();
      }
      
      // Validate version format if strict validation is enabled
      if (FeatureFlags.strictVersionValidation && versionFormatted.length != 3) {
        throw FormatException('Version must be exactly 3 digits, got: $versionFormatted');
      }
      
      if (FeatureFlags.verboseAuthLogging && kDebugMode) {
        print('AuthRepository: Using GetUserEx with version: $versionFormatted');
      }
    }
    
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
                  
                  // Add version element for GetUserEx
                  if (FeatureFlags.useGetUserEx && versionFormatted != null) {
                    soapEnvelope.element('version', nest: versionFormatted);
                  }
                });
          });
        });

    final soapRequest = soapEnvelope.buildDocument().toXmlString();
    
    if (FeatureFlags.verboseAuthLogging && kDebugMode) {
      print('SOAP Request ($methodName):');
      print(soapRequest);
    }

    try {
      final soapResponseString = await apiService.performSoapRequest(soapRequest);
      if (kDebugMode) {
        //print("SOAP Response: $soapResponseString");
      }
      final document = XmlDocument.parse(soapResponseString);

      final returnElement = document.findAllElements('m:return').firstOrNull;

      if (returnElement == null) {
        throw Exception("Server response is missing the <m:return> element.");
      }

      final codeError = returnElement.findElements('m:CodeError').firstOrNull?.innerText;
      
      if (codeError == '1') {
        // Successful login
        return UserModel.fromSoap({
          'Code': returnElement.findElements('m:Code').first.innerText,
          'Name': returnElement.findElements('m:Name').first.innerText,
          'Type': returnElement.findElements('m:Type').first.innerText,
          'CodeProject': returnElement.findElements('m:CodeProject').first.innerText,
          'WarehouseCode': returnElement.findElements('m:CodeSklad').first.innerText,
          'TelegramID': returnElement.findElements('m:telegramID').firstOrNull?.innerText ?? '',
          'ChatID': returnElement.findElements('m:chatID').firstOrNull?.innerText ?? '',
          'TopicID': returnElement.findElements('m:topicID').firstOrNull?.innerText ?? '',
        }, username: username, baseUrl: serverService.baseUrl);
      } else {
        // Failed login
        final message = returnElement.findElements('m:Message').firstOrNull?.innerText;
        throw Exception(message ?? 'Unknown login error');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in AuthRepositoryImpl: $e");
      }
      // Re-throw the original exception to be caught by the BLoC
      rethrow;
    }
  }
}