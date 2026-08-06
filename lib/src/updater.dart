/// Refreshable metadata: opt-in update mechanism with SHA-256 verification
/// and offline fallback. This is what makes the library "real-time" —
/// bundled data stays current via a versioned, verified remote snapshot.
///
/// Pure Dart (dart:io) — works on VM/Flutter. On web, inject a custom
/// [fetch] implementation.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

/// Result of a metadata update attempt.
class MetadataUpdateResult {
  const MetadataUpdateResult({
    required this.success,
    this.newVersion,
    this.error,
  });

  final bool success;
  final String? newVersion;
  final String? error;

  @override
  String toString() =>
      'MetadataUpdateResult(success: $success, newVersion: $newVersion, error: $error)';
}

/// Remote manifest describing the latest metadata snapshot.
class MetadataManifest {
  const MetadataManifest({
    required this.version,
    required this.sha256,
    required this.url,
  });

  final String version;
  final String sha256;
  final String url;

  static MetadataManifest? fromJson(Map<String, dynamic> j) {
    final v = j['version'] as String?;
    final h = j['sha256'] as String?;
    final u = j['url'] as String?;
    if (v == null || h == null || u == null) return null;
    return MetadataManifest(version: v, sha256: h, url: u);
  }
}

/// Fetches a URL and returns the bytes. Injectable for tests.
typedef UrlFetcher = Future<Uint8List> Function(String url);

/// Default fetcher using dart:io HttpClient (follows redirects).
Future<Uint8List> defaultUrlFetcher(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();
    if (resp.statusCode != 200) {
      throw HttpException('HTTP ${resp.statusCode} for $url');
    }
    final bytes = <int>[];
    await for (final chunk in resp) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  } finally {
    client.close(force: true);
  }
}

/// SHA-256 hex digest of a byte list (via package:crypto).
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Downloads, verifies, and swaps in updated region metadata.
///
/// Usage:
/// ```dart
/// final updater = MetadataUpdater(
///   manifestUrl: 'https://example.com/mobile-num-metadata/manifest.json',
///   fetcher: myFetcher,
/// );
/// final res = await updater.checkAndUpdate(currentVersion: 'bundled-0.1.0');
/// ```
class MetadataUpdater {
  MetadataUpdater({required this.manifestUrl, UrlFetcher? fetcher})
      : _fetcher = fetcher ?? defaultUrlFetcher;

  final String manifestUrl;
  final UrlFetcher _fetcher;

  /// Last verified metadata payload (region JSON list), null until a
  /// successful update. Pass to [CountryMobileValidator.loadRefreshedMetadata].
  String? lastVerifiedJson;

  /// Fetches the manifest; if its version differs from [currentVersion],
  /// downloads the snapshot, verifies SHA-256, and stores it in
  /// [lastVerifiedJson]. Never throws on network failure — returns
  /// [MetadataUpdateResult] with error so callers can fall back offline.
  Future<MetadataUpdateResult> checkAndUpdate(
      {required String currentVersion}) async {
    MetadataManifest? manifest;
    try {
      final bytes = await _fetcher(manifestUrl);
      final j = jsonDecode(utf8.decode(bytes));
      manifest = MetadataManifest.fromJson(j as Map<String, dynamic>);
    } catch (e) {
      return MetadataUpdateResult(
          success: false, error: 'manifest fetch failed: $e');
    }
    if (manifest == null) {
      return const MetadataUpdateResult(
          success: false, error: 'invalid manifest');
    }
    if (manifest.version == currentVersion) {
      return MetadataUpdateResult(success: true, newVersion: manifest.version);
    }

    try {
      final data = await _fetcher(manifest.url);
      final hex = sha256Hex(data);
      if (hex != manifest.sha256.toLowerCase()) {
        return MetadataUpdateResult(
          success: false,
          error: 'SHA-256 mismatch: got $hex expected ${manifest.sha256}',
        );
      }
      // Validate it parses as region JSON before swapping.
      jsonDecode(utf8.decode(data)) as List<dynamic>;
      lastVerifiedJson = utf8.decode(data);
      return MetadataUpdateResult(success: true, newVersion: manifest.version);
    } catch (e) {
      return MetadataUpdateResult(
          success: false, error: 'snapshot update failed: $e');
    }
  }
}
