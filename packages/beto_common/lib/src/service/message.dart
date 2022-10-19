import 'package:json_annotation/json_annotation.dart';

import '../json_utils.dart';
import 'record.dart';

part 'message.g.dart';

@JsonSerializable()
class SubmitBenchmarkDataRequest {
  SubmitBenchmarkDataRequest({
    required this.record,
  });

  factory SubmitBenchmarkDataRequest.fromJson(Map<String, Object?> json) =>
      _$SubmitBenchmarkDataRequestFromJson(json);

  final BenchmarkRecord record;

  Map<String, Object?> toJson() => _$SubmitBenchmarkDataRequestToJson(this);
}

@JsonSerializable()
class QueryBenchmarkDataRequest {
  QueryBenchmarkDataRequest({
    required this.suite,
    required this.benchmark,
    required this.device,
    required this.range,
  });

  factory QueryBenchmarkDataRequest.fromJson(Map<String, Object?> json) =>
      _$QueryBenchmarkDataRequestFromJson(json);

  final String suite;
  final String benchmark;
  final String device;
  @_BenchmarkDataRangeJsonConverter()
  final BenchmarkDataRange range;

  Map<String, Object?> toJson() => _$QueryBenchmarkDataRequestToJson(this);
}

// ignore: one_member_abstracts
abstract class BenchmarkDataRange {
  Map<String, Object?> toJson();
}

class _BenchmarkDataRangeJsonConverter
    extends TaggedTypeConverter<BenchmarkDataRange> {
  const _BenchmarkDataRangeJsonConverter()
      : super(
          'BenchmarkDataRange',
          const {
            CommitRange: 'commit',
            DateRange: 'date',
          },
          const {
            'commit': CommitRange.fromJson,
            'date': DateRange.fromJson,
          },
        );
}

@JsonSerializable()
class CommitRange implements BenchmarkDataRange {
  CommitRange(this.commit);

  factory CommitRange.fromJson(Map<String, Object?> json) =>
      _$CommitRangeFromJson(json);

  final String commit;

  @override
  Map<String, Object?> toJson() => _$CommitRangeToJson(this);
}

@JsonSerializable()
class DateRange implements BenchmarkDataRange {
  DateRange({required this.start, required this.end});

  factory DateRange.fromJson(Map<String, Object?> json) =>
      _$DateRangeFromJson(json);

  final DateTime start;
  final DateTime end;

  @override
  Map<String, Object?> toJson() => _$DateRangeToJson(this);
}
