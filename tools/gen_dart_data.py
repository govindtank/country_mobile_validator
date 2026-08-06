#!/usr/bin/env python3
"""Convert tools/data/regions.json into a Dart const file for embedding."""
import json

SRC = "tools/data/regions.json"
DST = "lib/src/data/regions_data.dart"

with open(SRC) as f:
    regions = json.load(f)

body = json.dumps(regions, separators=(",", ":"))
dart = f"""// GENERATED FILE — do not edit by hand.
// Run: python3 tools/gen_dart_data.py
// Source: Google libphonenumber PhoneNumberMetadata.xml (Apache-2.0)
// Compact per-territory mobile/fixed/special-type validation metadata.
// Size: {len(body)} bytes, {len(regions)} territories.

/// Raw JSON metadata, parsed lazily by [RegionsStore].
const String kRegionsJson = r'''{body}''';
"""
with open(DST, "w") as f:
    f.write(dart)
print(f"wrote {DST} ({len(dart)} bytes, {len(regions)} regions)")
