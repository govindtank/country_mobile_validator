# country_mobile_validator — example app

A complete, working demo of **`country_mobile_validator`** integrated with
**`country_code_picker`** — the exact workflow the library was built for.

## Run it

```bash
cd example
flutter pub get
flutter run          # on any device/emulator
```

## What the demo shows

| Step | Library feature |
|---|---|
| **1 · Pick a country** | `CountryCodePicker` (flag + dial code). |
| **2 · Enter number** | **Live length feedback** — as you type, it checks `isMobileLength(n)` against that country's *real* range (`10–11 digits` for AR, `8–10` for NZ, `10` for IN…) and shows `lengthHint`. A "fill sample" button loads a known-good number for the picked country. |
| **3 · Validate** | Two paths: **Validate for country** → `kit.validateForCountry(countryCode, input)` (national format, pinned to the picker's country) and **Auto-detect (+CC)** → `kit.validate('+CC…')` with region auto-detection. |
| **Result card** | `isValid`, `isMobile`, `isOtpDeliverable`, `type` (mobile / tollFree / premiumRate…), `regionCode`, the country's `mobileRange`, the rejection `issue` (tooShort / tooLong / invalidPrefix / unknownCountry), and the `metadataVersion` — staleness is always visible. |

## Try these numbers

- 🇮🇳 India: `9876543210` → valid & OTP-deliverable
- 🇦🇷 Argentina: `91123456789` (11) valid · `911234567` (9) → rejected, "needs 10–11 digits"
- 🇳🇿 New Zealand: `21123456` (8) valid — 7 digits rejected
- 🇺🇸 US: `4155552671` valid · `18005551234` → `tollFree`, NOT OTP-deliverable
- Any country: paste `+91…`/`+1…` full international and hit **Auto-detect**
