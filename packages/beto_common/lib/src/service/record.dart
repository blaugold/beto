import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'environment.dart';
import 'validate.dart';

part 'record.g.dart';

/// A node in a [BenchmarkRecord].
abstract class BenchmarkDataNode<T> {
  /// The children of this node.
  Iterable<BenchmarkDataNode> get children;

  /// Returns this node as JSON.
  Object? toJson();

  /// Returns a clone of this node.
  T clone();

  /// Validates this node and all its children.
  void validate() {
    performValidation();
    for (final child in children) {
      child.validate();
    }
  }

  /// Performs validation of this node
  @protected
  void performValidation();
}

/// A statistical function used to aggregates values.
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

/// Am aggregate value of a [Metric].
@JsonSerializable()
class Value extends BenchmarkDataNode<Value> {
  /// Creates a new [Value].
  Value({
    required this.statistic,
    required this.value,
    this.parameters = const {},
  });

  /// Creates a [Value] from JSON.
  factory Value.fromJson(Map<String, Object?> json) => _$ValueFromJson(json);

  /// The statistical function used to aggregate the metric.
  final Statistic statistic;

  /// The aggregated value.
  final double value;

  /// Benchmark parameters that were used when the aggregated values where
  /// recorded.
  @_ParametersConverter()
  final Map<String, String> parameters;

  /// The [Metric] this value belongs to.
  Metric get metric => _metric!;
  Metric? _metric;

  @override
  Iterable<BenchmarkDataNode> get children => const [];

  @override
  void performValidation() {}

  @override
  String toString() => 'Value(${metric.qualifiedName} [$statistic]: $value)';

  @override
  Map<String, Object?> toJson() => _$ValueToJson(this);

  @override
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

/// A metric that is recorded by a [Benchmark], such as runtime or memory usage.
@JsonSerializable()
class Metric extends BenchmarkDataNode<Metric> {
  /// Creates a new [Metric].
  Metric({
    required this.name,
    List<Value>? values,
  }) {
    values?.forEach(addValue);
  }

  /// Creates a [Metric] from JSON.
  factory Metric.fromJson(Map<String, Object?> json) => _$MetricFromJson(json);

  /// The name of this metric.
  ///
  /// It must only contain alphanumeric characters and underscores.
  final String name;

  /// The qualified name of this metric, which identifies it within the
  /// [BenchmarkRecord].
  String get qualifiedName => '${benchmark.qualifiedName}/$name';

  /// The [Benchmark] this metric belongs to.
  Benchmark get benchmark => _benchmark!;
  Benchmark? _benchmark;

  /// The recorded [Value]s for this metric.
  late final List<Value> values = UnmodifiableListView(_values);

  final List<Value> _values = [];

  /// Adds a [Value] to this metric.
  void addValue(Value value) {
    assert(value._metric == null);
    value._metric = this;
    _values.add(value);
  }

  @override
  Iterable<BenchmarkDataNode> get children => values;

  @override
  void performValidation() {
    validateAlphaNumericIdentifier('Metric.name', name);
  }

  @override
  String toString() => 'Metric($qualifiedName)';

  @override
  Map<String, Object?> toJson() => _$MetricToJson(this);

  @override
  Metric clone() => Metric(
        name: name,
        values: values.map((value) => value.clone()).toList(),
      );
}

/// A benchmark that is part of a [Suite].
@JsonSerializable()
class Benchmark extends BenchmarkDataNode<Benchmark> {
  /// Creates a new [Benchmark].
  Benchmark({
    required this.name,
    List<Metric>? metrics,
  }) {
    metrics?.forEach(addMetric);
  }

  /// Creates a [Benchmark] from JSON.
  factory Benchmark.fromJson(Map<String, Object?> json) =>
      _$BenchmarkFromJson(json);

  /// The name of this benchmark.
  ///
  /// It must only contain alphanumeric characters and underscores.
  final String name;

  /// The qualified name of this benchmark, which identifies it within the
  /// [BenchmarkRecord].
  String get qualifiedName => '${suite.name}/$name';

  /// The [Suite] this benchmark belongs to.
  Suite get suite => _suite!;
  Suite? _suite;

  /// The [Metric]s recorded by this benchmark.
  late final List<Metric> metrics = UnmodifiableListView(_metrics);

  final List<Metric> _metrics = [];

  /// Adds a [Metric] to this benchmark.
  void addMetric(Metric metric) {
    assert(metric._benchmark == null);
    metric._benchmark = this;
    _metrics.add(metric);
  }

  @override
  Iterable<BenchmarkDataNode> get children => metrics;

  @override
  void performValidation() {
    validateAlphaNumericIdentifier('Benchmark.name', name);
  }

  @override
  String toString() => 'Benchmark($qualifiedName)';

  @override
  Map<String, Object?> toJson() => _$BenchmarkToJson(this);

  @override
  Benchmark clone() => Benchmark(
        name: name,
        metrics: metrics.map((metric) => metric.clone()).toList(),
      );
}

/// A suite of [Benchmark]s.
@JsonSerializable()
class Suite extends BenchmarkDataNode<Suite> {
  /// Creates a new [Suite].
  Suite({
    required this.name,
    List<Benchmark>? benchmarks,
  }) {
    validateAlphaNumericIdentifier('Suite.name', name);
    benchmarks?.forEach(addBenchmark);
  }

  /// Creates a [Suite] from JSON.
  factory Suite.fromJson(Map<String, Object?> json) => _$SuiteFromJson(json);

  /// The name of this suite.
  final String name;

  /// The [BenchmarkRecord] this suite belongs to.
  BenchmarkRecord get record => _record!;
  BenchmarkRecord? _record;

  /// The [Benchmark]s in this suite.
  late final List<Benchmark> benchmarks = UnmodifiableListView(_benchmarks);

  final List<Benchmark> _benchmarks = [];

  /// Adds a [Benchmark] to this suite.
  void addBenchmark(Benchmark benchmark) {
    assert(benchmark._suite == null);
    benchmark._suite = this;
    _benchmarks.add(benchmark);
  }

  @override
  Iterable<BenchmarkDataNode> get children => benchmarks;

  @override
  void performValidation() {
    validateAlphaNumericIdentifier('Suite.name', name);
  }

  @override
  String toString() => 'Suite($name)';

  @override
  Map<String, Object?> toJson() => _$SuiteToJson(this);

  @override
  Suite clone() => Suite(
        name: name,
        benchmarks: benchmarks.map((benchmark) => benchmark.clone()).toList(),
      );
}

/// A record of benchmark [Suite]s that where executed together and in the
/// same [environment].
@JsonSerializable()
class BenchmarkRecord extends BenchmarkDataNode<BenchmarkRecord> {
  /// Creates a new [BenchmarkRecord].
  BenchmarkRecord({
    String? id,
    required this.startTime,
    this.commit,
    required this.environment,
    List<Suite>? suites,
  }) : id = id ?? const Uuid().v4() {
    suites?.forEach(addSuite);
  }

  /// Creates a [BenchmarkRecord] from JSON.
  factory BenchmarkRecord.fromJson(Map<String, Object?> json) =>
      _$BenchmarkRecordFromJson(json);

  /// A unique identifier for this record.
  final String id;

  /// The time recording of benchmark data in this record started.
  ///
  /// This time is only used to roughly order benchmark data over time.
  final DateTime startTime;

  /// The hash of the commit that contains the executed revision of the
  /// benchmark.
  final String? commit;

  /// The [Environment] in which the benchmarks were executed.
  final Environment environment;

  /// The [Suite]s in this record.
  late final List<Suite> suites = UnmodifiableListView(_suites);

  final List<Suite> _suites = [];

  /// Adds a [Suite] to this record.
  void addSuite(Suite suite) {
    assert(suite._record == null);
    suite._record = this;
    _suites.add(suite);
  }

  @override
  Iterable<BenchmarkDataNode> get children => suites;

  @override
  void performValidation() {}

  @override
  String toString() => 'BenchmarkRecord('
      'id: $id, '
      'startTime: $startTime, '
      'commit: $commit, '
      'environment: $environment, '
      'suites: $suites'
      ')';

  @override
  Map<String, Object?> toJson() => _$BenchmarkRecordToJson(this);

  @override
  BenchmarkRecord clone() => BenchmarkRecord(
        id: id,
        startTime: startTime,
        commit: commit,
        environment: environment,
        suites: suites.map((suite) => suite.clone()).toList(),
      );
}
