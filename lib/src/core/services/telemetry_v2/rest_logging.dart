import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// REST/HTTP loglar uchun yagona helper.
///
/// `attachRestLogger(dio, tag)` — Dio instance'ga LogInterceptor qo'shadi
/// (faqat kDebugMode'da). HTTP request va response method/URL/headers/body
/// bilan terminalga chiqariladi.
///
/// `restLog(tag, msg)` — qo'lda chiqariladigan structured log (servis ichidan).
void attachRestLogger(Dio dio, String tag) {
  if (!kDebugMode) return;
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[$tag] $obj'),
    ),
  );
}

void restLog(String tag, String message) {
  if (kDebugMode) {
    debugPrint('[$tag] $message');
  }
}
