/// Core result and model types for country_mobile_validator.
library;

/// Classification of a parsed phone number.
enum NumberType {
  /// Matches the region's mobile pattern.
  mobile,

  /// Matches the region's fixed-line pattern (and not mobile).
  fixedLine,

  /// Toll-free / freephone (e.g. 800, 1800).
  tollFree,

  /// Premium-rate (e.g. 900, 1-900) — usually NOT OTP-deliverable.
  premiumRate,

  /// Shared-cost numbers.
  sharedCost,

  /// A short code / short number (5-7 digits typical).
  shortCode,

  /// Matches general pattern but no specific type could be determined
  /// (e.g. NANP regions cannot distinguish mobile from fixed by range).
  unknown,

  /// Not parseable / not a phone number.
  notANumber,
}

/// Why a number failed validation.
enum ValidationIssue {
  none,
  empty,
  notANumber,
  tooShort,
  tooLong,
  invalidPrefix,
  unknownCountry,
  ambiguousRegion,
  specialType, // valid number but toll-free/premium/short-code
}

/// Possible length range for a number category in a region, plus optional
/// distinguishing prefixes.
class NumberRange {
  const NumberRange({required this.min, required this.max, this.prefixes});

  final int min;
  final int max;

  /// Regex fragment of leading digits that identify this category,
  /// when the region's plan defines them (empty for NANP-style regions).
  final String? prefixes;

  @override
  String toString() => 'NumberRange($min-$max${prefixes == null ? '' : ', prefixes: $prefixes'})';
}

/// A single validated number result.
class ValidationResult {
  const ValidationResult({
    required this.input,
    required this.isValid,
    required this.isMobile,
    required this.type,
    required this.issue,
    this.regionCode,
    this.countryCode,
    this.nationalNumber,
    this.e164,
    this.mobileRange,
    this.possible = false,
    this.metadataVersion = '',
  });

  final String input;
  final bool isValid;

  /// True when the number matched the region's mobile pattern.
  /// May be false even when [isValid] is true (landline, NANP unknown).
  final bool isMobile;

  /// True when this number is realistically OTP/SMS-deliverable:
  /// valid AND mobile AND not a special type (toll-free/premium/short-code).
  bool get isOtpDeliverable =>
      isValid && isMobile && type == NumberType.mobile;

  final NumberType type;
  final ValidationIssue issue;

  /// Region code (ISO-2 or "X<cc>" for non-geographic), when known.
  final String? regionCode;

  /// Country calling code.
  final int? countryCode;

  /// National significant number (without trunk prefix / CC).
  final String? nationalNumber;

  /// Full E.164 form (without leading +).
  final String? e164;

  /// The mobile length range this number falls into (when region known).
  final NumberRange? mobileRange;

  /// True if the number could exist in the region per general length rules
  /// but didn't match a specific pattern (reserved/unassigned).
  final bool possible;

  /// Metadata snapshot version this result was validated against.
  final String metadataVersion;

  @override
  String toString() =>
      'ValidationResult($input: valid=$isValid mobile=$isMobile type=$type issue=$issue region=$regionCode)';
}
