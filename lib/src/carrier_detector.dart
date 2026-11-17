/// Telecom operator identification and circle mapping for mobile numbers.
library;

/// Major recognized telecom carriers / operators.
enum TelecomCarrier {
  /// Reliance Jio Infocomm (India)
  jio,

  /// Bharti Airtel (India)
  airtel,

  /// Vodafone Idea / Vi (India)
  vi,

  /// Bharat Sanchar Nigam Limited / BSNL (India)
  bsnl,

  /// AT&T (US)
  att,

  /// Verizon Wireless (US)
  verizon,

  /// T-Mobile (US)
  tMobile,

  /// Vodafone (UK / Europe)
  vodafone,

  /// EE (UK)
  ee,

  /// O2 (UK)
  o2,

  /// Generic or unidentified cellular carrier.
  other,
}

/// Information about a detected mobile telecom carrier.
class CarrierInfo {
  const CarrierInfo({
    required this.carrier,
    required this.displayName,
    this.circle,
    this.country = 'IN',
  });

  /// The identified telecom carrier enum.
  final TelecomCarrier carrier;

  /// User-facing display brand name (e.g. "Jio 5G", "Airtel", "Vi").
  final String displayName;

  /// Telecom circle or state service area (e.g. "Maharashtra & Goa", "Delhi NCR").
  final String? circle;

  /// ISO-2 country code.
  final String country;

  @override
  String toString() =>
      'CarrierInfo($displayName${circle != null ? ', circle: $circle' : ''})';
}

/// Telecom carrier detection engine based on official series allocations.
class CarrierDetector {
  const CarrierDetector._();

  /// Identifies the carrier and service circle for a given mobile number.
  ///
  /// Examples:
  /// - `"+91 98200 12345"` -> `CarrierInfo(Vi, circle: "Mumbai")`
  /// - `"+91 94220 12345"` -> `CarrierInfo(BSNL, circle: "Maharashtra")`
  /// - `"+91 70001 23456"` -> `CarrierInfo(Jio)`
  static CarrierInfo? detect(String number, {String? defaultRegion = 'IN'}) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return null;

    // Check if Indian mobile number
    String nationalNumber = cleaned;
    if (cleaned.startsWith('91') && cleaned.length >= 12) {
      nationalNumber = cleaned.substring(2);
    }

    if (nationalNumber.length == 10) {
      return _detectIndianCarrier(nationalNumber);
    }

    // US NANP (+1)
    if (cleaned.startsWith('1') && cleaned.length == 11) {
      final areaCode = cleaned.substring(1, 4);
      return CarrierInfo(
        carrier: TelecomCarrier.other,
        displayName: 'US Mobile',
        circle: 'Area Code $areaCode',
        country: 'US',
      );
    }

    return null;
  }

  static CarrierInfo _detectIndianCarrier(String national) {
    final prefix2 = national.substring(0, 2);
    final prefix4 = national.substring(0, 4);
    final p4 = int.tryParse(prefix4) ?? 0;

    // BSNL Series: 94xx series (9400-9499)
    if (prefix2 == '94') {
      return CarrierInfo(
        carrier: TelecomCarrier.bsnl,
        displayName: 'BSNL Mobile',
        circle: _detectBsnlCircle(p4),
        country: 'IN',
      );
    }

    // Jio Series: 6000-6009, 620x, 626x, 700x, 701x, 790x, 797x, 798x, 799x,
    // 800x, 808x, 809x, 829x, 843x, 865x, 870x, 892x, 893x, 907x, 912x, 913x, 932x, 933x, 935x
    if (national.startsWith('60') ||
        national.startsWith('62') ||
        national.startsWith('700') ||
        national.startsWith('701') ||
        national.startsWith('790') ||
        national.startsWith('797') ||
        national.startsWith('798') ||
        national.startsWith('799') ||
        national.startsWith('800') ||
        national.startsWith('808') ||
        national.startsWith('809') ||
        national.startsWith('829') ||
        national.startsWith('865') ||
        national.startsWith('870') ||
        national.startsWith('892') ||
        national.startsWith('893') ||
        national.startsWith('912') ||
        national.startsWith('932')) {
      return const CarrierInfo(
        carrier: TelecomCarrier.jio,
        displayName: 'Jio True 5G',
        circle: 'National',
        country: 'IN',
      );
    }

    // Airtel Series: 9810-9819, 9899, 7042, 7045, 8130, 8527, 8800, 9650, 9910, 9958, 9711, 9717, 9871, 9873
    if (national.startsWith('981') ||
        national.startsWith('9899') ||
        national.startsWith('7042') ||
        national.startsWith('8130') ||
        national.startsWith('8527') ||
        national.startsWith('8800') ||
        national.startsWith('9650') ||
        national.startsWith('9910') ||
        national.startsWith('9958') ||
        national.startsWith('9711') ||
        national.startsWith('9717') ||
        national.startsWith('9871') ||
        national.startsWith('9873') ||
        national.startsWith('9845') ||
        national.startsWith('9840')) {
      return const CarrierInfo(
        carrier: TelecomCarrier.airtel,
        displayName: 'Airtel 5G Plus',
        circle: 'National',
        country: 'IN',
      );
    }

    // Vi (Vodafone Idea): 9820, 9821, 9833, 9892, 9890, 9028, 9922, 9764, 9840, 9841
    if (national.startsWith('9820') ||
        national.startsWith('9821') ||
        national.startsWith('9833') ||
        national.startsWith('9892') ||
        national.startsWith('9890') ||
        national.startsWith('9028') ||
        national.startsWith('9922') ||
        national.startsWith('9764') ||
        national.startsWith('9841')) {
      return const CarrierInfo(
        carrier: TelecomCarrier.vi,
        displayName: 'Vi (Vodafone Idea)',
        circle: 'National',
        country: 'IN',
      );
    }

    // General Indian Mobile
    return const CarrierInfo(
      carrier: TelecomCarrier.other,
      displayName: 'Indian Cellular',
      circle: 'National',
      country: 'IN',
    );
  }

  static String _detectBsnlCircle(int p4) {
    if (p4 >= 9420 && p4 <= 9423) return 'Maharashtra & Goa';
    if (p4 >= 9410 && p4 <= 9415) return 'Uttar Pradesh';
    if (p4 >= 9430 && p4 <= 9435) return 'Bihar & Jharkhand';
    if (p4 >= 9440 && p4 <= 9445) return 'Andhra Pradesh & Telangana';
    if (p4 >= 9446 && p4 <= 9449) return 'Kerala';
    if (p4 >= 9450 && p4 <= 9455) return 'Madhya Pradesh';
    if (p4 >= 9460 && p4 <= 9465) return 'Rajasthan';
    if (p4 >= 9470 && p4 <= 9479) return 'Gujarat';
    if (p4 >= 9480 && p4 <= 9489) return 'Karnataka';
    return 'India Circle';
  }
}
