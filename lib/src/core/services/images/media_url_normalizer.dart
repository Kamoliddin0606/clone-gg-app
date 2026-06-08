import 'package:flutter/foundation.dart';

import '../token_service.dart';

/// Rewrites a backend-supplied media URL so its scheme/host/port match the
/// app's reachable V2 base ([TokenService.v2BaseUrl]).
///
/// **Why this exists.** The backend builds absolute media URLs via
/// `request.build_absolute_uri()`. Behind the current reverse proxy that
/// resolves to `https://<host>:8080/media/...` — but port 8080 only serves
/// plain HTTP, so the TLS handshake fails and the image bytes never load
/// (product / customer photos render as broken). The metadata list call
/// itself succeeds because the app talks to `http://<host>:8080` directly.
///
/// This is a defensive client-side mitigation, NOT the real fix: the
/// backend should emit a reachable URL (`http://<host>:8080/...` or
/// `https://<host>/...` on 443). To stay safe, we ONLY touch URLs whose
/// host matches the configured V2 base host — a CDN / third-party host is
/// left untouched. When the backend is corrected, same-host URLs already
/// match the base and this becomes a no-op.
String? normalizeMediaUrl(String? url) {
  if (url == null || url.isEmpty) return url;

  final Uri parsed;
  try {
    parsed = Uri.parse(url);
  } catch (_) {
    return url;
  }
  if (!parsed.hasScheme || parsed.host.isEmpty) return url;

  final base = Uri.parse(TokenService.v2BaseUrl);
  // Only realign URLs that point at the same host as our API base. Anything
  // else (e.g. a future CDN) is intentionally left as-is.
  if (parsed.host != base.host) return url;

  // Already reachable (scheme + port already match the base) → no-op.
  if (parsed.scheme == base.scheme && parsed.port == base.port) return url;

  final fixed = parsed.replace(
    scheme: base.scheme,
    port: base.hasPort ? base.port : null,
  );
  if (kDebugMode) {
    debugPrint('[IMG-URL] normalized "$url" → "$fixed"');
  }
  return fixed.toString();
}
