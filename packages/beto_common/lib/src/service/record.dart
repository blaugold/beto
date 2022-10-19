import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'environment.dart';

part 'record.g.dart';

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
  @_ParametersConverter()
  final Map<String, String> parameters;

  Metric get metric => _metric!;
  Metric? _metric;

  @override
  String toString() => 'Value(${metric.qualifiedName} [$statistic]: $value)';

  Map<String, Object?> toJson() => _$ValueToJson(this);

  Value clone() => Value(
        statistic: statistic,
        value: value,
        parameters: parameters,
      );
}

class _ParametersConverter
    implements JsonConverter<Map<String, String>, List<Object?>> {
  const _ParametersConverter();

  @override
  Map<String, String> fromJson(List<Object?> json) {
    final entries = json
        .cast<Map<String, Object?>>()
        .map((e) => MapEntry(e['name']! as String, e['value']! as String));
    return Map<String, String>.fromEntries(entries);
  }

  @override
  List<Object?> toJson(Map<String, String> object) => object.entries
      .map((entry) => {'name': entry.key, 'value': entry.value})
      .toList();
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

  Metric clone() => Metric(
        name: name,
        values: values.map((value) => value.clone()).toList(),
      );
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

  Benchmark clone() => Benchmark(
        name: name,
        metrics: metrics.map((metric) => metric.clone()).toList(),
      );
}

@JsonSerializable()
class Suite {
  Suite({
    required this.name,
    List<Benchmark>? benchmarks,
  }) {
    benchmarks?.forEach(addBenchmark);
  }

  factory Suite.fromJson(Map<String, Object?> json) => _$SuiteFromJson(json);

  final String name;

  BenchmarkRecord get record => _record!;
  BenchmarkRecord? _record;

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

  Suite clone() => Suite(
        name: name,
        benchmarks: benchmarks.map((benchmark) => benchmark.clone()).toList(),
      );
}

@JsonSerializable()
class BenchmarkRecord {
  BenchmarkRecord({
    String? id,
    required this.environment,
    List<Suite>? suites,
  }) : id = id ?? const Uuid().v4() {
    suites?.forEach(addSuite);
  }

  factory BenchmarkRecord.fromJson(Map<String, Object?> json) =>
      _$BenchmarkRecordFromJson(json);

  final String id;
  final Environment environment;

  late final List<Suite> suites = UnmodifiableListView(_suites);

  final List<Suite> _suites = [];

  void addSuite(Suite suite) {
    assert(suite._record == null);
    suite._record = this;
    _suites.add(suite);
  }

  @override
  String toString() =>
      'BenchmarkRecord(environment: $environment, suites: $suites)';

  Map<String, Object?> toJson() => _$BenchmarkRecordToJson(this);

  BenchmarkRecord clone() => BenchmarkRecord(
        id: id,
        environment: environment,
        suites: suites.map((suite) => suite.clone()).toList(),
      );
}
