/// High-level convenience extensions on [String] for mobile validation.
library;

import 'carrier_detector.dart';
import 'parser.dart';
import 'types.dart';
import 'validator.dart';

/// Extension methods for zero-boilerplate mobile number validation and formatting.
extension CountryMobileStringExtensions on String {
  /// Validates this string as a mobile number.
  /// If input starts with `+`, uses global auto-detecting validation.
  /// Otherwise validates against the specified [region] (defaults to `'IN'`).
  ValidationResult validateMobile([String region = 'IN']) {
    final trimmed = trim();
    if (trimmed.startsWith('+')) {
      return mobileValidator.validate(trimmed);
    }
    try {
      final v = mobileValidator.forRegion(region);
      return v.validate(trimmed);
    } catch (_) {
      return mobileValidator.validate(trimmed);
    }
  }

  /// Whether this string is a valid cellular mobile number.
  bool isValidMobile([String region = 'IN']) {
    final res = validateMobile(region);
    return res.isValid && res.isMobile;
  }

  /// Whether this number is deliverable for SMS OTP codes.
  bool isOtpDeliverable([String region = 'IN']) {
    final res = validateMobile(region);
    return res.isOtpDeliverable;
  }

  /// Identifies the telecom carrier and service circle for this mobile number.
  CarrierInfo? detectCarrier({String defaultRegion = 'IN'}) {
    return CarrierDetector.detect(this, defaultRegion: defaultRegion);
  }

  /// Converts this number to canonical E.164 format (e.g. `+919876543210`).
  String? toE164([String region = 'IN']) {
    final trimmed = trim();
    if (trimmed.startsWith('+')) {
      final parsed = parseNumber(trimmed);
      if (parsed.countryCode != null) {
        return '+${parsed.countryCode}${parsed.digits}';
      }
    }
    try {
      final v = mobileValidator.forRegion(region);
      return v.formatE164(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// Generates a direct WhatsApp click-to-chat URL (`https://wa.me/...`).
  String? toWhatsAppUrl({String region = 'IN', String? message}) {
    final e164 = toE164(region);
    if (e164 == null) return null;
    final digits = e164.replaceAll('+', '');
    if (message != null && message.isNotEmpty) {
      final encoded = Uri.encodeComponent(message);
      return 'https://wa.me/$digits?text=$encoded';
    }
    return 'https://wa.me/$digits';
  }

  /// Formats the mobile number into standard national groupings (e.g. `98765 43210`).
  String formatNational([String region = 'IN']) {
    var rawDigits = replaceAll(RegExp(r'\D'), '');
    if (startsWith('+') || rawDigits.length > 10) {
      final parsed = parseNumber(this);
      if (parsed.countryCode != null) {
        rawDigits = parsed.digits;
      }
    }

    if (rawDigits.length == 10) {
      return '${rawDigits.substring(0, 5)} ${rawDigits.substring(5)}';
    }
    try {
      final v = mobileValidator.forRegion(region);
      return v.formatNational(rawDigits);
    } catch (_) {
      return rawDigits;
    }
  }
}
