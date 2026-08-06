import 'package:mobile_num_kit/mobile_num_kit.dart';

void main() {
  final kit = MobileNumberKit();

  // Warm up lazy metadata load + regex compile.
  for (var i = 0; i < 1000; i++) {
    kit.validate('+919876543210');
    kit.forRegion('AR').validate('91123456789');
  }

  const n = 100000;
  final sw = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    kit.validate('+919876543210');
  }
  sw.stop();
  final perIntl = sw.elapsedMicroseconds / n;

  final sw2 = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    kit.forRegion('IN').validate('9876543210');
  }
  sw2.stop();
  final perPinned = sw2.elapsedMicroseconds / n;

  print('validate(+91...)   : ${perIntl.toStringAsFixed(2)} µs/op');
  print('forRegion(IN).v... : ${perPinned.toStringAsFixed(2)} µs/op');
}
