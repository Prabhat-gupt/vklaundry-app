import 'dart:io';

void main() {
  final dirs = [Directory('lib/app/ui/screens'), Directory('lib/app/ui/widgets')];
  
  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    final files = dir.listSync(recursive: true).whereType<File>().where((f) => 
        f.path.endsWith('.dart') && 
        !f.path.contains('checkout.dart') && 
        !f.path.contains('special_carousel.dart') // Wait, let's include special_carousel but maybe the user checked it earlier.
    );
    
    for (final file in files) {
      if (file.path.contains('checkout.dart')) continue;
      String content = file.readAsStringSync();
      bool changed = false;
      
      content = content.replaceAllMapped(RegExp(r'(\d+)\.(w|h|sp|r)\b'), (match) {
        changed = true;
        int val = int.parse(match.group(1)!);
        int newVal = (val * 0.75).round();
        if (newVal == 0 && val > 0) newVal = 1;
        return '$newVal.${match.group(2)}';
      });

      if (changed) {
        file.writeAsStringSync(content);
        print('Updated sizes in ${file.path}');
      }
    }
  }
}
