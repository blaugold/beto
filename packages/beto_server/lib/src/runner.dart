import 'dart:async';
import 'dart:io';

import 'configuration.dart';
import 'logging.dart';
import 'server.dart';
import 'services.dart';

Future<void> runServer(List<String> arguments) async {
  final options = await _handleInvalidConfiguration(
    () => Options([
      ...loggingOptions,
      ...servicesOptions,
      ...serverOptions,
    ])
      ..resolve(
        arguments: arguments,
        environment: Platform.environment,
      ),
  );

  setupLogging(
    logLevel: options.logLevel,
    useRequestCounter: options.useRequestCounter,
  );

  final services = Services(
    gcpServiceAccount: options.gcpServiceAccount,
    bigQueryDatasetId: options.bigQueryDatasetId,
    benchmarkDataStoreType: options.benchmarkDataStore,
  );

  final server = BetoServer(
    port: options.port,
    address: options.address,
    logRequests: options.logRequests,
    useRequestCounter: options.useRequestCounter,
    apiSecrets: options.apiSecrets,
    services: services,
  );

  await _handleInvalidConfiguration(server.start);

  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    await services.dispose();
    exit(0);
  });
}

Future<T> _handleInvalidConfiguration<T>(
  FutureOr<T> Function() callback,
) async {
  try {
    return await callback();
  } on InvalidConfiguration catch (error) {
    // ignore: avoid_print
    print(error);
    exit(1);
  }
}
