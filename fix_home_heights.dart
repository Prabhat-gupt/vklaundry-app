import 'dart:io';

void main() {
  final file = File('lib/app/ui/screens/home.dart');
  if (!file.existsSync()) {
    print('home.dart not found!');
    return;
  }

  String content = file.readAsStringSync();
  bool changed = false;

  // Convert height: X.w to height: X.h
  content = content.replaceAllMapped(RegExp(r'(height)\s*:\s*(\d+)\.w'), (match) {
    changed = true;
    return '${match.group(1)}: ${match.group(2)}.h';
  });

  // Convert vertical: X.w to vertical: X.h
  content = content.replaceAllMapped(RegExp(r'(vertical|top|bottom)\s*:\s*(\d+)\.w'), (match) {
    changed = true;
    return '${match.group(1)}: ${match.group(2)}.h';
  });

  if (changed) {
    file.writeAsStringSync(content);
    print('Fixed vertical scaling in home.dart');
  }
}
