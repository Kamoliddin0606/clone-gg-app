/// Decoded `{ "error": { code, message, details, traceId } }` body.
///
/// Lives in the data layer so the interceptor can produce a Domain `Failure`
/// without ad-hoc parsing at every call site.
class ErrorEnvelope {
  const ErrorEnvelope({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? traceId;

  /// Tolerant parser — accepts either `{ "error": { ... } }` or a bare
  /// `{ code, message }` body (some legacy 5xx pages don't wrap).
  static ErrorEnvelope? tryParse(dynamic body) {
    if (body is! Map) return null;
    final outer = body['error'] is Map ? body['error'] as Map : body;
    final code = outer['code'];
    final message = outer['message'];
    if (code is! String || message is! String) return null;
    return ErrorEnvelope(
      code: code,
      message: message,
      details: (outer['details'] as Map?)?.cast<String, dynamic>(),
      traceId: outer['traceId'] as String?,
    );
  }
}
