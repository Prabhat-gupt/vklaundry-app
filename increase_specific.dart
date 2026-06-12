import 'dart:io';

void main() {
  final targetFiles = [
    'lib/app/ui/screens/home.dart',
  ];

  for (final path in targetFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      continue;
    }

    String content = file.readAsStringSync();
    bool changed = false;

    // Scale UP by 10% (multiply by 1.10)
    content = content.replaceAllMapped(RegExp(r'\b(\d+)\.(w|h|sp|r|dg)\b'), (match) {
      changed = true;
      int val = int.parse(match.group(1)!);
      int newVal = (val * 1.10).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '$newVal.${match.group(2)}';
    });

    if (changed) {
      file.writeAsStringSync(content);
      print('Slightly increased sizes in $path');
    }
  }
}
