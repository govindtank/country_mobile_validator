## 0.4.0

* **Telecom Carrier & Network Detection (`CarrierDetector`)**: Instant operator and telecom circle mapping for mobile numbers:
  * Detects major Indian carriers (Jio True 5G, Airtel 5G Plus, Vi, BSNL) and service circles (e.g. Maharashtra, Delhi NCR, Karnataka).
  * Direct detection API: `CarrierDetector.detect(number)` and string extension `number.detectCarrier()`.
* **Zero-Boilerplate String Extensions**: Direct validation and formatting helpers on `String`:
  * `isValidMobile([region])`: One-line boolean check.
  * `isOtpDeliverable([region])`: Rejects toll-free, premium, and landline destinations.
  * `toE164([region])`: Canonical international E.164 string (`+919876543210`).
  * `toWhatsAppUrl({message})`: One-click WhatsApp direct chat link generator (`https://wa.me/919876543210?text=...`).
  * `formatNational([region])`: Formats into readable local groups (`98765 43210`).
* **Upgraded Vector Visual Showcase**: High-resolution 1200x680 diagram illustrating real authentication input mockups, carrier chips, and WhatsApp links.
* **100% Test Coverage**: Expanded unit tests across carrier detection rules and extension methods.

## 0.3.1

* **Discovery & Metadata**: Added official funding channels and refined search discovery topics.

## 0.3.0

* **International E.164 Formatting**: Polished E.164 and national formatting pipelines with country code prefix normalization.
* **Corpus & Performance**: Verified international golden corpus across all ISO 3166-1 alpha-2 regions.

## 0.2.2

* docs: update centered vector badges and documentation.

## 0.2.1

* Added `formatE164()` and `formatNational()` helpers to `MobileValidator`.
* Cleaned package layout conventions and verified CI/CD workflows.

## 0.2.0

* **Breaking**: renamed the entry class `MobileNumberKit` → `CountryMobileValidator` (matches the package name; old name is gone everywhere — code, docs, tests, SVG).
* **New**: zero-setup top-level API — `validateMobile(input, {countryCode})` and a global `mobileValidator` instance. Unknown `countryCode` returns an invalid result instead of throwing.
* README rewritten: shorter, scannable, integration-first.

## 0.1.1

* Full 160/160 pub.dev score: fixed doc-comment HTML warnings, formatted source, added topics, trimmed description, CHANGELOG entry.
* `MetadataUpdater` doc reference now points to `loadRefreshedMetadata`.

## 0.1.0

* Initial release.
* Pure Dart mobile-only validator for 254 regions (libphonenumber metadata, Apache-2.0).
* Queryable per-country mobile length ranges (AR 10–11, NZ 8–10, …).
* Mobile / fixed-line / toll-free / premium-rate / shared-cost / short-code type detection; OTP-deliverability verdict.
* Auto country-code detection with longest-prefix match and multi-region resolution (`+1` → US/CA/…, `+44` → GB/GG/JE/IM).
* Input normalization: separators, Unicode digits, extensions, trunk prefixes.
* Refreshable metadata via `MetadataUpdater` (SHA-256 verified, offline fallback).
* Golden corpus test suite over all 247 mobile-enabled regions.
