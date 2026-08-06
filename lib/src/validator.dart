/// Validation engine: range + prefix + type checks against region metadata.
library;

import 'parser.dart';
import 'store.dart';
import 'types.dart';

/// Validates mobile numbers against a single region's rules.
class MobileValidator {
  MobileValidator(this.region, {this.metadataVersion = 'bundled-0.1.0'})
      : _mobileRe = region.mobilePattern == null ? null : RegExp('^${region.mobilePattern}\$'),
        _fixedRe = region.fixedPattern == null ? null : RegExp('^${region.fixedPattern}\$'),
        _tfRe = region.tollFreePattern == null ? null : RegExp('^${region.tollFreePattern}\$'),
        _prRe = region.premiumPattern == null ? null : RegExp('^${region.premiumPattern}\$'),
        _scRe = region.shortCodePattern == null ? null : RegExp('^${region.shortCodePattern}\$'),
        _shcRe = region.sharedCostPattern == null ? null : RegExp('^${region.sharedCostPattern}\$');

  final RegionInfo region;
  final String metadataVersion;

  final RegExp? _mobileRe;
  final RegExp? _fixedRe;
  final RegExp? _tfRe;
  final RegExp? _prRe;
  final RegExp? _scRe;
  final RegExp? _shcRe;

  /// The mobile length range for this region (min, max) or null.
  (int, int)? get mobileLengthRange => region.mobileRange;

  /// Human-readable range hint, e.g. "8–10 digits".
  String get lengthHint {
    final r = region.mobileRange;
    if (r == null) return 'unknown length';
    return r.$1 == r.$2 ? '${r.$1} digits' : '${r.$1}–${r.$2} digits';
  }

  ValidationResult validate(String input) {
    final norm = normalizeDigits(input);
    return validateNationalDigits(norm.digits, extension: norm.extension, rawInput: input);
  }

  /// Validates already-normalized national significant digits (no CC).
  /// Used by [MobileNumberKit.validate] after CC extraction.
  ValidationResult validateNationalDigits(
    String digits, {
    String? extension,
    String? rawInput,
  }) {
    final n = digits.length;

    if (digits.isEmpty) {
      return ValidationResult(
        input: rawInput ?? digits,
        isValid: false,
        isMobile: false,
        type: NumberType.notANumber,
        issue: extension != null ? ValidationIssue.empty : ValidationIssue.notANumber,
        metadataVersion: metadataVersion,
      );
    }

    // --- special types first (flag, don't silently accept as mobile) ---
    if (n >= 3) {
      if (_tfRe?.hasMatch(digits) ?? false) {
        return _special(rawInput ?? digits, digits, NumberType.tollFree, ValidationIssue.specialType);
      }
      if (_prRe?.hasMatch(digits) ?? false) {
        return _special(rawInput ?? digits, digits, NumberType.premiumRate, ValidationIssue.specialType);
      }
      if (_shcRe?.hasMatch(digits) ?? false) {
        return _special(rawInput ?? digits, digits, NumberType.sharedCost, ValidationIssue.specialType);
      }
      if (_scRe?.hasMatch(digits) ?? false) {
        return _special(rawInput ?? digits, digits, NumberType.shortCode, ValidationIssue.specialType);
      }
    }

    final r = region.mobileRange;
    if (r != null) {
      if (n < r.$1) {
        return ValidationResult(
          input: rawInput ?? digits,
          isValid: false,
          isMobile: false,
          type: NumberType.notANumber,
          issue: ValidationIssue.tooShort,
          regionCode: region.id,
          countryCode: region.countryCode,
          nationalNumber: digits,
          possible: n >= 3,
          metadataVersion: metadataVersion,
        );
      }
      if (n > r.$2) {
        return ValidationResult(
          input: rawInput ?? digits,
          isValid: false,
          isMobile: false,
          type: NumberType.notANumber,
          issue: ValidationIssue.tooLong,
          regionCode: region.id,
          countryCode: region.countryCode,
          nationalNumber: digits,
          metadataVersion: metadataVersion,
        );
      }
    }

    // --- prefix / pattern checks ---
    if (_mobileRe != null) {
      if (_mobileRe.hasMatch(digits)) {
        return ValidationResult(
          input: rawInput ?? digits,
          isValid: true,
          isMobile: true,
          type: NumberType.mobile,
          issue: ValidationIssue.none,
          regionCode: region.id,
          countryCode: region.countryCode,
          nationalNumber: digits,
          e164: '${region.countryCode}$digits',
          mobileRange: region.mobileNumberRange,
          possible: true,
          metadataVersion: metadataVersion,
        );
      }
    }

    // Not mobile — but maybe a valid fixed-line (isValid stays false for
    // mobile validation, but type/issue tell the caller why).
    final fx = _fixedRe?.hasMatch(digits) ?? false;

    return ValidationResult(
      input: rawInput ?? digits,
      isValid: false,
      isMobile: false,
      type: fx ? NumberType.fixedLine : NumberType.notANumber,
      issue: fx ? ValidationIssue.invalidPrefix : ValidationIssue.invalidPrefix,
      regionCode: region.id,
      countryCode: region.countryCode,
      nationalNumber: digits,
      possible: fx,
      mobileRange: region.mobileNumberRange,
      metadataVersion: metadataVersion,
    );
  }

  ValidationResult _special(String input, String digits, NumberType t, ValidationIssue i) {
    return ValidationResult(
      input: input,
      isValid: false, // not a mobile number
      isMobile: false,
      type: t,
      issue: i,
      regionCode: region.id,
      countryCode: region.countryCode,
      nationalNumber: digits,
      possible: true,
      metadataVersion: metadataVersion,
    );
  }
}

/// Country-code → region resolution + multi-region handling.
class MobileNumberKit {
  MobileNumberKit({this.metadataVersion = 'bundled-0.1.0'}) {
    _store = RegionsStore();
  }

  final String metadataVersion;
  late RegionsStore _store;

  /// Loads refreshed metadata produced by [MetadataUpdater.lastVerifiedJson].
  /// After this, validators use the new snapshot. Returns the new version
  /// string if loaded, else null.
  String? loadRefreshedMetadata(String json, {required String version}) {
    _store = RegionsStore.fromJson(json);
    return version;
  }

  /// Validator for a specific region (throws ArgumentError if unknown).
  MobileValidator forRegion(String iso2) {
    final r = _store.byRegionCode(iso2);
    if (r == null) throw ArgumentError.value(iso2, 'iso2', 'unknown region code');
    return MobileValidator(r, metadataVersion: metadataVersion);
  }

  /// Validates a number against all candidate regions for its calling code.
  /// Returns the first region whose mobile pattern matches, or a detailed
  /// failure. When the number has no +CC, use [forRegion] directly.
  ValidationResult validate(String input) {
    final p = parseNumber(input);
    if (p.countryCode == null) {
      return ValidationResult(
        input: input,
        isValid: false,
        isMobile: false,
        type: NumberType.notANumber,
        issue: ValidationIssue.unknownCountry,
        metadataVersion: metadataVersion,
      );
    }
    final cands = p.regionCandidates;
    if (cands.isEmpty) {
      return ValidationResult(
        input: input,
        isValid: false,
        isMobile: false,
        type: NumberType.notANumber,
        issue: ValidationIssue.unknownCountry,
        countryCode: p.countryCode,
        metadataVersion: metadataVersion,
      );
    }

    // Try each region (main first); collect failures.
    ValidationResult? best;
    for (final r in cands) {
      final res = MobileValidator(r, metadataVersion: metadataVersion)
          .validateNationalDigits(p.digits, rawInput: input);
      if (res.isValid && res.isMobile) return res;
      best ??= res;
      // remember a possible-but-invalid as the most informative
      if (res.possible && (best.possible == false || !res.isValid)) best = res;
    }
    return best!;
  }

  /// All regions sharing a calling code (e.g. 1 → [US, CA, ...]).
  List<RegionInfo> regionsForCountryCode(int cc) =>
      _store.forCountryCode(cc) ?? const [];

  /// Number of regions in the metadata snapshot.
  int get regionCount => _store.count;

  /// True if the given region code is known.
  bool hasRegion(String iso2) => _store.byRegionCode(iso2) != null;
}
