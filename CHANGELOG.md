## 0.1.0

- Initial release.
- Pure Dart mobile-only validator for 254 regions (libphonenumber metadata,
  Apache-2.0).
- Queryable per-country mobile length ranges (AR 10–11, NZ 8–10, …).
- Mobile / fixed-line / toll-free / premium-rate / shared-cost / short-code
  type detection; OTP-deliverability verdict.
- Auto country-code detection with longest-prefix match and multi-region
  resolution (`+1` → US/CA/…, `+44` → GB/GG/JE/IM).
- Input normalization: separators, Unicode digits, extensions, trunk prefixes.
- Refreshable metadata via `MetadataUpdater` (SHA-256 verified, offline
  fallback).
- Golden corpus test suite over all 247 mobile-enabled regions.
