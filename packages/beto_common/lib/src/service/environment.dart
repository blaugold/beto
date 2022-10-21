import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '../io_utils.dart';
import 'validate.dart';

part 'environment.g.dart';

/// Describes the environment in which benchmark data was recorded.
@JsonSerializable()
class Environment {
  /// Creates a new [Environment].
  Environment({
    required this.device,
    required this.os,
    required this.cpu,
    this.runtime,
  });

  /// Creates an [Environment] describing the current environment.
  ///
  /// This is a convenience method for creating an [Environment] with the
  /// current [Os], [Cpu]. The [runtime] defaults to the current
  /// [Dart Runtime][Runtime.dart].
  factory Environment.current({
    required String device,
    Os? os,
    Cpu? cpu,
    Runtime? runtime,
  }) =>
      Environment(
        device: device,
        os: os ?? Os.current(),
        cpu: cpu ?? Cpu.current(),
        runtime: runtime ?? Runtime.dart(),
      );

  /// Creates an [Environment] from JSON.
  factory Environment.fromJson(Map<String, Object?> json) =>
      _$EnvironmentFromJson(json);

  /// An identifier for the device model.
  ///
  /// It must only contain alphanumeric characters and underscores.
  final String device;

  /// The operating system .
  final Os os;

  /// The CPU.
  final Cpu cpu;

  /// The runtime.
  final Runtime? runtime;

  /// Validates this [Environment].
  void validate() {
    validateAlphaNumericIdentifier('Environment.device', device);
  }

  @override
  String toString() => 'Environment('
      'device: $device, '
      'os: $os, '
      'cpu: $cpu, '
      'runtime: $runtime'
      ')';

  Map<String, Object?> toJson() => _$EnvironmentToJson(this);
}

/// A type of operating system.
enum OsType {
  android,
  ios,
  linux,
  macos,
  windows,
}

/// Describes an operating system.
@JsonSerializable()
class Os {
  /// Creates a new [Os].
  Os({
    required this.type,
    required this.versionString,
  });

  /// Creates an [Os] from JSON.
  factory Os.fromJson(Map<String, Object?> json) => _$OsFromJson(json);

  /// Creates an [Os] describing the current operating system.
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

  /// The type of operating system.
  final OsType type;

  /// A string describing the version of the operating system.
  ///
  /// This is not a structured, stable representation of the version.
  final String versionString;

  @override
  String toString() => 'Os(type: $type, versionString: $versionString)';

  Map<String, Object?> toJson() => _$OsToJson(this);
}

/// A CPU architecture.
enum Arch {
  x86,
  x64,
  arm,
  arm64,
  ia64,
}

/// Describes a CPU.
@JsonSerializable()
class Cpu {
  /// Creates a new [Cpu].
  Cpu({
    required this.model,
    required this.arch,
    required this.cores,
  });

  /// Creates a [Cpu] from JSON.
  factory Cpu.fromJson(Map<String, Object?> json) => _$CpuFromJson(json);

  /// Creates a [Cpu] describing the current CPU.
  factory Cpu.current() => Cpu(
        model: _currentModel(),
        arch: _currentArch(),
        cores: Platform.numberOfProcessors,
      );

  /// The model of the CPU.
  final String model;

  /// The architecture of the CPU.
  final Arch arch;

  /// The number of cores on the CPU.
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

/// Describes a runtime.
@JsonSerializable()
class Runtime {
  /// Creates a new [Runtime].
  Runtime({
    required this.name,
    required this.version,
  });

  /// Creates a [Runtime] from JSON.
  factory Runtime.fromJson(Map<String, Object?> json) =>
      _$RuntimeFromJson(json);

  /// Creates a [Runtime] describing the current Dart VM.
  factory Runtime.dart() => Runtime(
        name: 'Dart',
        version: Platform.version.split(' ').first,
      );

  /// The name of the runtime.
  final String name;

  /// The release version of the runtime.
  final String version;

  @override
  String toString() => 'Runtime(name: $name, version: $version)';

  Map<String, Object?> toJson() => _$RuntimeToJson(this);
}
