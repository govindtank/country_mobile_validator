# country_mobile_validator

**Validate mobile numbers per country using the real length ranges** — and it
works out-of-the-box with `country_code_picker`.

- ✅ **Mobile-only** — landlines, toll-free, premium and short codes are flagged, never silently accepted.
- ✅ **Range-aware** — every country exposes its true mobile length range (`8–10`, `10–11`…), no hardcoded "10 digits".
- ✅ **Zero setup** — one import, one call.
- ✅ **1 dependency** (`crypto`, Dart-team maintained). Pure Dart, ~8 µs per validation, works on all platforms.
- ✅ **Refreshable metadata** — SHA-256-verified updates of the bundled
  [libphonenumber](https://github.com/google/libphonenumber) data (Apache-2.0).

## Quick start

```dart
import 'package:country_mobile_validator/country_mobile_validator.dart';

void main() {
  // One-shot: auto-detects the country from the calling code.
  final r = validateMobile('+91 98765 43210'); // India
  print(r.isValid);       // true
  print(r.isMobile);      // true
  print(r.regionCode);    // IN
}
```

Prefer an instance? It also supports pinned (national-format) validation:

```dart
final v = CountryMobileValidator();

v.validate('+1 415 555 2671').isValid;        // true — auto-detect
v.forRegion('AR').validate('91123456789').isValid; // true — Argentina, 11 digits
v.forRegion('AR').validate('91123456').isValid;    // false — too short
v.forRegion('AR').lengthHint;                      // "10–11 digits"
```

## `country_code_picker` integration

Pick a country, validate against *that* country's real mobile range:

```dart
import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_mobile_validator/country_mobile_validator.dart';

final kit = CountryMobileValidator();

CountryCodePicker(
  onChanged: (CountryCode c) => selected = c,
);

// On submit — the country_code_picker flow in one call:
final res = kit.validateForCountry(selected!.code!, input);

if (!res.isValid) {
  error = 'Enter a valid mobile number (${kit.forRegion(selected!.code!).lengthHint})';
}
```

Live feedback while typing (uses the real range for the selected country):

```dart
final v = kit.forRegion(selected!.code!);
final len = controller.text.replaceAll(RegExp(r'\D'), '').length;
hint = v.isMobileLength(len) ? '✓' : 'Needs ${v.lengthHint}';
```

## Why range-awareness matters

Argentina allows **10–11** digits, New Zealand **8–10**, Indonesia **9–12**,
India exactly **10**. This library knows all 247 mobile-enabled regions —
you never hardcode a length again.

```dart
final v = kit.forRegion('NZ');
v.mobileLengthRange;  // (8, 10)
v.isMobileLength(8);  // true
v.isMobileLength(7);  // false
```

## OTP-safe verdicts

`800`-numbers never pass as mobile:

```dart
final r = v.validate('+1 800 555 0134');
r.type;              // NumberType.tollFree — NOT mobile
r.isOtpDeliverable;  // false — don't send an OTP here
```

Every result carries `isValid`, `isMobile`, `isOtpDeliverable`, `type`,
`issue` (why it failed — `tooShort`, `invalidPrefix`…), `regionCode`,
`mobileRange`, and `metadataVersion`.

## Refreshable metadata

```dart
final updater = MetadataUpdater(
  manifestUrl: 'https://example.com/mobile-num-metadata/manifest.json',
);
final res = await updater.checkAndUpdate(currentVersion: kit.metadataVersion);
if (res.success && res.newVersion != null) {
  kit.loadRefreshedMetadata(updater.lastVerifiedJson!, version: res.newVersion!);
}
// Offline fallback: the bundled snapshot keeps working. Nothing breaks.
```

Manifest: `{ "version": "2026.08", "sha256": "…", "url": "…" }` — the download
is verified against the SHA-256 before use.

## Example app

A complete Flutter demo wiring this library to `country_code_picker` with live
range feedback and OTP verdicts: [`example/`](example/README.md)
(`cd example && flutter run`).

## Blog post

A complete guide with code samples: [Validating Mobile Numbers the Right Way:
Introducing country_mobile_validator](https://govindtank.github.io/blog/validating-mobile-numbers-right-way-country-mobile-validator)

## Development

```bash
dart pub get
dart test        # golden corpus over all 247 mobile regions + updater + API
dart analyze
```

## License

Apache-2.0. Metadata generated from
[libphonenumber](https://github.com/google/libphonenumber) (Apache-2.0,
Copyright Google Inc.).
