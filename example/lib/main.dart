import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_mobile_validator/country_mobile_validator.dart';
import 'package:flutter/material.dart';

/// Complete demo of `country_mobile_validator` + `country_code_picker`.
///
/// Shows every library feature:
///  1. Pick a country (flag + dial code) — country_code_picker.
///  2. Live length feedback while typing, using the country's REAL mobile
///     length range (e.g. AR 10–11, NZ 8–10, IN 10).
///  3. OTP-safe verdict on submit: mobile-only, type-aware
///     (toll-free/premium/landline are rejected as mobile).
///  4. Smart auto-detection: paste a full international number (+CC...) and
///     the region is detected automatically.
void main() => runApp(const ValidatorDemoApp());

class ValidatorDemoApp extends StatelessWidget {
  const ValidatorDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Country Mobile Validator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ValidatorScreen(),
    );
  }
}

class ValidatorScreen extends StatefulWidget {
  const ValidatorScreen({super.key});

  @override
  State<ValidatorScreen> createState() => _ValidatorScreenState();
}

class _ValidatorScreenState extends State<ValidatorScreen> {
  final kit = MobileNumberKit();
  final controller = TextEditingController();

  CountryCode? _country; // picked via country_code_picker
  ValidationResult? _result;
  bool _liveInRange = false;
  int _liveLength = 0;

  /// Known-good mobile numbers per country so the demo is one tap away.
  static const _samples = <String, String>{
    'IN': '9876543210', // India — 10 digits
    'US': '4155552671', // US — 10 digits (NANP)
    'AR': '91123456789', // Argentina — 10–11 digits
    'NZ': '21123456', // New Zealand — 8–10 digits
    'BR': '11961234567', // Brazil — 10–11 digits
    'DE': '15123456789', // Germany — 10–11 digits
    'GB': '7400123456', // UK — 10 digits
    'ID': '81234567890', // Indonesia — 9–12 digits
  };

  @override
  void initState() {
    super.initState();
    // Seed the picker's default so the demo works before the user touches it.
    _country = CountryCode.fromCountryCode('IN');
    controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final digits = controller.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _liveLength = digits.length;
      _liveInRange = _country != null &&
          kit.forRegion(_country!.code!).isMobileLength(_liveLength);
    });
  }

  String _lengthHint() {
    if (_country == null) return 'Pick a country first';
    return '${_country!.dialCode} · ${kit.forRegion(_country!.code!).lengthHint}';
  }

  void _fillSample() {
    final sample = _samples[_country?.code];
    if (sample != null) {
      controller.text = sample;
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
  }

  /// 1) Pinned path — the country_code_picker workflow:
  ///    country from the picker + national-format input, validated against
  ///    that country's real mobile length range and prefix pattern.
  void _validatePinned() {
    final country = _country;
    if (country == null) {
      _showSnack('Pick a country first 🇮🇳');
      return;
    }
    setState(() {
      _result = kit.validateForCountry(country.code!, controller.text);
    });
  }

  /// 2) Smart path — auto-detect region from a full international number.
  void _validateAuto() {
    final input = controller.text.trim();
    if (input.isEmpty) {
      _showSnack('Enter a number first');
      return;
    }
    setState(() {
      _result = kit.validate(input);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final picked = _country;
    final hint = _lengthHint();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Mobile Validator'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'metadata ${kit.metadataVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Step 1: pick the country ────────────────────────────────
          Card(
            child: ListTile(
              title: const Text('1 · Pick a country'),
              subtitle: const Text('country_code_picker'),
              trailing: CountryCodePicker(
                initialSelection: 'IN',
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                favorite: const ['+91', 'IN', '+1', 'US'],
                onChanged: (c) => setState(() => _country = c),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Step 2: type the number — live range feedback ──────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2 · Enter mobile number',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixText: picked?.dialCode == null
                          ? null
                          : '${picked!.dialCode} ',
                      hintText:
                          'e.g. ${_samples[picked?.code] ?? '9876543210'}',
                      suffixIcon: picked != null
                          ? IconButton(
                              icon: const Icon(Icons.auto_fix_high),
                              tooltip: 'Fill sample',
                              onPressed: _fillSample,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _liveInRange ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: _liveInRange ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          picked == null
                              ? 'Pick a country to see its real mobile length range'
                              : _liveInRange
                                  ? '✓ $_liveLength digits — inside the valid range ($hint)'
                                  : '$_liveLength digits so far — needs $hint',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Step 3: validate ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _validatePinned,
                  icon: const Icon(Icons.flag),
                  label: const Text('Validate for country'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _validateAuto,
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Auto-detect (+CC)'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Result ──────────────────────────────────────────────────
          if (_result != null) _ResultCard(result: _result!),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ValidationResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isValid && result.isMobile;
    final color = ok ? Colors.green : Colors.red.shade400;

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.cancel, color: color),
                const SizedBox(width: 8),
                Text(
                  ok
                      ? 'Valid ${result.isOtpDeliverable ? '& OTP-deliverable' : 'mobile'}'
                      : 'Not a valid mobile',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv(context, 'Region', result.regionCode ?? '—'),
            _kv(context, 'Type', result.type.name),
            _kv(context, 'isMobile', '${result.isMobile}'),
            _kv(context, 'isOtpDeliverable', '${result.isOtpDeliverable}'),
            _kv(
                context,
                'Mobile length range',
                result.mobileRange == null
                    ? '—'
                    : '${result.mobileRange!.min}–${result.mobileRange!.max} digits'),
            _kv(context, 'Issue (if invalid)', result.issue.name),
            _kv(context, 'Metadata version', result.metadataVersion),
            const SizedBox(height: 8),
            Text(
              ok
                  ? 'This number matches the mobile pattern for ${result.regionCode}. '
                      'OTP is safe to send.'
                  : 'Rejected by ${result.regionCode ?? 'region'} rules — '
                      '${_explain(result)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _explain(ValidationResult r) {
    final digits = r.nationalNumber?.length ??
        r.input.replaceAll(RegExp(r'\D'), '').length;
    return switch (r.issue) {
      ValidationIssue.tooShort => 'too short ($digits digits)',
      ValidationIssue.tooLong => 'too long',
      ValidationIssue.invalidPrefix => 'prefix not assigned to mobiles',
      ValidationIssue.unknownCountry => 'unknown country code',
      _ => 'does not match the mobile pattern',
    };
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(k, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(v,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
