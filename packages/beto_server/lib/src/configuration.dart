// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:io';

import 'package:args/args.dart';
import 'package:recase/recase.dart';

class OptionValue<T> {
  OptionValue(this.value);

  final T value;
}

abstract class Option<T> {
  const Option({
    required this.name,
    this.abbreviation,
    required this.description,
    this.isRequired = true,
    this.defaultValue,
  });

  final String name;
  final String? abbreviation;
  final String description;
  final bool isRequired;
  final OptionValue<T>? defaultValue;

  String get commandLineParameterName => name.paramCase;

  String get environmentVariableName => name.constantCase;

  void registerWithArgParser(ArgParser parser);

  OptionValue<T>? resolveFromArguments(ArgResults arguments);

  OptionValue<T>? resolveFromEnvironment(Map<String, String> environment);
}

abstract class SimpleOption<T> extends Option<T> {
  SimpleOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    super.defaultValue,
    this.allowedValues,
  });

  final List<T>? allowedValues;

  String valueToString(T value);

  T valueFromString(String value);

  @override
  void registerWithArgParser(ArgParser parser) {
    parser.addOption(
      commandLineParameterName,
      abbr: abbreviation,
      help: description,
      allowed: allowedValues?.map(valueToString).toList(),
      defaultsTo:
          defaultValue == null ? null : valueToString(defaultValue!.value),
    );
  }

  @override
  OptionValue<T>? resolveFromArguments(ArgResults arguments) {
    if (arguments.wasParsed(commandLineParameterName)) {
      return OptionValue(
        valueFromString(arguments[commandLineParameterName]! as String),
      );
    }
    return null;
  }

  @override
  OptionValue<T>? resolveFromEnvironment(Map<String, String> environment) {
    if (environment.containsKey(environmentVariableName)) {
      return OptionValue(
        valueFromString(environment[environmentVariableName]!),
      );
    }
    return null;
  }
}

class FlagOption extends SimpleOption<bool> {
  FlagOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    bool? defaultValue,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  void registerWithArgParser(ArgParser parser) {
    parser.addFlag(
      commandLineParameterName,
      abbr: abbreviation,
      help: description,
      defaultsTo: defaultValue?.value ?? false,
    );
  }

  @override
  OptionValue<bool>? resolveFromArguments(ArgResults arguments) {
    if (arguments.wasParsed(commandLineParameterName)) {
      return OptionValue(arguments[commandLineParameterName]! as bool);
    }
    return null;
  }

  @override
  String valueToString(bool value) => value.toString();

  @override
  bool valueFromString(String value) {
    switch (value) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        throw FormatException('Value "$value" is not a valid boolean value.');
    }
  }
}

class IntegerOption extends SimpleOption<int> {
  IntegerOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    int? defaultValue,
    super.allowedValues,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  String valueToString(int value) => value.toString();

  @override
  int valueFromString(String value) => int.parse(value);
}

class EnumOption<T extends Enum> extends SimpleOption<T> {
  EnumOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    T? defaultValue,
    required List<T> super.allowedValues,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  String valueToString(T value) => value.name;

  @override
  T valueFromString(String value) {
    for (final enumValue in allowedValues!) {
      if (enumValue.name == value) {
        return enumValue;
      }
    }
    throw FormatException('Value "$value" is not a valid enum value.');
  }
}

class StringOption extends SimpleOption<String> {
  StringOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    String? defaultValue,
    super.allowedValues,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  void registerWithArgParser(ArgParser parser) {
    parser.addOption(
      commandLineParameterName,
      abbr: abbreviation,
      help: description,
      allowed: allowedValues,
      defaultsTo: defaultValue?.value,
    );
  }

  @override
  String valueFromString(String value) => value;

  @override
  String valueToString(String value) => value;
}

class InternetAddressOption extends SimpleOption<InternetAddress> {
  InternetAddressOption({
    required super.name,
    super.abbreviation,
    required super.description,
    super.isRequired,
    InternetAddress? defaultValue,
    super.allowedValues,
  }) : super(
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  @override
  String valueToString(InternetAddress value) => value.toString();

  @override
  InternetAddress valueFromString(String value) {
    if (value == 'localhost') {
      return InternetAddress.loopbackIPv4;
    }

    try {
      return InternetAddress(value);
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw InvalidConfiguration(
        'Value "$value" is not a valid internet address.',
      );
    }
  }
}

class ListOption<T> extends Option<List<T>> {
  ListOption({required this.option, List<T>? defaultValue})
      : super(
          name: option.name,
          abbreviation: option.abbreviation,
          description: option.description,
          isRequired: option.isRequired,
          defaultValue: defaultValue == null ? null : OptionValue(defaultValue),
        );

  final SimpleOption<T> option;

  @override
  void registerWithArgParser(ArgParser parser) {
    parser.addMultiOption(
      option.commandLineParameterName,
      abbr: option.abbreviation,
      help: option.description,
      defaultsTo: defaultValue?.value.map(option.valueToString).toList(),
      allowed: option.allowedValues?.map(option.valueToString).toList(),
    );
  }

  @override
  OptionValue<List<T>>? resolveFromArguments(ArgResults arguments) {
    if (arguments.wasParsed(option.commandLineParameterName)) {
      return OptionValue(
        (arguments[option.commandLineParameterName]! as List<String>)
            .map(option.valueFromString)
            .toList(),
      );
    }
    return null;
  }

  @override
  OptionValue<List<T>>? resolveFromEnvironment(
    Map<String, String> environment,
  ) {
    if (environment.containsKey(option.environmentVariableName)) {
      return OptionValue(
        environment[option.environmentVariableName]!
            .split(',')
            .map(option.valueFromString)
            .toList(),
      );
    }
    return null;
  }
}

class Options {
  Options(Iterable<Option> options) : _options = List.of(options);

  final List<Option> _options;
  final Map<Option, Object?> _values = {};

  void resolve({
    required List<String> arguments,
    required Map<String, String> environment,
  }) {
    final parser = ArgParser();

    for (final option in _options) {
      option.registerWithArgParser(parser);
    }

    if (arguments.contains('--help') || arguments.contains('-h')) {
      throw InvalidConfiguration(parser.usage);
    }

    final ArgResults argResults;
    try {
      argResults = parser.parse(arguments);
    } on ArgParserException catch (e) {
      throw InvalidConfiguration('$e\n\n${parser.usage}');
    }

    for (final option in _options) {
      OptionValue? value;

      try {
        value = option.resolveFromArguments(argResults);
        value ??= option.resolveFromEnvironment(environment);
      } on FormatException catch (e) {
        throw InvalidConfiguration(
          'Invalid value for option ${option.name}: $e\n\n${parser.usage}',
        );
      }

      value ??= option.defaultValue;
      if (option.isRequired && value == null) {
        throw InvalidConfiguration(
          'Missing required option: $option\n\n${parser.usage}',
        );
      }
      _values[option] = value?.value;
    }
  }

  T get<T>(Option<T> option) => _values[option] as T;
}

class InvalidConfiguration implements Exception {
  InvalidConfiguration(this.message);

  final String message;

  @override
  String toString() => message;
}
