import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

String prettyFormatJson(Object? object) =>
    const JsonEncoder.withIndent('  ').convert(object);

class TaggedTypeConverter<T> extends JsonConverter<T, List<Object?>> {
  const TaggedTypeConverter(this.baseType, this.typeToTag, this.tagToConverter);

  final String baseType;
  final Map<Type, String> typeToTag;
  final Map<String, T Function(Map<String, Object?>)> tagToConverter;

  @override
  T fromJson(List<Object?> json) {
    if (json.length != 2) {
      throw FormatException('Invalid $baseType: $json');
    }
    final type = json.first;
    if (type is! String) {
      throw FormatException('Invalid $baseType: $json');
    }
    final value = json[2];
    if (value is! Map<String, Object?>) {
      throw FormatException('Invalid $baseType: $json');
    }
    final converter = tagToConverter[type];
    if (converter == null) {
      throw FormatException('Invalid $baseType: $json');
    }
    return converter(value);
  }

  @override
  List<Object?> toJson(T object) {
    final tag = typeToTag[object.runtimeType];
    if (tag == null) {
      throw UnimplementedError('No tag for ${object.runtimeType} registered.');
    }
    // ignore: avoid_dynamic_calls
    return [tag, (object as dynamic).toJson()];
  }
}
