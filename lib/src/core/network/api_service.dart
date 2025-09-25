import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  // TODO: Get base URL from a config file
  static const String _baseUrl = "http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws";

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(milliseconds: 5000),
            receiveTimeout: const Duration(milliseconds: 3000),
          ),
        ) {
    // TODO: Add interceptors for logging, authentication, etc.
    // _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  // Example GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // Example POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
  
  Future<String> performSoapRequest(String body) async {
    try {
      final response = await _dio.post(
        '', // SOAP endpoint is usually the base URL
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            // 'SOAPAction': soapAction, // Sometimes required
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      // Handle Dio-specific errors
      throw Exception('Network Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to perform SOAP request: $e');
    }
  }
}