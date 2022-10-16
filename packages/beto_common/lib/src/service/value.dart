import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

import 'environment.dart';

part 'value.g.dart';

enum Statistic {
  average,
  median,
  min,
  max,
  stdDev,
  stdErr,
  count,
  sum,
  percentile_90,
  percentile_99,
  percentile_999,
}

@JsonSerializable()
class Value {
  Value({
    required this.statistic,
    required this.value,
    this.parameters = const {},
  });

  factory Value.fromJson(Map<String, Object?> json) => _$ValueFromJson(json);

  final Statistic statistic;
  final double value;
  final Map<String, Object?> parameters;

  Metric get metric => _metric!;
  Metric? _metric;

  @override
  String toString() => 'Value(${metric.qualifiedName} [$statistic]: $value)';

  Map<String, Object?> toJson() => _$ValueToJson(this);
}

@JsonSerializable()
class Metric {
  Metric({
    required this.name,
    List<Value>? values,
  }) {
    values?.forEach(addValue);
  }

  factory Metric.fromJson(Map<String, Object?> json) => _$MetricFromJson(json);

  final String name;

  Benchmark get benchmark => _benchmark!;
  Benchmark? _benchmark;

  late final List<Value> values = UnmodifiableListView(_values);

  final List<Value> _values = [];

  void addValue(Value value) {
    assert(value._metric == null);
    value._metric = this;
    _values.add(value);
  }

  String get qualifiedName => '${benchmark.qualifiedName}/$name';

  @override
  String toString() => 'Metric($qualifiedName)';

  Map<String, Object?> toJson() => _$MetricToJson(this);
}

@JsonSerializable()
class Benchmark {
  Benchmark({
    required this.name,
    List<Metric>? metrics,
  }) {
    metrics?.forEach(addMetric);
  }

  factory Benchmark.fromJson(Map<String, Object?> json) =>
      _$BenchmarkFromJson(json);

  final String name;

  Suite get suite => _suite!;
  Suite? _suite;

  String get qualifiedName => '${suite.name}/$name';

  late final List<Metric> metrics = UnmodifiableListView(_metrics);

  final List<Metric> _metrics = [];

  void addMetric(Metric metric) {
    assert(metric._benchmark == null);
    metric._benchmark = this;
    _metrics.add(metric);
  }

  @override
  String toString() => 'Benchmark($qualifiedName)';

  Map<String, Object?> toJson() => _$BenchmarkToJson(this);
}

@JsonSerializable()
class Suite {
  Suite({
    required this.name,
    required this.environment,
    List<Benchmark>? benchmarks,
  }) {
    benchmarks?.forEach(addBenchmark);
  }

  factory Suite.fromJson(Map<String, Object?> json) => _$SuiteFromJson(json);

  final String name;
  final Environment environment;

  late final List<Benchmark> benchmarks = UnmodifiableListView(_benchmarks);

  final List<Benchmark> _benchmarks = [];

  void addBenchmark(Benchmark benchmark) {
    assert(benchmark._suite == null);
    benchmark._suite = this;
    _benchmarks.add(benchmark);
  }

  @override
  String toString() => 'Suite($name)';

  Map<String, Object?> toJson() => _$SuiteToJson(this);
}
