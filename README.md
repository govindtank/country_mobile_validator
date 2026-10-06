# country_mobile_validator

<p align="center">
  <a href="https://pub.dev/packages/country_mobile_validator"><img src="https://img.shields.io/pub/v/country_mobile_validator.svg?style=flat-square&color=blue" alt="Pub Version"></a>
  <a href="https://pub.dev/packages/country_mobile_validator/score"><img src="https://img.shields.io/pub/points/country_mobile_validator?style=flat-square&color=2E8B57&label=pub%20points" alt="Pub Points"></a>
  <a href="https://pub.dev/packages/country_mobile_validator"><img src="https://img.shields.io/pub/likes/country_mobile_validator?style=flat-square" alt="Pub Likes"></a>
  <a href="https://github.com/govindtank/country_mobile_validator/actions"><img src="https://github.com/govindtank/country_mobile_validator/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square" alt="License"></a>
</p>

---

<p align="center">
  <img src="https://raw.githubusercontent.com/govindtank/country_mobile_validator/main/screenshot.svg" width="680" alt="country_mobile_validator screenshot" />
</p>

---

## 🌟 Why `country_mobile_validator`?

Most phone number validators either assume a naive "10 digits everywhere" rule or pull in heavy, unmaintained regex wrappers. `country_mobile_validator` provides lightweight, accurate, and type-aware validation:

- 📱 **Mobile-Only Detection** — Landlines, toll-free, premium rate, and short codes are flagged accurately and never mistakenly treated as deliverable mobile numbers.
- 🎯 **Range-Aware** — Every country exposes its true national mobile length range (`8–10`, `10–11`…), preventing valid international users from getting blocked.
- ⚡ **Ultra-Fast & Pure Dart** — ~8 µs per validation, 0 platform channels, 1 standard dependency (`crypto`). Works everywhere: Flutter (Android, iOS, Web, macOS, Windows, Linux) and standalone Dart / Server.
- 🔒 **OTP-Safe Verdicts** — Returns `isOtpDeliverable` and specific failure reasons (`tooShort`, `invalidPrefix`, etc.) before you trigger costly SMS gateways.
- 🔄 **Refreshable Metadata** — Built-in SHA-256 verified runtime updater for bundled [libphonenumber](https://github.com/google/libphonenumber) metadata without needing a package update.
- 🧩 **First-Class `country_code_picker` Companion** — Validate as users type or submit with one function call.

---

## 📦 Installation

Add `country_mobile_validator` to your `pubspec.yaml`:

```bash
# For Flutter:
flutter pub add country_mobile_validator

# For pure Dart:
dart pub add country_mobile_validator
```

Or manually in `pubspec.yaml`:

```yaml
dependencies:
  country_mobile_validator: ^0.2.1
```

---

## 🚀 Quick Start

### 1. One-Shot Auto-Detection (E.164 / International)

Automatically parses the international dialing code and validates against that country's mobile rules:

```dart
import 'package:country_mobile_validator/country_mobile_validator.dart';

void main() {
  // India mobile (+91)
  final r1 = validateMobile('+91 98765 43210');
  print(r1.isValid);           // true
  print(r1.isMobile);          // true
  print(r1.isOtpDeliverable);   // true
  print(r1.regionCode);        // IN

  // US Toll-Free (+1 800)
  final r2 = validateMobile('+1 800 555 0134');
  print(r2.isValid);           // true
  print(r2.isMobile);          // false (NumberType.tollFree)
  print(r2.isOtpDeliverable);   // false -> Do not attempt SMS OTP!
}
```

### 2. Country-Pinned Validation (National Format)

Validate national numbers for a specific ISO-3166-1 alpha-2 region code:

```dart
final validator = CountryMobileValidator();

// Argentina (AR) allows 10–11 digits
final arRegion = validator.forRegion('AR');
print(arRegion.lengthHint);                       // "10–11 digits"
print(arRegion.validate('91123456789').isValid);  // true (11 digits)
print(arRegion.validate('91123456').isValid);     // false (too short)
```

---

## 📱 `country_code_picker` Integration

Easily integrate with Flutter's `country_code_picker` or any country dropdown:

```dart
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_mobile_validator/country_mobile_validator.dart';

class PhoneInputWidget extends StatefulWidget {
  const PhoneInputWidget({super.key});

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  final _validator = CountryMobileValidator();
  String _selectedCountryCode = 'US';
  String? _errorMessage;

  void _onValidate(String rawNumber) {
    final result = _validator.validateForCountry(
      _selectedCountryCode,
      rawNumber,
    );

    setState(() {
      if (result.isValid && result.isMobile) {
        _errorMessage = null; // Valid mobile number!
      } else {
        final hint = _validator.forRegion(_selectedCountryCode).lengthHint;
        _errorMessage = 'Please enter a valid mobile number ($hint)';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CountryCodePicker(
              initialSelection: _selectedCountryCode,
              onChanged: (country) {
                setState(() {
                  _selectedCountryCode = country.code ?? 'US';
                });
              },
            ),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  errorText: _errorMessage,
                ),
                onChanged: _onValidate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 🌍 Real-World Range Awareness

Different countries have different mobile length standards. Hardcoding 10 digits breaks for billions of real users:

| Country | Code | Mobile Length Range | Notes |
|---|---|---|---|
| **Argentina** | `AR` | 10 – 11 digits | Includes mobile prefix 9 |
| **New Zealand** | `NZ` | 8 – 10 digits | Variable length mobile prefixes |
| **Indonesia** | `ID` | 9 – 12 digits | Variable length by telecom carrier |
| **India** | `IN` | 10 digits | Strict 10-digit mobile numbering |
| **Germany** | `DE` | 10 – 11 digits | Standard mobile allocations |
| **United Kingdom**| `GB` | 10 digits | Mobile prefix 7xxx |

With `country_mobile_validator`, query any region dynamically:

```dart
final nz = validator.forRegion('NZ');
nz.mobileLengthRange; // (8, 10)
nz.isMobileLength(8); // true
nz.isMobileLength(7); // false
```

---

## 🔍 ValidationResult API

Each validation call returns a rich `ValidationResult` object:

| Field | Type | Description |
|---|---|---|
| `isValid` | `bool` | Whether the number is valid syntax and length for the country. |
| `isMobile` | `bool` | Whether the number type is strictly a mobile line. |
| `isOtpDeliverable` | `bool` | Convenience boolean: `isValid && isMobile`. Safe to send SMS OTP. |
| `regionCode` | `String?` | 2-letter ISO country code (e.g. `IN`, `US`, `GB`). |
| `countryCallingCode` | `String?` | International calling code (e.g. `+91`, `+1`). |
| `nationalNumber` | `String?` | Sanitized national number digits. |
| `type` | `NumberType` | `mobile`, `fixedLine`, `tollFree`, `premiumRate`, `voip`, `unknown`. |
| `issue` | `ValidationIssue?` | Reason for failure: `tooShort`, `tooLong`, `invalidPrefix`, `unknownCountry`, etc. |
| `metadataVersion` | `String` | Version of the metadata used during validation. |

---

## 🔄 Refreshable Metadata Pipeline

When country numbering plans change, update metadata in runtime without releasing a new app build:

```dart
final updater = MetadataUpdater(
  manifestUrl: 'https://your-cdn.com/phone-metadata/manifest.json',
);

final result = await updater.checkAndUpdate(
  currentVersion: validator.metadataVersion,
);

if (result.success && result.newVersion != null) {
  validator.loadRefreshedMetadata(
    updater.lastVerifiedJson!,
    version: result.newVersion!,
  );
}
```

- **Cryptographic Security**: Downloads are verified against SHA-256 checksums.
- **Resilient Fallback**: If the network is unavailable or verification fails, the bundled snapshot continues working seamlessly.

---

## 🛠️ Testing & Development

Run the test suite covering 247 mobile regions:

```bash
dart pub get
dart test
dart analyze
```

---

## 🌐 Ecosystem & Related Packages

Explore complementary production-grade libraries built for high-performance Flutter & Dart development:

| Package | Description | Version |
| :--- | :--- | :--- |
| **[`ambient_backdrop_glow`](https://pub.dev/packages/ambient_backdrop_glow)** | Dynamic ambient background glow and fluid animated mesh gradients from image artwork with OKLab color blending for Flutter. | `^1.1.2` |
| **[`cron_schedule`](https://pub.dev/packages/cron_schedule)** | Lightweight, pure-Dart cron parser, next-occurrence predictor, human-readable translator, and fluent schedule builder for Dart and Flutter. | `^1.1.1` |
| **[`currency_field_formatter`](https://pub.dev/packages/currency_field_formatter)** | Bulletproof Flutter currency TextInputFormatter with exact cursor tracking, backspace handling, Indian Lakhs/Crores, and ISO 4217 presets. | `^1.1.1` |
| **[`flutter_whisper`](https://pub.dev/packages/flutter_whisper)** | On-device speech-to-text transcription using whisper.cpp. Automatic model download, streaming segment results, Android support. | `^0.2.1` |
| **[`offline_outbox`](https://pub.dev/packages/offline_outbox)** | Resilient offline-first outbox and retry queue for Dart and Flutter with disk persistence, exponential backoff, priority scheduling, and deduplication. | `^1.1.1` |
| **[`quote_painter`](https://pub.dev/packages/quote_painter)** | Flutter package for rendering styled text on image/video canvas with gradient fill, stroke, shadow, decorative quotation marks, line badges, and themes. | `^0.2.4` |
| **[`scratch_reveal`](https://pub.dev/packages/scratch_reveal)** | High-performance GPU-accelerated scratch card and scratch-to-reveal canvas widget for Flutter with sub-millisecond bitmask progress tracking. | `^1.1.1` |
| **[`segmented_ring_painter`](https://pub.dev/packages/segmented_ring_painter)** | High-performance segmented circular progress and concentric activity ring widget for Flutter with gradient arcs, rounded caps, gap math, and tap hit-testing. | `^1.1.2` |
| **[`waveform_pro`](https://pub.dev/packages/waveform_pro)** | Production-quality Flutter waveform widget with GPU-accelerated rendering, discrete bars, curved splines, dual-color progress, zoom, markers, and audio peak extraction. | `^1.1.4` |

---

## 💖 Support the Project

If you find this project useful, consider supporting its active maintenance and future development:

<p align="left">
  <a href="https://buymeacoffee.com/govindtanko"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee" /></a>
  <a href="https://github.com/sponsors/govindtank"><img src="https://img.shields.io/badge/GitHub%20Sponsors-EA4AAA?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Sponsors" /></a>
  <a href="https://www.patreon.com/govindtank"><img src="https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon" /></a>
</p>

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

*Maintained with ❤️ by [Govind Tank](https://github.com/govindtank).*
