import 'dart:io';

void main() {
  final files = Directory('lib/app/ui').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Scale DOWN by multiplying by 0.913
    content = content.replaceAllMapped(RegExp(r'\b(\d+)\.(w|h|sp|r|dg)\b'), (match) {
      changed = true;
      int val = int.parse(match.group(1)!);
      int newVal = (val * 0.913).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '$newVal.${match.group(2)}';
    });

    if (changed) {
      file.writeAsStringSync(content);
      print('Adjusted sizes in ${file.path}');
    }
  }
}
