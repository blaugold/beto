// ignore_for_file: cascade_invocations

import 'package:logging/logging.dart';

import 'middleware.dart';

final logger = Logger('beto_server');

void setupLogging({required Level logLevel, bool useRequestCounter = false}) {
  hierarchicalLoggingEnabled = true;
  logger.level = logLevel;
  logger.onRecord.listen((event) {
    var requestId = event.zone?.requestId;
    if (useRequestCounter) {
      requestId = requestId?.padRight(6);
    }

    final buffer = StringBuffer();

    buffer.write(event.time.toIso8601String());

    buffer
      ..write('  ')
      ..write('[${event.level.name}]'.padRight(9));

    if (requestId != null) {
      buffer
        ..write('  #')
        ..write(requestId);
    }

    if (event.loggerName != logger.fullName) {
      buffer
        ..write('  ')
        ..write(event.loggerName);
    }

    buffer
      ..write(' ')
      ..write(event.message);

    if (event.error != null) {
      buffer
        ..writeln()
        ..write(event.error);
    }

    if (event.stackTrace != null) {
      buffer
        ..writeln()
        ..write(event.stackTrace);
    }

    // ignore: avoid_print
    print(buffer);
  });
}
