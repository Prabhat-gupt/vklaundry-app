import 'dart:io';

void main() {
  final dir = Directory('lib/app/ui');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains(RegExp(r'\.h\b'))) {
      content = content.replaceAll(RegExp(r'\.h\b'), '.w');
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
