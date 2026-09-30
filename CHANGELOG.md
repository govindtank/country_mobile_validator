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
