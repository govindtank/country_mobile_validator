#!/usr/bin/env python3
"""
Extract mobile number validation metadata from Google libphonenumber XML
into a compact, Dart-embeddable JSON dataset.

Source: https://github.com/google/libphonenumber (Apache-2.0)
  resources/PhoneNumberMetadata.xml

Output: tools/data/regions.json (compact, one object per territory)
"""
import json
import re
import sys
import xml.etree.ElementTree as ET

XML_PATH = "/tmp/lpn_metadata.xml"
OUT_PATH = "tools/data/regions.json"

def norm_pattern(text):
    """Strip whitespace/newlines from a libphonenumber regex so Dart RegExp accepts it."""
    if not text:
        return ""
    return re.sub(r"\s+", "", text)

def parse_lengths(elem, attr="national"):
    """Parse possibleLengths like '10,11' or '[6-8]' into (min,max) or None."""
    if elem is None:
        return None
    raw = elem.get(attr, "")
    if not raw:
        return None
    nums = []
    for part in raw.split(","):
        part = part.strip()
        m = re.match(r"\[(\d+)-(\d+)\]", part)
        if m:
            nums += list(range(int(m.group(1)), int(m.group(2)) + 1))
        else:
            nums.append(int(part))
    return (min(nums), max(nums)) if nums else None

def main():
    tree = ET.parse(XML_PATH)
    root = tree.getroot()
    regions = []
    seen_cc = {}

    territories = root.find("territories")

    for terr in territories.findall("territory"):
        rid = terr.get("id")
        if rid == "001":
            continue  # non-geographical entities handled separately below
        cc = int(terr.get("countryCode"))
        region = {
            "id": rid,
            "cc": cc,
            "prefix": terr.get("nationalPrefix") or "",
            "main": terr.get("mainCountryForCode") == "true",
        }

        # --- mobile ---
        mob = terr.find("mobile")
        if mob is not None:
            region["mob_len"] = parse_lengths(mob.find("possibleLengths"))
            pat = mob.find("nationalNumberPattern")
            if pat is not None and pat.text:
                region["mob_pat"] = norm_pattern(pat.text)
            ex = mob.find("exampleNumber")
            if ex is not None and ex.text:
                region["mob_ex"] = ex.text

        # --- fixedLine (for mobile-vs-landline disambiguation) ---
        fx = terr.find("fixedLine")
        if fx is not None:
            pat = fx.find("nationalNumberPattern")
            if pat is not None and pat.text:
                region["fx_pat"] = norm_pattern(pat.text)
            region["fx_len"] = parse_lengths(fx.find("possibleLengths"))

        # --- special types (flag, don't silently accept) ---
        for tname, key in [("tollFree", "tf"), ("premiumRate", "pr"),
                           ("shortCode", "sc"), ("sharedCost", "shc")]:
            el = terr.find(tname)
            if el is None:
                continue
            pat = el.find("nationalNumberPattern")
            if pat is not None and pat.text:
                region[key + "_pat"] = norm_pattern(pat.text)
            region[key + "_len"] = parse_lengths(el.find("possibleLengths"))

        # --- leading digits hint for mobile (faster reject) ---
        ld = terr.find("leadingDigits")
        if ld is not None and ld.text:
            region["ld"] = norm_pattern(ld.text)

        regions.append(region)
        seen_cc.setdefault(cc, []).append(rid)

    # Non-geographical entities (001): +800, +808, +870, +881..883, +888, +979, +991
    # Represent as pseudo-regions with id "X<cc>" so they're still validated.
    for terr in territories.findall("territory"):
        if terr.get("id") != "001":
            continue
        cc = int(terr.get("countryCode"))
        region = {"id": f"X{cc}", "cc": cc, "prefix": "", "main": True, "nonGeo": True}
        mob = terr.find("mobile")
        if mob is not None:
            pat = mob.find("nationalNumberPattern")
            if pat is not None and pat.text:
                region["mob_pat"] = norm_pattern(pat.text)
            region["mob_len"] = parse_lengths(mob.find("possibleLengths"))
        regions.append(region)

    regions.sort(key=lambda r: r["cc"])
    with open(OUT_PATH, "w") as f:
        json.dump(regions, f, separators=(",", ":"))

    n_mobile = sum(1 for r in regions if "mob_pat" in r)
    print(f"territories: {len(regions)} (incl. {sum(1 for r in regions if r.get('nonGeo'))} non-geo)")
    print(f"with mobile pattern: {n_mobile}")
    print(f"with mobile lengths: {sum(1 for r in regions if 'mob_len' in r)}")
    print(f"output: {OUT_PATH} ({len(json.dumps(regions, separators=(',', ':')))} bytes)")

    # spot checks
    for rid in ["IN", "US", "AR", "NZ", "BR", "DE", "GB"]:
        r = next((x for x in regions if x["id"] == rid), None)
        print(f"  {rid}: cc={r['cc']} mob_len={r.get('mob_len')} mob_ex={r.get('mob_ex')}")

if __name__ == "__main__":
    main()
