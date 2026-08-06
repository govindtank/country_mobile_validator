import 'dart:convert';

import 'package:country_mobile_validator/country_mobile_validator.dart';
import 'package:test/test.dart';

/// Golden corpus test: every region's official example mobile number from the
/// libphonenumber metadata must validate as a mobile number. This catches
/// regex translation errors across all 247 mobile-enabled regions at once.
void main() {
  final kit = CountryMobileValidator();

  // Load raw metadata to read example numbers (they're embedded in kRegionsJson).
  final raw = jsonDecode(kRegionsJson) as List<dynamic>;

  final regions = raw
      .map((e) => e as Map<String, dynamic>)
      .where((r) => r['mob_ex'] != null)
      .toList();

  test('every region example number validates as mobile', () {
    final failures = <String>[];
    for (final r in regions) {
      final id = r['id'] as String;
      final ex = r['mob_ex'] as String;
      final cc = r['cc'] as int;
      final res = kit.validate('+$cc$ex');
      if (!res.isValid || !res.isMobile) {
        failures.add(
            '$id: +$cc$ex → valid=${res.isValid} mobile=${res.isMobile} type=${res.type} issue=${res.issue}');
      }
    }
    expect(failures, isEmpty,
        reason: 'Example-number failures:\n${failures.join('\n')}');
  });

  test('example numbers are within declared mobile length range', () {
    final violations = <String>[];
    for (final r in regions) {
      final len = r['mob_len'] as List?;
      final ex = r['mob_ex'] as String;
      if (len == null) continue;
      final lo = (len[0] as num).toInt();
      final hi = (len[1] as num).toInt();
      if (ex.length < lo || ex.length > hi) {
        violations.add('${r['id']}: example $ex (${ex.length}) outside $len');
      }
    }
    expect(violations, isEmpty);
  });

  test('every region with a pattern has a valid length range', () {
    final missing = regions
        .where((r) => r['mob_len'] == null && r['mob_pat'] != null)
        .map((r) => r['id'])
        .toList();
    expect(missing, isEmpty,
        reason: 'Regions with pattern but no length: $missing');
  });
}
