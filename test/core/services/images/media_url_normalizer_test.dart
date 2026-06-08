import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/media_url_normalizer.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';

/// Guards the client-side mitigation for the backend media-URL scheme bug:
/// the V2 backend builds image URLs as `https://<host>:8080/...` but port
/// 8080 serves plain HTTP, so the bytes never load. [normalizeMediaUrl]
/// realigns same-host media URLs to the reachable [TokenService.v2BaseUrl].
void main() {
  final base = Uri.parse(TokenService.v2BaseUrl);

  group('normalizeMediaUrl', () {
    test('null / empty pass through unchanged', () {
      expect(normalizeMediaUrl(null), isNull);
      expect(normalizeMediaUrl(''), '');
    });

    test('a foreign host (e.g. a CDN) is left untouched', () {
      const cdn = 'https://cdn.example.org:9443/media/img/s/x.webp?v=1';
      expect(normalizeMediaUrl(cdn), cdn);
    });

    test('same-host URL with a wrong scheme/port is realigned to the base '
        'scheme+port, preserving path + query', () {
      // Deliberately wrong variant of the API host — the exact shape the
      // backend currently emits (https on a non-TLS port).
      final wrongScheme = base.scheme == 'https' ? 'http' : 'https';
      final bad = Uri(
        scheme: wrongScheme,
        host: base.host,
        port: 18080,
        path: '/media/img/s/2026/05/small.webp',
        query: 'a=1',
      ).toString();

      final fixed = Uri.parse(normalizeMediaUrl(bad)!);
      expect(fixed.scheme, base.scheme);
      expect(fixed.host, base.host);
      expect(fixed.port, base.port);
      expect(fixed.path, '/media/img/s/2026/05/small.webp');
      expect(fixed.query, 'a=1');
    });

    test('the concrete backend bug: https://<host>:8080 → reachable base', () {
      final bad =
          'https://${base.host}:8080/media/img/s/2026/05/small.webp';
      final fixed = Uri.parse(normalizeMediaUrl(bad)!);
      expect(fixed.scheme, base.scheme);
      expect(fixed.host, base.host);
      expect(fixed.port, base.port);
      expect(fixed.path, '/media/img/s/2026/05/small.webp');
    });

    test('an already-reachable same-host URL is returned unchanged', () {
      final good = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: '/media/img/m/2026/06/medium.webp',
      ).toString();
      expect(normalizeMediaUrl(good), good);
    });

    test('is idempotent', () {
      final bad = 'https://${base.host}:8080/media/x.webp';
      final once = normalizeMediaUrl(bad);
      final twice = normalizeMediaUrl(once);
      expect(twice, once);
    });

    test('a non-parseable / schemeless value is returned as-is', () {
      expect(normalizeMediaUrl('not a url'), 'not a url');
      expect(normalizeMediaUrl('/media/relative.webp'), '/media/relative.webp');
    });
  });
}
