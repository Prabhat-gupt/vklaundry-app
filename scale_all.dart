import 'dart:io';

void main() {
  final files = Directory('lib/app/ui').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Fix const issues
    final constWidgets = r'SizedBox|EdgeInsets|BorderRadius|Radius|Padding|Text|Icon|Positioned|Container|Spacer|Expanded|Flexible|Column|Row|BoxDecoration|TextStyle|Center|Align|Stack|ListView|GridView|SingleChildScrollView|Opacity|SlideTransition|AnimatedContainer|AnimatedOpacity|Transform|AnimatedBuilder|Curve|CurvedAnimation|Tween|Duration|Color|Colors|Widget|TextSpan|RichText|Material|InkWell|FittedBox|ClipRRect|Image|DecorationImage|LinearGradient|Gradient|BoxShadow|IconData|FontWeight|MainAxisAlignment|CrossAxisAlignment';
    content = content.replaceAllMapped(RegExp('const\\s+($constWidgets)'), (m) {
      changed = true;
      return m.group(1)!;
    });
    content = content.replaceAllMapped(RegExp(r'const\s+\['), (m) { changed = true; return '['; });
    content = content.replaceAllMapped(RegExp(r'const\s+\{'), (m) { changed = true; return '{'; });

    // Protect against backtracking by rejecting any match that is followed by a digit or dot
    // This perfectly isolates RAW numbers and completely ignores numbers that already have .w, .h, .sp etc.
    final numPattern = r'(\d+(\.\d+)?)(?![\d\.])(?!\s*\.(w|h|sp|r|dg|0))';

    content = content.replaceAllMapped(RegExp(r'(height|width|fontSize|radius|size)\s*:\s*' + numPattern), (match) {
      changed = true;
      double val = double.parse(match.group(2)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '${match.group(1)}: $newVal.w';
    });

    content = content.replaceAllMapped(RegExp(r'\.all\(\s*' + numPattern + r'\s*\)'), (match) {
      changed = true;
      double val = double.parse(match.group(1)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '.all($newVal.w)';
    });

    content = content.replaceAllMapped(RegExp(r'\.circular\(\s*' + numPattern + r'\s*\)'), (match) {
      changed = true;
      double val = double.parse(match.group(1)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '.circular($newVal.w)';
    });

    content = content.replaceAllMapped(RegExp(r'(horizontal|vertical|top|bottom|left|right)\s*:\s*' + numPattern), (match) {
      changed = true;
      double val = double.parse(match.group(2)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '${match.group(1)}: $newVal.w';
    });

    // NOW shrink ALREADY screenutil'd sizes
    // Use the same (?![\d\.]) logic to parse the float properly!
    // e.g. 20.0.w -> we match 20.0, and unit is w.
    content = content.replaceAllMapped(RegExp(r'(\d+(\.\d+)?)(?![\d\.])\.(w|h|sp|r|dg)\b'), (match) {
      changed = true;
      double val = double.parse(match.group(1)!);
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      // Change .h to .w so everything scales by width (proportional scaling)
      String unit = match.group(3)!;
      if (unit == 'h') unit = 'w';
      return '$newVal.$unit';
    });

    if (changed && !content.contains('flutter_screenutil.dart')) {
      content = "import 'package:flutter_screenutil/flutter_screenutil.dart';\n" + content;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Processed ${file.path}');
    }
  }
}
