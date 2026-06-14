import 'dart:io';

void main() {
  final file = File('lib/app/ui/screens/checkout.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAllMapped(RegExp(r'(\d+)\.(w|h|sp|r)\b'), (match) {
    int val = int.parse(match.group(1)!);
    int newVal = (val * 0.75).round();
    if (newVal == 0 && val > 0) newVal = 1;
    return '$newVal.${match.group(2)}';
  });

  file.writeAsStringSync(content);
  print('Updated sizes in checkout.dart');
}
