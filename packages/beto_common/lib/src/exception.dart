import 'package:json_annotation/json_annotation.dart';

part 'exception.g.dart';

@JsonSerializable()
class BetoException implements Exception {
  BetoException({
    required this.statusCode,
    required this.message,
  });

  factory BetoException.fromJson(Map<String, dynamic> json) =>
      _$BetoExceptionFromJson(json);

  final int statusCode;
  final String message;

  @override
  String toString() => 'BetoException('
      'statusCode: $statusCode, '
      'message: $message'
      ')';

  Map<String, Object?> toJson() => _$BetoExceptionToJson(this);
}
