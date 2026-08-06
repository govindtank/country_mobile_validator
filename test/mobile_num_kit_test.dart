import 'package:country_mobile_validator/country_mobile_validator.dart';
import 'package:test/test.dart';

void main() {
  group('MobileNumberKit basics', () {
    final kit = MobileNumberKit();

    test('metadata loads all regions', () {
      expect(kit.regionCount, greaterThan(200));
      expect(kit.hasRegion('IN'), isTrue);
      expect(kit.hasRegion('US'), isTrue);
      expect(kit.hasRegion('AR'), isTrue);
    });

    test('regions sharing +1 resolve', () {
      final rs = kit.regionsForCountryCode(1);
      expect(rs.map((r) => r.id), containsAll(['US', 'CA']));
      expect(rs.first.id, 'US'); // main country first
    });

    test('unknown region throws', () {
      expect(() => kit.forRegion('ZZ'), throwsArgumentError);
    });
  });

  group('Range API — the core differentiator', () {
    final kit = MobileNumberKit();

    test('variable length countries expose real ranges', () {
      final ar = kit.forRegion('AR').mobileLengthRange;
      expect(ar, (10, 11));

      final nz = kit.forRegion('NZ').mobileLengthRange;
      expect(nz, (8, 10));

      final in_ = kit.forRegion('IN').mobileLengthRange;
      expect(in_, (10, 10));

      final us = kit.forRegion('US').mobileLengthRange;
      expect(us, (10, 10));

      final br = kit.forRegion('BR').mobileLengthRange;
      expect(br, (10, 11));
    });

    test('length hint is human readable', () {
      expect(kit.forRegion('AR').lengthHint, '10–11 digits');
      expect(kit.forRegion('IN').lengthHint, '10 digits');
    });
  });

  group('Country-code aware validation', () {
    final kit = MobileNumberKit();

    test('India mobile', () {
      final r = kit.validate('+919876543210');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
      expect(r.isOtpDeliverable, isTrue);
      expect(r.regionCode, 'IN');
      expect(r.e164, '919876543210');
    });

    test('India — wrong prefix rejected (starts with 2, landline)', () {
      final r = kit.validate('+912222222222');
      expect(r.isValid, isFalse);
      expect(r.isMobile, isFalse);
      expect(r.type, NumberType.fixedLine);
      expect(r.issue, ValidationIssue.invalidPrefix);
    });

    test('Argentina — 11-digit mobile valid', () {
      final r = kit.validate('+5491123456789');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
      expect(r.regionCode, 'AR');
    });

  group('country_code_picker integration', () {
    test('validateForCountry validates against the real length range', () {
      // country_code_picker hands us Country.countryCode ("AR") + national input.
      final res = kit.validateForCountry('AR', '91123456789');
      expect(res.isValid, isTrue);
      expect(res.isMobile, isTrue);

      // Too short for Argentina's 10-11 range → invalid.
      expect(kit.validateForCountry('AR', '911234567').isValid, isFalse);
    });

    test('lengthHint drives user-facing error messages', () {
      final v = kit.forRegion('NZ');
      expect(v.lengthHint, '8–10 digits');
      expect(v.isMobileLength(8), isTrue);
      expect(v.isMobileLength(10), isTrue);
      expect(v.isMobileLength(7), isFalse);

      final v2 = kit.forRegion('IN');
      expect(v2.lengthHint, '10 digits');
      expect(v2.mobileLengthRange, (10, 10));
    });

    test('validateForCountry + dial code mirrors country_code_picker flow', () {
      // Typical picker state: dialCode "+91", countryCode "IN", raw input.
      const dialCode = '+91';
      const countryCode = 'IN';
      const raw = '9876543210';

      // Smart path: full international format.
      final smart = kit.validate('$dialCode$raw');
      expect(smart.isValid, isTrue);
      expect(smart.regionCode, 'IN');

      // Pinned path: national format against the picker's country.
      final pinned = kit.validateForCountry(countryCode, raw);
      expect(pinned.isValid, isTrue);
      expect(pinned.isMobile, isTrue);
    });

    test('unknown region throws with clear message', () {
      expect(() => kit.validateForCountry('XX', '123'), throwsArgumentError);
    });
  });

    test('US — valid NANP mobile', () {
      final r = kit.validate('+14155552671');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue); // US pattern is same as fixed, both "mobile" per metadata
      expect(r.regionCode, 'US');
    });

    test('US — toll-free flagged as special, not OTP-deliverable', () {
      final r = kit.validate('+18005551234');
      expect(r.isValid, isFalse);
      expect(r.type, NumberType.tollFree);
      expect(r.isOtpDeliverable, isFalse);
    });

    test('UK mobile', () {
      final r = kit.validate('+447400123456');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
      expect(r.regionCode, 'GB');
    });

    test('unknown country code', () {
      final r = kit.validate('+99912345678');
      expect(r.isValid, isFalse);
      expect(r.issue, ValidationIssue.unknownCountry);
    });
  });

  group('Region-pinned validation (no +CC)', () {
    final kit = MobileNumberKit();

    test('Argentina national format', () {
      final v = kit.forRegion('AR');
      final r = v.validate('91123456789');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
      expect(v.lengthHint, '10–11 digits');
    });

    test('India national format, 10 digits', () {
      final r = kit.forRegion('IN').validate('9876543210');
      expect(r.isValid, isTrue);
      expect(r.isMobile, isTrue);
    });

    test('India — 9 digits too short', () {
      final r = kit.forRegion('IN').validate('987654321');
      expect(r.isValid, isFalse);
      expect(r.issue, ValidationIssue.tooShort);
    });

    test('Argentina — 9 digits too short for mobile', () {
      final r = kit.forRegion('AR').validate('911234567');
      expect(r.isValid, isFalse);
      expect(r.issue, ValidationIssue.tooShort);
    });

    test('Brazil — 11-digit mobile valid', () {
      final r = kit.forRegion('BR').validate('11961234567');
      expect(r.isValid, isTrue);
    });
  });

  group('Input normalization', () {
    final kit = MobileNumberKit();

    test('separators stripped', () {
      expect(kit.validate('+91 98765 43210').isValid, isTrue);
      expect(kit.validate('+91-98765-43210').isValid, isTrue);
      expect(kit.validate('+91 (98765) 43210').isValid, isTrue);
    });

    test('Unicode digits normalized', () {
      // Arabic-Indic digits for 9876543210
      final arDigits = '\u{0669}\u{0668}\u{0667}\u{0666}\u{0665}\u{0664}\u{0663}\u{0662}\u{0661}\u{0660}';
      expect(kit.forRegion('IN').validate(arDigits).isValid, isTrue);
    });

    test('extension separated', () {
      final p = parseNumber('+1 415 555 2671 x123');
      expect(p.digits, '4155552671');
      expect(p.extension, '123');
    });

    test('empty and junk', () {
      expect(kit.forRegion('IN').validate('').isValid, isFalse);
      expect(kit.forRegion('IN').validate('abc').isValid, isFalse);
      expect(kit.forRegion('IN').validate('---').isValid, isFalse);
    });

    test('too many digits rejected (E.164 cap)', () {
      final r = kit.forRegion('IN').validate('98765432109876543210');
      expect(r.isValid, isFalse);
      expect(r.issue, ValidationIssue.tooLong);
    });
  });

  group('Regional edge cases', () {
    final kit = MobileNumberKit();

    test('Germany mobile 11 digits', () {
      expect(kit.validate('+4915123456789').isValid, isTrue);
    });

    test('France mobile 9 digits', () {
      expect(kit.validate('+33612345678').isValid, isTrue);
    });

    test('Indonesia mobile 9-12 digits', () {
      expect(kit.validate('+6281234567890').isValid, isTrue);
    });

    test('Japan mobile', () {
      expect(kit.validate('+819012345678').isValid, isTrue);
    });

    test('Canada via +1 — Toronto number resolves to CA', () {
      // 416 is a Toronto area code: US pattern fails, CA pattern matches
      final r = kit.validate('+14165551234');
      expect(r.isValid, isTrue);
      expect(r.regionCode, 'CA');
    });

    test('US via +1 — SF number resolves to US (main NANP first)', () {
      final r = kit.validate('+14155552671');
      expect(r.regionCode, 'US');
    });
  });
}
