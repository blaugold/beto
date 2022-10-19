import 'dart:io';

import 'package:beto_server/src/configuration.dart';
import 'package:beto_server/src/logging.dart';
import 'package:beto_server/src/server.dart';
import 'package:logging/logging.dart';

void main() async {
  const debug = true;
  // ignore: prefer_const_declarations
  final Level? logLevel = null;

  // ignore: dead_code
  final effectiveLogLevel = logLevel ?? (debug ? Level.FINE : Level.INFO);

  setupLogging(logLevel: effectiveLogLevel, useRequestCounter: debug);

  final server = BetoServer(
    dataStoreImpl: DataStoreImpl.inMemory,
    logRequests: debug,
    useRequestCounter: debug,
  );

  try {
    await server.start();
  } on InvalidConfiguration catch (error) {
    logger.severe('Invalid configuration:\n${error.message}');
    exit(1);
  }

  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
}
