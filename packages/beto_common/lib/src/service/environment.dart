import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '../io_utils.dart';

part 'environment.g.dart';

@JsonSerializable()
class Environment {
  Environment({
    required this.startTime,
    this.commit,
    required this.device,
    required this.os,
    required this.cpu,
    this.runtime,
  });

  factory Environment.fromJson(Map<String, Object?> json) =>
      _$EnvironmentFromJson(json);

  final DateTime startTime;
  final String? commit;
  final String device;
  final Os os;
  final Cpu cpu;
  final Runtime? runtime;

  @override
  String toString() => 'Environment('
      'startTime: $startTime, '
      'commit: $commit, '
      'device: $device, '
      'os: $os, '
      'cpu: $cpu, '
      'runtime: $runtime'
      ')';

  Map<String, Object?> toJson() => _$EnvironmentToJson(this);
}

enum OsType {
  android,
  ios,
  linux,
  macos,
  windows,
}

@JsonSerializable()
class Os {
  Os({
    required this.type,
    required this.versionString,
  });

  factory Os.fromJson(Map<String, Object?> json) => _$OsFromJson(json);

  factory Os.current() {
    final OsType type;
    if (Platform.isAndroid) {
      type = OsType.android;
    } else if (Platform.isIOS) {
      type = OsType.ios;
    } else if (Platform.isLinux) {
      type = OsType.linux;
    } else if (Platform.isMacOS) {
      type = OsType.macos;
    } else if (Platform.isWindows) {
      type = OsType.windows;
    } else {
      throw UnimplementedError('Unimplemented OS: ${Platform.operatingSystem}');
    }
    return Os(
      type: type,
      versionString: Platform.operatingSystemVersion,
    );
  }

  final OsType type;
  final String versionString;

  @override
  String toString() => 'Os(type: $type, versionString: $versionString)';

  Map<String, Object?> toJson() => _$OsToJson(this);
}

enum Arch {
  x86,
  x64,
  arm,
  arm64,
  ia64,
}

@JsonSerializable()
class Cpu {
  Cpu({
    required this.model,
    required this.arch,
    required this.cores,
  });

  factory Cpu.fromJson(Map<String, Object?> json) => _$CpuFromJson(json);

  factory Cpu.current() => Cpu(
        model: _currentModel(),
        arch: _currentArch(),
        cores: Platform.numberOfProcessors,
      );

  final String model;
  final Arch arch;
  final int cores;

  @override
  String toString() => 'Cpu(model: $model, arch: $arch, cores: $cores)';

  Map<String, Object?> toJson() => _$CpuToJson(this);

  static String _currentModel() {
    if (Platform.isMacOS || Platform.isIOS) {
      return runProcess('sysctl', ['-n', 'machdep.cpu.brand_string']);
    } else if (Platform.isAndroid || Platform.isLinux || Platform.isFuchsia) {
      final lscpuOutput = runProcess('lscpu', []);
      final modelLine = lscpuOutput
          .split('\n')
          .firstWhere((element) => element.startsWith('Model:'));
      return modelLine.split(':')[1].trim();
    } else if (Platform.isWindows) {
      return runProcess(
        'powershell',
        ['(Get-CimInstance -ClassName Win32_BIOS).Name'],
      );
    } else {
      throw UnimplementedError('Unimplemented OS: ${Platform.operatingSystem}');
    }
  }

  static Arch _currentArch() {
    if (Platform.isWindows) {
      final architecture = Platform.environment['PROCESSOR_ARCHITECTURE'];
      switch (architecture) {
        case 'X86':
          return Arch.x86;
        case 'AMD64':
          return Arch.x64;
        case 'ARM64':
          return Arch.arm64;
        case 'IA64':
          return Arch.ia64;
        default:
          throw UnimplementedError('Unknown architecture: $architecture');
      }
    } else {
      final architecture = runProcess('uname', ['-m']);
      switch (architecture) {
        case 'i386':
        case 'i686':
          return Arch.x86;
        case 'x86_64':
          return Arch.x64;
        case 'arm':
          return Arch.arm;
        case 'aarch64_be':
        case 'aarch64':
        case 'armv8b':
        case 'armv8l':
        case 'arm64':
          return Arch.arm64;
        case 'ia64':
          return Arch.ia64;
        default:
          throw UnimplementedError('Unknown architecture: $architecture');
      }
    }
  }
}

@JsonSerializable()
class Runtime {
  Runtime({
    required this.name,
    required this.version,
  });

  factory Runtime.fromJson(Map<String, Object?> json) =>
      _$RuntimeFromJson(json);

  factory Runtime.dart() => Runtime(
        name: 'Dart',
        version: Platform.version.split(' ').first,
      );

  final String name;
  final String version;

  @override
  String toString() => 'Runtime(name: $name, version: $version)';

  Map<String, Object?> toJson() => _$RuntimeToJson(this);
}
