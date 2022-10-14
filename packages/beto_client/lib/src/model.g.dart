// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitRange _$CommitRangeFromJson(Map<String, dynamic> json) => CommitRange(
      json['commit'] as String,
    );

Map<String, dynamic> _$CommitRangeToJson(CommitRange instance) =>
    <String, dynamic>{
      'commit': instance.commit,
    };

DateRange _$DateRangeFromJson(Map<String, dynamic> json) => DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$DateRangeToJson(DateRange instance) => <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
    };

QueryRequest _$QueryRequestFromJson(Map<String, dynamic> json) => QueryRequest(
      suite: json['suite'] as String,
      benchmark: json['benchmark'] as String,
      device: json['device'] as String,
      range: const _QueryRangeJsonConverter().fromJson(json['range'] as List),
    );

Map<String, dynamic> _$QueryRequestToJson(QueryRequest instance) =>
    <String, dynamic>{
      'suite': instance.suite,
      'benchmark': instance.benchmark,
      'device': instance.device,
      'range': const _QueryRangeJsonConverter().toJson(instance.range),
    };
