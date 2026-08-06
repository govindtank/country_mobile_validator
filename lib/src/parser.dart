/// Input normalization and country-code extraction.
library;

import 'store.dart';

/// Parsed raw input: digits, detected calling code, region candidates.
class ParsedNumber {
  const ParsedNumber({
    required this.digits,
    this.countryCode,
    this.regionCandidates = const [],
    this.trunkPrefix,
    this.extension,
    this.ambiguous = false,
  });

  /// Only ASCII digits, in order, without CC (unless [countryCode] is null).
  final String digits;

  /// Detected country calling code, when a leading +/00 was present.
  final int? countryCode;

  /// Regions matching the detected CC, ordered (main country first).
  final List<RegionInfo> regionCandidates;

  /// National trunk prefix (e.g. '0') if present and stripped.
  final String? trunkPrefix;

  /// Digits after 'ext.' / 'x' — not part of the number.
  final String? extension;

  /// True when more than one region shares the CC (e.g. +1, +44, +7).
  final bool ambiguous;
}

/// Extension separators that split an extension off the tail.
final RegExp kExtensionPattern =
    RegExp(r'([;,x#])\s*(\d+)\s*$', caseSensitive: false);

String _stripNonDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');

/// Safe, lossless normalization: strips separators, converts Unicode digits,
/// extracts a trailing extension. Never guesses country codes or trunk
/// prefixes. This is what region-pinned validation uses.
({String digits, String? extension}) normalizeDigits(String input) {
  var s = input.trim();
  if (s.isEmpty) return (digits: '', extension: null);

  // Convert common Unicode digit ranges to ASCII (Arabic-Indic, Devanagari, fullwidth...)
  final buf = StringBuffer();
  for (final rune in s.runes) {
    final c = String.fromCharCode(rune);
    if (rune >= 0x0660 && rune <= 0x0669) {
      buf.write(rune - 0x0660); // Arabic-Indic
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buf.write(rune - 0x06F0); // Eastern Arabic-Indic
    } else if (rune >= 0x0966 && rune <= 0x096F) {
      buf.write(rune - 0x0966); // Devanagari
    } else if (rune >= 0xFF10 && rune <= 0xFF19) {
      buf.write(rune - 0xFF10); // Fullwidth
    } else {
      buf.write(c);
    }
  }
  s = buf.toString();

  // Extension: split at ; x # , (pause/extension conventions)
  String? extension;
  final extMatch = kExtensionPattern.firstMatch(s);
  if (extMatch != null) {
    extension = extMatch.group(2);
    s = s.substring(0, extMatch.start).trim();
  }

  return (digits: _stripNonDigits(s), extension: extension);
}

/// Normalizes input: strips separators/Unicode digits, extracts extension,
/// detects leading + or 00 (international prefix) + country code.
ParsedNumber parseNumber(String input) {
  final n = normalizeDigits(input);
  var s = n.digits;
  final extension = n.extension;

  if (s.isEmpty) {
    return const ParsedNumber(digits: '', countryCode: null);
  }

  // E.164 hard limit: max 15 significant digits
  if (s.length > 18) {
    return ParsedNumber(digits: s, extension: extension);
  }

  String? trunk;
  int? cc;
  List<RegionInfo>? candidates;

  // Leading + → international format
  final hasPlus = input.trim().startsWith('+');
  var rest = s;

  if (hasPlus) {
    // try longest CC match (e.g. +1 vs +12 vs +123...)
    for (var len = 3; len >= 1; len--) {
      if (rest.length <= len) continue;
      final c = int.tryParse(rest.substring(0, len));
      if (c == null) continue;
      final cands = RegionsStore.instance.forCountryCode(c);
      if (cands != null && cands.isNotEmpty) {
        cc = c;
        candidates = cands;
        rest = rest.substring(len);
        break;
      }
    }
    if (cc == null) {
      return ParsedNumber(digits: s, extension: extension);
    }
  } else {
    // National format with explicit international prefix '00' only.
    // No trunk-prefix guessing — a leading '0'/'1'/'8' can be part of the
    // national number (Brazil 11..., etc). Trunk stripping belongs to
    // region-pinned validation where the country is already known.
    if (rest.startsWith('00') && rest.length > 3) {
      final trial = rest.substring(2);
      for (var len = 3; len >= 1; len--) {
        if (trial.length <= len) continue;
        final c = int.tryParse(trial.substring(0, len));
        if (c == null) continue;
        final cands = RegionsStore.instance.forCountryCode(c);
        if (cands != null && cands.isNotEmpty) {
          cc = c;
          candidates = cands;
          trunk = '00';
          rest = trial.substring(len);
          break;
        }
      }
    }
  }

  return ParsedNumber(
    digits: cc == null ? rest : rest,
    countryCode: cc,
    regionCandidates: candidates ?? const [],
    trunkPrefix: trunk,
    extension: extension,
    ambiguous: (candidates?.length ?? 0) > 1,
  );
}
