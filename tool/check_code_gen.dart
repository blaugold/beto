import 'dart:io';

import 'utils.dart';

void main() {
  if (isRepositoryDirty()) {
    printDiff();
    error('Repository must not be dirty when running check_code_gen.');
  }

  runProcess('melos', ['code-gen', '--no-select']);

  // Wait a bit to make sure the file system has time to update.
  sleep(const Duration(seconds: 1));

  if (isRepositoryDirty()) {
    printDiff();
    error('Repository is dirty after running code-gen.');
  }
}

Never error(String message) {
  throw Exception(message);
}

void printDiff() {
  // ignore: avoid_print
  print(runProcess('git', ['diff']));
}
