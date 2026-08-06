# mobile_num_kit

![architecture](assets/architecture.svg)

**Range-aware, mobile-only phone number validation for every country — with
refreshable, verified metadata.**

`mobile_num_kit` is the missing piece in the Dart ecosystem: existing phone
packages validate "any phone number" against **frozen** metadata, return
booleans, and can't tell you that a number is a **mobile** number (or that
Argentina allows **10–11** digits while New Zealand allows **8–10**).

This library:

- ✅ Validates **mobile numbers only** (OTP-ready) — rejects landlines,
  toll-free, premium-rate, and short codes.
- ✅ **Range-aware**: every country exposes its real mobile length range
  (`8–10`, `10–11`, …) so you never hardcode "10 digits" again.
- ✅ **Refreshable metadata** (SHA-256 verified, offline fallback) — bundled
  data from [libphonenumber](https://github.com/google/libphonenumber)
  (Apache-2.0), updatable at runtime.
- ✅ Pure Dart core — works on Flutter, Dart VM, and web. ~8 µs per
  validation, no platform channels.
- ✅ Handles `+`, separators, Unicode digits, extensions, trunk prefixes, and
  shared country codes (`+1` → US/CA/…, `+44` → GB/GG/JE/…).

---

## Quick start

```dart
import 'package:mobile_num_kit/mobile_num_kit.dart';

final kit = MobileNumberKit();

// Smart: auto-detects country from the calling code.
final r = kit.validate('+919876543210');          // India
print(r.isValid);      // true
print(r.isMobile);     // true
print(r.regionCode);   // IN

// Pinned: validate in national format against a specific country.
final v = kit.forRegion('AR');                    // Argentina
print(v.validate('91123456789').isValid);         // true (11 digits)
print(v.validate('911234567').isValid);           // false (too short)
print(v.lengthHint);                              // "10–11 digits"
```

## The range API (the differentiator)

```dart
final v = kit.forRegion('NZ');                    // New Zealand
print(v.mobileRange);      // 8–10
print(v.mobileRanges);     // [{min: 8, max: 10}] — full list, per-type
print(v.lengthHint);       // "8–10 digits"
print(v.isMobileLength(8));// true
print(v.isMobileLength(7));// false
```

Length variance is real: **AR 10–11, NZ 8–10, BR 10–11, ID 9–12, DE 10–11,
GB 10, IN 10, US 10**. `mobile_num_kit` knows them all.

## Type awareness (OTP-safe verdicts)

```dart
final r = kit.validate('+18005551234');           // US toll-free
print(r.type);            // NumberType.tollFree — NOT mobile
print(r.isOtpDeliverable);// false — don't send an OTP here
```

A `800`-number will never pass as a mobile. Types: `mobile`, `fixedLine`,
`tollFree`, `premiumRate`, `sharedCost`, `shortCode`, `unknown`.

## Refreshable metadata ("real-time")

Bundled data is versioned. Update it at runtime with SHA-256 verification:

```dart
final updater = MetadataUpdater(
  manifestUrl: 'https://example.com/mobile-num-metadata/manifest.json',
);
final res = await updater.checkAndUpdate(currentVersion: kit.metadataVersion);
if (res.success && res.newVersion != null) {
  kit.loadRefreshedMetadata(updater.lastVerifiedJson!, version: res.newVersion!);
} else {
  // Offline fallback: keep using the bundled snapshot. Nothing breaks.
}
```

On web, inject your own fetcher (e.g. `package:http`):

```dart
MetadataUpdater(
  manifestUrl: '...',
  fetcher: (url) async => (await http.get(Uri.parse(url))).bodyBytes,
);
```

The manifest is a tiny JSON:

```json
{ "version": "2026.08", "sha256": "…", "url": "…" }
```

## Region detection with shared country codes

`+1` covers 25 NANP regions; `+44` covers GB, GG, JE, IM. The library resolves
by longest-prefix match, tries the main region first, then the others, and
returns the region whose mobile pattern actually matches:

```dart
kit.validate('+14155552671').regionCode;   // US (415 = San Francisco)
kit.validate('+14165551234').regionCode;   // CA (416 = Toronto)
```

## What it handles

| Input | Behavior |
|---|---|
| `+91 98765 43210` | separators stripped |
| `٠٩٨٧٦٥٤٣٢١٠` | Arabic-Indic digits normalized |
| `+1 415 555 2671 x123` | extension split off, ignored |
| `011 91 98765 43210` | `011` international prefix handled |
| `+1…` vs `+44…` | longest-prefix calling-code match |
| `9876543210` (IN) | region-pinned national format |

## Development

```bash
dart pub get
dart test          # 37 tests: golden corpus over all 247 mobile regions + updater
dart analyze
dart run benchmark/bench.dart
```

Metadata refresh pipeline:

```bash
python3 tools/extract_metadata.py   # libphonenumber XML → tools/data/regions.json
python3 tools/gen_dart_data.py      # JSON → lib/src/data/regions_data.dart
```

## License & attribution

Apache-2.0. Metadata is generated from
[libphonenumber](https://github.com/google/libphonenumber) (Apache-2.0,
Copyright Google Inc.). Validators are compared against libphonenumber's
example corpus on every test run.
