import 'utils.dart';

void main() {
  if (isRepositoryDirty()) {
    error('Repository must not be dirty when running check_code_gen.');
  }

  runProcess('melos', ['code-gen', '--no-select']);

  if (isRepositoryDirty()) {
    error('Repository is dirty after running code-gen.');
  }
}

Never error(String message) {
  throw Exception(message);
}
