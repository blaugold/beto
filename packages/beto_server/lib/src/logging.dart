// ignore_for_file: cascade_invocations

import 'package:logging/logging.dart';

import 'configuration.dart';
import 'middleware.dart';

class LevelOption extends SimpleOption<Level> {
  LevelOption({
    required super.name,
    required super.description,
    Level? defaultValue,
    super.abbreviation,
    super.allowedValues,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  Level valueFromString(String value) {
    for (final level in Level.LEVELS) {
      if (level.name == value) {
        return level;
      }
    }
    throw FormatException('Value "$value" is not a valid log level.');
  }

  @override
  String valueToString(Level value) => value.name;
}

final _logLevel = LevelOption(
  name: 'logLevel',
  description: 'The log level to use.',
  defaultValue: Level.INFO,
  allowedValues: Level.LEVELS,
);

final loggingOptions = [
  _logLevel,
];

extension LoggingOptions on Options {
  Level get logLevel => get(_logLevel);
}

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
