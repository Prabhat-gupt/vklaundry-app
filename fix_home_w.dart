import 'dart:io';

void main() {
  final file = File('lib/app/ui/screens/home.dart');
  if (!file.existsSync()) {
    print('home.dart not found!');
    return;
  }

  String content = file.readAsStringSync();
  bool changed = false;

  // Convert .h back to .w to lock aspect ratio and prevent overflow
  content = content.replaceAllMapped(RegExp(r'\b(\d+)\.h\b'), (match) {
    changed = true;
    return '${match.group(1)}.w';
  });

  if (changed) {
    file.writeAsStringSync(content);
    print('Reverted .h back to .w in home.dart for responsive aspect ratios');
  }
}
