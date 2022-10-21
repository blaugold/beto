final _alphaNumericIdentifierRegExp = RegExp(r'^[a-zA-Z0-9_]+$');

bool isAlphaNumericIdentifier(String value) =>
    _alphaNumericIdentifierRegExp.hasMatch(value);

void validateAlphaNumericIdentifier(String name, String value) {
  if (!isAlphaNumericIdentifier(value)) {
    throw FormatException(
      '"$name" must only contain alphanumeric characters and underscores.',
      value,
    );
  }
}
