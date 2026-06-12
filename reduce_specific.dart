import 'dart:io';

void main() {
  final targetFiles = [
    'lib/app/ui/screens/all_orders.dart',
    'lib/app/ui/screens/order_details.dart',
    'lib/app/ui/widgets/order_card.dart',
  ];

  for (final path in targetFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      continue;
    }

    String content = file.readAsStringSync();
    bool changed = false;

    // Scale DOWN by 10% (multiply by 0.90)
    content = content.replaceAllMapped(RegExp(r'\b(\d+)\.(w|h|sp|r|dg)\b'), (match) {
      changed = true;
      int val = int.parse(match.group(1)!);
      int newVal = (val * 0.90).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '$newVal.${match.group(2)}';
    });

    if (changed) {
      file.writeAsStringSync(content);
      print('Slightly reduced sizes in $path');
    }
  }
}
