// Custom exceptions for API errors
class PaymentRequiredException implements Exception {
  final String message;
  PaymentRequiredException(this.message);

  @override
  String toString() => message;
}

class ServerUnavailableException implements Exception {
  final String message;
  ServerUnavailableException(this.message);

  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}

class SoapFaultException implements Exception {
  final String message;
  final String? responseData;

  SoapFaultException(this.message, [this.responseData]);

  @override
  String toString() => message;
}