import 'dart:convert';
import 'dart:io';

String runProcess(String executable, List<String> arguments) {
  final result = Process.runSync(
    executable,
    arguments,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
    // Run in shell on Windows to resolve .bat scripts.
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    throw Exception(
      'Failed to run "$executable" $arguments:\n'
      'Exit code: ${result.exitCode}\n'
      '${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

bool isRepositoryDirty() {
  final result = runProcess('git', ['status', '--porcelain']);
  return result.isNotEmpty;
}
