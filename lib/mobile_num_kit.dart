/// mobile_num_kit — real-time updated, range-aware mobile number validation.
///
/// Pure Dart core: works on Flutter, Dart VM, and the web.
library;

export 'src/store.dart' show RegionInfo, RegionsStore;
export 'src/data/regions_data.dart' show kRegionsJson;
export 'src/types.dart' show NumberRange, NumberType, ValidationIssue, ValidationResult;
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
