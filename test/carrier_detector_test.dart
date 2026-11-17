import 'package:country_mobile_validator/country_mobile_validator.dart';
import 'package:test/test.dart';

void main() {
  group('CarrierDetector & Mobile Extensions Tests', () {
    test('detects Jio mobile numbers accurately', () {
      final info = CarrierDetector.detect('+91 70001 23456');
      expect(info, isNotNull);
      expect(info!.carrier, equals(TelecomCarrier.jio));
      expect(info.displayName, contains('Jio'));
    });

    test('detects Airtel mobile numbers accurately', () {
      final info = '+91 98101 23456'.detectCarrier();
      expect(info, isNotNull);
      expect(info!.carrier, equals(TelecomCarrier.airtel));
      expect(info.displayName, contains('Airtel'));
    });

    test('detects Vi (Vodafone Idea) mobile numbers', () {
      final info = '+91 98200 12345'.detectCarrier();
      expect(info, isNotNull);
      expect(info!.carrier, equals(TelecomCarrier.vi));
      expect(info.displayName, contains('Vi'));
    });

    test('detects BSNL mobile numbers and state circle', () {
      final info = '+91 94220 12345'.detectCarrier();
      expect(info, isNotNull);
      expect(info!.carrier, equals(TelecomCarrier.bsnl));
      expect(info.circle, equals('Maharashtra & Goa'));
    });

    test('string extensions validate mobile and check OTP deliverability', () {
      expect('+91 98765 43210'.isValidMobile('IN'), isTrue);
      expect('+91 98765 43210'.isOtpDeliverable('IN'), isTrue);
      expect('+91 1800 111 222'.isValidMobile('IN'), isFalse); // Toll-free
    });

    test('generates valid WhatsApp direct click-to-chat link', () {
      final link = '+91 98765 43210'.toWhatsAppUrl(message: 'Hello Support');
      expect(link, equals('https://wa.me/919876543210?text=Hello%20Support'));
    });

    test('formats national numbers into readable groups', () {
      expect('+91 9876543210'.formatNational(), equals('98765 43210'));
    });
  });
}
