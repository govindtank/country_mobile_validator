/// country_mobile_validator — validate mobile numbers per country with real
/// length ranges (8-10, 10-11 digits...), mobile-only type detection, and a
/// country_code_picker-friendly API.
///
/// Pure Dart core: works on Flutter, Dart VM, and the web.
library;

export 'src/store.dart' show RegionInfo, RegionsStore;
export 'src/data/regions_data.dart' show kRegionsJson;
export 'src/types.dart'
    show NumberRange, NumberType, ValidationIssue, ValidationResult;
export 'src/parser.dart' show ParsedNumber, parseNumber;
export 'src/updater.dart'
    show
        MetadataManifest,
        MetadataUpdateResult,
        MetadataUpdater,
        UrlFetcher,
        defaultUrlFetcher,
        sha256Hex;
export 'src/validator.dart' show MobileNumberKit, MobileValidator;
