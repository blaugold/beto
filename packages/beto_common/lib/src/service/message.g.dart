// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitBenchmarkDataRequest _$SubmitBenchmarkDataRequestFromJson(
        Map<String, dynamic> json) =>
    SubmitBenchmarkDataRequest(
      suite: Suite.fromJson(json['suite'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmitBenchmarkDataRequestToJson(
        SubmitBenchmarkDataRequest instance) =>
    <String, dynamic>{
      'suite': instance.suite,
    };

QueryBenchmarkDataRequest _$QueryBenchmarkDataRequestFromJson(
        Map<String, dynamic> json) =>
    QueryBenchmarkDataRequest(
      suite: json['suite'] as String,
      benchmark: json['benchmark'] as String,
      device: json['device'] as String,
      range: const _QueryRangeJsonConverter().fromJson(json['range'] as List),
    );

Map<String, dynamic> _$QueryBenchmarkDataRequestToJson(
        QueryBenchmarkDataRequest instance) =>
    <String, dynamic>{
      'suite': instance.suite,
      'benchmark': instance.benchmark,
      'device': instance.device,
      'range': const _QueryRangeJsonConverter().toJson(instance.range),
    };

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
