// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Value _$ValueFromJson(Map<String, dynamic> json) => Value(
      statistic: $enumDecode(_$StatisticEnumMap, json['statistic']),
      value: (json['value'] as num).toDouble(),
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ValueToJson(Value instance) => <String, dynamic>{
      'statistic': _$StatisticEnumMap[instance.statistic]!,
      'value': instance.value,
      'parameters': instance.parameters,
    };

const _$StatisticEnumMap = {
  Statistic.average: 'average',
  Statistic.median: 'median',
  Statistic.min: 'min',
  Statistic.max: 'max',
  Statistic.stdDev: 'stdDev',
  Statistic.stdErr: 'stdErr',
  Statistic.count: 'count',
  Statistic.sum: 'sum',
  Statistic.percentile_90: 'percentile_90',
  Statistic.percentile_99: 'percentile_99',
  Statistic.percentile_999: 'percentile_999',
};

Metric _$MetricFromJson(Map<String, dynamic> json) => Metric(
      name: json['name'] as String,
      values: (json['values'] as List<dynamic>?)
          ?.map((e) => Value.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MetricToJson(Metric instance) => <String, dynamic>{
      'name': instance.name,
      'values': instance.values,
    };

Benchmark _$BenchmarkFromJson(Map<String, dynamic> json) => Benchmark(
      name: json['name'] as String,
      metrics: (json['metrics'] as List<dynamic>?)
          ?.map((e) => Metric.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BenchmarkToJson(Benchmark instance) => <String, dynamic>{
      'name': instance.name,
      'metrics': instance.metrics,
    };

Suite _$SuiteFromJson(Map<String, dynamic> json) => Suite(
      name: json['name'] as String,
      environment:
          Environment.fromJson(json['environment'] as Map<String, dynamic>),
      benchmarks: (json['benchmarks'] as List<dynamic>?)
          ?.map((e) => Benchmark.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SuiteToJson(Suite instance) => <String, dynamic>{
      'name': instance.name,
      'environment': instance.environment,
      'benchmarks': instance.benchmarks,
    };
