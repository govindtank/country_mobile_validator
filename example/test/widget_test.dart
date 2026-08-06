import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_mobile_validator_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valid India mobile → green OTP verdict', (tester) async {
    await tester.pumpWidget(const ValidatorDemoApp());

    // Type a valid Indian mobile (country defaults to IN on launch).
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();

    // Tap "Validate for country".
    await tester.tap(find.text('Validate for country'));
    await tester.pumpAndSettle();

    // Green verdict: valid & OTP-deliverable, region IN.
    expect(find.text('Valid & OTP-deliverable'), findsOneWidget);
    expect(find.text('IN'), findsWidgets);
  });

  testWidgets('too-short Argentina number → rejected with range hint',
      (tester) async {
    await tester.pumpWidget(const ValidatorDemoApp());

    // Open the picker and select Argentina (rows render as "+54 Argentina").
    await tester.tap(find.byType(CountryCodePicker));
    await tester.pumpAndSettle();
    // The country list is lazy — scroll until Argentina is built.
    await tester.scrollUntilVisible(
      find.textContaining('Argentina'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.textContaining('Argentina').last);
    await tester.pumpAndSettle();

    // 9 digits — below Argentina's 10–11 range.
    await tester.enterText(find.byType(TextField), '911234567');
    await tester.pumpAndSettle();

    // Live feedback shows the real range (hint is "+54 · 10–11 digits").
    expect(find.textContaining('10–11 digits'), findsOneWidget);

    await tester.tap(find.text('Validate for country'));
    await tester.pumpAndSettle();

    expect(find.text('Not a valid mobile'), findsOneWidget);
    expect(find.textContaining('too short (9 digits)'), findsOneWidget);
  });

  testWidgets('US toll-free flagged, not OTP-deliverable', (tester) async {
    await tester.pumpWidget(const ValidatorDemoApp());

    // Auto-detect path with a full international number.
    await tester.enterText(find.byType(TextField), '+18005551234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-detect (+CC)'));
    await tester.pumpAndSettle();

    expect(find.text('Not a valid mobile'), findsOneWidget);
    expect(find.text('tollFree'), findsOneWidget);
    expect(find.textContaining('false'), findsWidgets); // isOtpDeliverable false
  });
}
