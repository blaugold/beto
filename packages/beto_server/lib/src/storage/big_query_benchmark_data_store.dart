import 'dart:convert';

import 'package:beto_common/beto_common.dart';
// ignore: implementation_imports
import 'package:beto_common/src/json_utils.dart';
import 'package:googleapis/bigquery/v2.dart';

import '../logging.dart';
import 'benchmark_data_store.dart';

const _benchmarkDataTableId = 'benchmark_data';
const _benchmarkDataTableVersionTag = 'version';

class BigQueryBenchmarkDataStore extends BenchmarkDataStore {
  BigQueryBenchmarkDataStore({
    required this.bigQueryApi,
    required this.projectId,
    required this.datasetId,
  });

  final BigqueryApi bigQueryApi;
  final String projectId;
  final String datasetId;

  @override
  Future<void> initialize() async {
    await setupBigQueryBenchmarkDataset(
      bigQueryApi: bigQueryApi,
      projectId: projectId,
      datasetId: datasetId,
    );
  }

  @override
  Future<void> insertBenchmarkRecord(BenchmarkRecord record) async {
    final response = await bigQueryApi.tabledata.insertAll(
      TableDataInsertAllRequest(
        rows: [
          TableDataInsertAllRequestRows(
            json: record.toJson(),
          ),
        ],
      ),
      projectId,
      datasetId,
      _benchmarkDataTableId,
    );

    final errors = response.insertErrors;
    if (errors != null) {
      final errorsJson =
          prettyFormatJson(errors.map((e) => e.toJson()).toList());
      logger.severe(
        'Unable to insert benchmark record into BigQuery. \n$errorsJson',
      );
      throw BetoException(
        statusCode: 500,
        message: 'Unable to persist benchmark data.',
      );
    }
  }

  @override
  Future<List<BenchmarkRecord>> queryBenchmarkRecords({
    required String suite,
    required String benchmark,
    required String device,
    required BenchmarkDataRange range,
  }) async {
    final String rangeCondition;
    if (range is CommitRange) {
      rangeCondition = 'record.commit = @commit';
    } else if (range is DateRange) {
      rangeCondition = '''
record.startTime >= @rangeStartDate AND
record.startTime <= @rangeEndDate
''';
    } else {
      throw UnimplementedError(
        'Range type ${range.runtimeType} not implemented.',
      );
    }

    final query = '''
SELECT
  record.id AS id,
  UNIX_MILLIS(ANY_VALUE(record).startTime) AS startTime,
  ANY_VALUE(record).commit AS commit,
  TO_JSON_STRING(ANY_VALUE(record.environment)) AS environment,
  TO_JSON_STRING(ARRAY_CONCAT_AGG(benchmark.metrics)) AS metrics
FROM
  $_benchmarkDataTableId AS record,
  record.suites AS suite,
  suite.benchmarks AS benchmark
WHERE
  $rangeCondition AND
  record.environment.device = @device AND
  suite.name = @suite AND
  benchmark.name = @benchmark
GROUP BY record.id
ORDER BY startTime
''';

    final queryParameters = [
      if (range is CommitRange)
        QueryParameter(
          name: 'commit',
          parameterType: QueryParameterType(
            type: 'STRING',
          ),
          parameterValue: QueryParameterValue(
            value: range.commit,
          ),
        ),
      if (range is DateRange) ...[
        QueryParameter(
          name: 'rangeStartDate',
          parameterType: QueryParameterType(
            type: 'TIMESTAMP',
          ),
          parameterValue: QueryParameterValue(
            value: range.start.toIso8601String(),
          ),
        ),
        QueryParameter(
          name: 'rangeEndDate',
          parameterType: QueryParameterType(
            type: 'TIMESTAMP',
          ),
          parameterValue: QueryParameterValue(
            value: range.end.toIso8601String(),
          ),
        ),
      ],
      QueryParameter(
        name: 'device',
        parameterType: QueryParameterType(
          type: 'STRING',
        ),
        parameterValue: QueryParameterValue(value: device),
      ),
      QueryParameter(
        name: 'suite',
        parameterType: QueryParameterType(
          type: 'STRING',
        ),
        parameterValue: QueryParameterValue(value: suite),
      ),
      QueryParameter(
        name: 'benchmark',
        parameterType: QueryParameterType(
          type: 'STRING',
        ),
        parameterValue: QueryParameterValue(value: benchmark),
      ),
    ];

    final response = await bigQueryApi.jobs.query(
      QueryRequest(
        defaultDataset: DatasetReference(
          projectId: projectId,
          datasetId: datasetId,
        ),
        query: query,
        useLegacySql: false,
        parameterMode: 'NAMED',
        queryParameters: queryParameters,
      ),
      projectId,
    );

    final errors = response.errors;
    if (errors != null) {
      final errorsJson =
          prettyFormatJson(errors.map((e) => e.toJson()).toList());
      logger.severe(
        'Unable to query benchmark records from BigQuery. \n$errorsJson',
      );
      throw BetoException(
        statusCode: 500,
        message: 'Unable to query benchmark data.',
      );
    }

    if (!(response.jobComplete ?? false)) {
      throw BetoException(
        statusCode: 500,
        message: 'Could not complete the query in a reasonable time.',
      );
    }

    return response.rows!
        .map((row) => _benchmarkRecordFromQueryRow(row, suite, benchmark))
        .toList();
  }

  BenchmarkRecord _benchmarkRecordFromQueryRow(
    TableRow row,
    String suiteName,
    String benchmarkName,
  ) {
    final id = row.f![0].v! as String;
    final startTime = row.f![1].v! as String;
    final commit = row.f![2].v as String?;
    final environment = jsonDecode(row.f![3].v! as String);
    final metrics = jsonDecode(row.f![4].v! as String);

    final record = BenchmarkRecord(
      id: id,
      startTime: DateTime.fromMillisecondsSinceEpoch(int.parse(startTime)),
      commit: commit,
      environment: Environment.fromJson(environment as Map<String, Object?>),
    );
    final suite = Suite(name: suiteName);
    record.addSuite(suite);
    final benchmark = Benchmark.fromJson({
      'name': benchmarkName,
      'metrics': metrics,
    });
    suite.addBenchmark(benchmark);

    return record;
  }
}

Future<void> setupBigQueryBenchmarkDataset({
  required BigqueryApi bigQueryApi,
  required String projectId,
  required String datasetId,
}) async {
  // Create the dataset if it doesn't exist.
  // ignore: unused_local_variable
  Dataset dataset;
  try {
    dataset = await bigQueryApi.datasets.get(projectId, datasetId);
  } on DetailedApiRequestError catch (e) {
    if (e.status == 404) {
      dataset = await bigQueryApi.datasets.insert(
        Dataset(
          datasetReference: DatasetReference(datasetId: datasetId),
          friendlyName: 'Beto data',
        ),
        projectId,
      );
    } else {
      rethrow;
    }
  }

  // Create the tables if they don't exist.
  Table table;
  try {
    table = await bigQueryApi.tables
        .get(projectId, datasetId, _benchmarkDataTableId);
  } on DetailedApiRequestError catch (e) {
    if (e.status == 404) {
      table = await bigQueryApi.tables.insert(
        Table(
          tableReference: TableReference(
            tableId: _benchmarkDataTableId,
          ),
          friendlyName: 'Benchmark data',
          labels: {
            _benchmarkDataTableVersionTag: '0',
          },
        ),
        projectId,
        datasetId,
      );
    } else {
      rethrow;
    }
  }

  // Update the table if the version is outdated.
  final version = int.parse(table.labels![_benchmarkDataTableVersionTag]!);
  final migrations = _benchmarkDataTableMigrations.sublist(version);
  for (final migration in migrations) {
    table = await migration(bigQueryApi, table);
  }

  // Update the version tag.
  await bigQueryApi.tables.patch(
    Table(
      labels: {
        _benchmarkDataTableVersionTag: '${migrations.length}',
      },
    ),
    projectId,
    datasetId,
    _benchmarkDataTableId,
  );
}

// ignore: avoid_private_typedef_functions
typedef _TableMigration = Future<Table> Function(
  BigqueryApi bigQueryApi,
  Table table,
);

const _benchmarkDataTableMigrations = <_TableMigration>[
  _benchmarkDataTableMigration1,
];

Future<Table> _benchmarkDataTableMigration1(
  BigqueryApi bigQueryApi,
  Table table,
) {
  final tableSchema = TableSchema(
    fields: [
      TableFieldSchema(
        name: 'id',
        type: 'STRING',
        mode: 'REQUIRED',
      ),
      TableFieldSchema(
        name: 'startTime',
        type: 'TIMESTAMP',
        mode: 'REQUIRED',
      ),
      TableFieldSchema(
        name: 'commit',
        type: 'STRING',
        mode: 'NULLABLE',
      ),
      TableFieldSchema(
        name: 'environment',
        type: 'RECORD',
        mode: 'REQUIRED',
        fields: [
          TableFieldSchema(
            name: 'device',
            type: 'STRING',
            mode: 'REQUIRED',
          ),
          TableFieldSchema(
            name: 'os',
            type: 'RECORD',
            mode: 'REQUIRED',
            fields: [
              TableFieldSchema(
                name: 'type',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
              TableFieldSchema(
                name: 'versionString',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
            ],
          ),
          TableFieldSchema(
            name: 'cpu',
            type: 'RECORD',
            mode: 'REQUIRED',
            fields: [
              TableFieldSchema(
                name: 'model',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
              TableFieldSchema(
                name: 'arch',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
              TableFieldSchema(
                name: 'cores',
                type: 'INTEGER',
                mode: 'REQUIRED',
              ),
            ],
          ),
          TableFieldSchema(
            name: 'runtime',
            type: 'RECORD',
            mode: 'NULLABLE',
            fields: [
              TableFieldSchema(
                name: 'name',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
              TableFieldSchema(
                name: 'version',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
            ],
          ),
        ],
      ),
      TableFieldSchema(
        name: 'suites',
        type: 'RECORD',
        mode: 'REPEATED',
        fields: [
          TableFieldSchema(
            name: 'name',
            type: 'STRING',
            mode: 'REQUIRED',
          ),
          TableFieldSchema(
            name: 'benchmarks',
            type: 'RECORD',
            mode: 'REPEATED',
            fields: [
              TableFieldSchema(
                name: 'name',
                type: 'STRING',
                mode: 'REQUIRED',
              ),
              TableFieldSchema(
                name: 'metrics',
                type: 'RECORD',
                mode: 'REPEATED',
                fields: [
                  TableFieldSchema(
                    name: 'name',
                    type: 'STRING',
                    mode: 'REQUIRED',
                  ),
                  TableFieldSchema(
                    name: 'values',
                    type: 'RECORD',
                    mode: 'REPEATED',
                    fields: [
                      TableFieldSchema(
                        name: 'statistic',
                        type: 'STRING',
                        mode: 'REQUIRED',
                      ),
                      TableFieldSchema(
                        name: 'value',
                        type: 'FLOAT',
                        mode: 'REQUIRED',
                      ),
                      TableFieldSchema(
                        name: 'parameters',
                        type: 'RECORD',
                        mode: 'REPEATED',
                        fields: [
                          TableFieldSchema(
                            name: 'name',
                            type: 'STRING',
                            mode: 'REQUIRED',
                          ),
                          TableFieldSchema(
                            name: 'value',
                            type: 'STRING',
                            mode: 'REQUIRED',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return bigQueryApi.tables.patch(
    Table(
      schema: tableSchema,
    ),
    table.tableReference!.projectId!,
    table.tableReference!.datasetId!,
    table.tableReference!.tableId!,
  );
}
