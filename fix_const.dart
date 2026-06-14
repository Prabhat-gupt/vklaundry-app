import 'dart:io';

void main() {
  final files = Directory('lib/app/ui').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('const CircleAvatar')) {
      content = content.replaceAll('const CircleAvatar', 'CircleAvatar');
      changed = true;
    }
    if (content.contains('const Divider')) {
      content = content.replaceAll('const Divider', 'Divider');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed const in ${file.path}');
    }
  }
}
