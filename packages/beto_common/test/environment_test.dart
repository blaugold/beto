import 'dart:io';

import 'package:beto_common/beto_common.dart';
import 'package:test/test.dart';

void main() {
  group('Os', () {
    group('current', () {
      test('smoke test', () {
        final os = Os.current();
        expect(os.versionString, Platform.operatingSystemVersion);
      });
    });
  });

  group('Cpu', () {
    group('current', () {
      test('smoke test', () {
        final cpu = Cpu.current();
        expect(cpu.model, isNotEmpty);
        expect(cpu.cores, Platform.numberOfProcessors);
      });
    });
  });
}
