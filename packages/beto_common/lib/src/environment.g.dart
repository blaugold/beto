// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Environment _$EnvironmentFromJson(Map<String, dynamic> json) => Environment(
      startTime: DateTime.parse(json['startTime'] as String),
      commit: json['commit'] as String?,
      device: json['device'] as String,
      os: Os.fromJson(json['os'] as Map<String, dynamic>),
      cpu: Cpu.fromJson(json['cpu'] as Map<String, dynamic>),
      runtime: json['runtime'] == null
          ? null
          : Runtime.fromJson(json['runtime'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EnvironmentToJson(Environment instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'commit': instance.commit,
      'device': instance.device,
      'os': instance.os,
      'cpu': instance.cpu,
      'runtime': instance.runtime,
    };

Os _$OsFromJson(Map<String, dynamic> json) => Os(
      type: $enumDecode(_$OsTypeEnumMap, json['type']),
      versionString: json['versionString'] as String,
    );

Map<String, dynamic> _$OsToJson(Os instance) => <String, dynamic>{
      'type': _$OsTypeEnumMap[instance.type]!,
      'versionString': instance.versionString,
    };

const _$OsTypeEnumMap = {
  OsType.android: 'android',
  OsType.ios: 'ios',
  OsType.linux: 'linux',
  OsType.macos: 'macos',
  OsType.windows: 'windows',
};

Cpu _$CpuFromJson(Map<String, dynamic> json) => Cpu(
      model: json['model'] as String,
      arch: $enumDecode(_$ArchEnumMap, json['arch']),
      cores: json['cores'] as int,
    );

Map<String, dynamic> _$CpuToJson(Cpu instance) => <String, dynamic>{
      'model': instance.model,
      'arch': _$ArchEnumMap[instance.arch]!,
      'cores': instance.cores,
    };

const _$ArchEnumMap = {
  Arch.x86: 'x86',
  Arch.x64: 'x64',
  Arch.arm: 'arm',
  Arch.arm64: 'arm64',
  Arch.ia64: 'ia64',
};

Runtime _$RuntimeFromJson(Map<String, dynamic> json) => Runtime(
      name: json['name'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$RuntimeToJson(Runtime instance) => <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
    };
