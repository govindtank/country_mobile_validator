/// Metadata store: lazily loads the bundled region data and provides
/// lookups by region code and by country calling code.
library;

import 'dart:convert';

import 'data/regions_data.dart';
import 'types.dart';

/// One territory entry from the generated dataset.
class RegionInfo {
  const RegionInfo({
    required this.id,
    required this.countryCode,
    required this.nationalPrefix,
    required this.isMain,
    this.mobileRange,
    this.mobilePattern,
    this.mobileExample,
    this.fixedPattern,
    this.tollFreePattern,
    this.premiumPattern,
    this.shortCodePattern,
    this.sharedCostPattern,
    this.leadingDigits,
    this.nonGeo = false,
  });

  final String id;
  final int countryCode;
  final String nationalPrefix;
  final bool isMain;

  /// `min`–`max` national significant length for mobile numbers.
  final (int, int)? mobileRange;
  final String? mobilePattern;
  final String? mobileExample;
  final String? fixedPattern;
  final String? tollFreePattern;
  final String? premiumPattern;
  final String? shortCodePattern;
  final String? sharedCostPattern;
  final String? leadingDigits;
  final bool nonGeo;

  bool get hasMobile => mobilePattern != null;

  /// Mobile length range as a [NumberRange] (null when unknown).
  NumberRange? get mobileNumberRange => mobileRange == null
      ? null
      : NumberRange(min: mobileRange!.$1, max: mobileRange!.$2);

  static RegionInfo fromJson(Map<String, dynamic> j) {
    (int, int)? len;
    final l = j['mob_len'];
    if (l is List && l.length == 2) {
      final lo = (l[0] as num).toInt();
      if (lo >= 0) len = (lo, (l[1] as num).toInt());
    }
    return RegionInfo(
      id: j['id'] as String,
      countryCode: (j['cc'] as num).toInt(),
      nationalPrefix: (j['prefix'] as String?) ?? '',
      isMain: j['main'] == true,
      mobileRange: len,
      mobilePattern: j['mob_pat'] as String?,
      mobileExample: j['mob_ex'] as String?,
      fixedPattern: j['fx_pat'] as String?,
      tollFreePattern: j['tf_pat'] as String?,
      premiumPattern: j['pr_pat'] as String?,
      shortCodePattern: j['sc_pat'] as String?,
      sharedCostPattern: j['shc_pat'] as String?,
      leadingDigits: j['ld'] as String?,
      nonGeo: j['nonGeo'] == true,
    );
  }
}

/// Lazily-initialized store of all regions.
class RegionsStore {
  /// Loads the bundled metadata snapshot.
  RegionsStore() {
    _byId = _load(kRegionsJson);
  }

  /// Store loaded from a refreshed metadata snapshot.
  RegionsStore.fromJson(String json) {
    _byId = _load(json);
  }

  static final RegionsStore instance = RegionsStore();

  Map<String, RegionInfo>? _byId;
  Map<int, List<RegionInfo>>? _byCc;

  /// All regions keyed by ISO-2 id (plus `X<cc>` for non-geo).
  Map<String, RegionInfo> get byId {
    _byId ??= _load(kRegionsJson);
    return _byId!;
  }

  /// Regions keyed by country calling code (multiple regions share +1, +44...).
  Map<int, List<RegionInfo>> get byCountryCode {
    _byCc ??= () {
      final m = <int, List<RegionInfo>>{};
      for (final r in byId.values) {
        m.putIfAbsent(r.countryCode, () => []).add(r);
      }
      for (final l in m.values) {
        // main country first (e.g. US before other NANP regions)
        l.sort((a, b) => (b.isMain ? 1 : 0) - (a.isMain ? 1 : 0));
      }
      return m;
    }();
    return _byCc!;
  }

  RegionInfo? byRegionCode(String code) => byId[code.toUpperCase()];

  List<RegionInfo>? forCountryCode(int cc) => byCountryCode[cc];

  Map<String, RegionInfo> _load(String source) {
    final data = jsonDecode(source) as List<dynamic>;
    return {
      for (final e in data)
        (e as Map<String, dynamic>)['id'] as String: RegionInfo.fromJson(e),
    };
  }

  int get count => byId.length;
}
