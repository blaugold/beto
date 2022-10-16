import 'dart:io';

import 'package:beto_server/src/server.dart';

void main() async {
  final server = BetoServer();

  try {
    await server.start();
  } on InvalidConfiguration catch (e) {
    // TODO: Logging
    // ignore: avoid_print
    print(e);
    exit(1);
  }

  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
}
