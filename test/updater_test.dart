import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:country_mobile_validator/country_mobile_validator.dart';
import 'package:test/test.dart';

/// Fake fetcher serving manifest + snapshot from in-memory maps.
class FakeFetcher {
  final Map<String, String> responses = {};

  Future<Uint8List> call(String url) async {
    final body = responses[url];
    if (body == null) throw Exception('no response for $url');
    return Uint8List.fromList(utf8.encode(body));
  }
}

void main() {
  group('MetadataUpdater', () {
    test('same version → success, no download', () async {
      final f = FakeFetcher();
      f.responses['https://m/manifest.json'] =
          jsonEncode({'version': '2026.08', 'sha256': 'x', 'url': 'https://m/data.json'});
      final u = MetadataUpdater(manifestUrl: 'https://m/manifest.json', fetcher: f.call);
      final res = await u.checkAndUpdate(currentVersion: '2026.08');
      expect(res.success, isTrue);
      expect(res.newVersion, '2026.08');
      expect(u.lastVerifiedJson, isNull); // nothing downloaded
    });

    test('new version → downloads, verifies SHA-256, stores JSON', () async {
      final data = jsonEncode([
        {'id': 'ZZ', 'cc': 999, 'main': true, 'mob_len': [10, 10], 'mob_pat': '5\\d{9}', 'mob_ex': '5123456789'}
      ]);
      final f = FakeFetcher();
      f.responses['https://m/manifest.json'] = jsonEncode({
        'version': '2026.09',
        'sha256': sha256.convert(utf8.encode(data)).toString(),
        'url': 'https://m/data.json',
      });
      f.responses['https://m/data.json'] = data;
      final u = MetadataUpdater(manifestUrl: 'https://m/manifest.json', fetcher: f.call);
      final res = await u.checkAndUpdate(currentVersion: '2026.08');
      expect(res.success, isTrue);
      expect(res.newVersion, '2026.09');
      expect(u.lastVerifiedJson, data);

      // And the refreshed data actually loads and validates.
      final kit = MobileNumberKit();
      kit.loadRefreshedMetadata(u.lastVerifiedJson!, version: res.newVersion!);
      expect(kit.hasRegion('ZZ'), isTrue);
      final r = kit.forRegion('ZZ').validate('5123456789');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
    });

    test('tampered payload → SHA-256 mismatch, no swap', () async {
      final data = jsonEncode([{'id': 'ZZ', 'cc': 999}]);
      final f = FakeFetcher();
      f.responses['https://m/manifest.json'] = jsonEncode({
        'version': '2026.09',
        'sha256': 'deadbeef' * 8, // wrong hash
        'url': 'https://m/data.json',
      });
      f.responses['https://m/data.json'] = data;
      final u = MetadataUpdater(manifestUrl: 'https://m/manifest.json', fetcher: f.call);
      final res = await u.checkAndUpdate(currentVersion: '2026.08');
      expect(res.success, isFalse);
      expect(res.error, contains('SHA-256 mismatch'));
      expect(u.lastVerifiedJson, isNull);
    });

    test('network failure → graceful error, offline fallback intact', () async {
      final f = FakeFetcher(); // no responses → every fetch throws
      final u = MetadataUpdater(manifestUrl: 'https://m/manifest.json', fetcher: f.call);
      final res = await u.checkAndUpdate(currentVersion: '2026.08');
      expect(res.success, isFalse);
      expect(res.error, contains('manifest fetch failed'));
      expect(u.lastVerifiedJson, isNull);
    });

    test('sha256Hex matches known vector', () {
      expect(sha256Hex(utf8.encode('hello world')), 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9');
    });
  });
}
