import 'dart:io';

void main() {
  final files = Directory('lib/app/ui').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    if (file.path.contains('checkout.dart')) continue;
    String content = file.readAsStringSync();
    bool changed = false;

    // Safely remove const before known UI classes that might be injected with .w
    content = content.replaceAll(RegExp(r'const\s+(SizedBox|EdgeInsets|BorderRadius|Radius|Padding|Text|Icon|Positioned|Container|Spacer|Expanded|Flexible|Column|Row|BoxDecoration|TextStyle|Center|Align|Stack|ListView|GridView|SingleChildScrollView|Opacity|SlideTransition|AnimatedContainer|AnimatedOpacity|Transform|AnimatedBuilder|Curve|CurvedAnimation|Tween|Duration|Color|Colors)'), r'$1');
    content = content.replaceAll(RegExp(r'const\s+(Widget|TextSpan|RichText|Material|InkWell|FittedBox|ClipRRect|Image|DecorationImage|LinearGradient|Gradient|BoxShadow|IconData|FontWeight|MainAxisAlignment|CrossAxisAlignment)'), r'$1');

    // Remove const array literal `const [`
    content = content.replaceAll(RegExp(r'const\s+\['), '[');
    // Remove `const` before map literals `const {`
    content = content.replaceAll(RegExp(r'const\s+\{'), '{');

    // target: height: 20 -> height: 15.w
    content = content.replaceAllMapped(RegExp(r'(height|width|fontSize|radius|size)\s*:\s*(\d+(\.\d+)?)(?!\.w|\.h|\.sp|\.r)'), (match) {
      changed = true;
      double val = double.parse(match.group(2)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '${match.group(1)}: $newVal.w';
    });

    // target: EdgeInsets.all(20) -> EdgeInsets.all(15.w)
    content = content.replaceAllMapped(RegExp(r'\.all\(\s*(\d+(\.\d+)?)\s*\)'), (match) {
      changed = true;
      double val = double.parse(match.group(1)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '.all($newVal.w)';
    });

    // target: Radius.circular(20) -> Radius.circular(15.w)
    content = content.replaceAllMapped(RegExp(r'\.circular\(\s*(\d+(\.\d+)?)\s*\)'), (match) {
      changed = true;
      double val = double.parse(match.group(1)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '.circular($newVal.w)';
    });

    // target: symmetric(horizontal: 20) -> symmetric(horizontal: 15.w)
    content = content.replaceAllMapped(RegExp(r'(horizontal|vertical|top|bottom|left|right)\s*:\s*(\d+(\.\d+)?)(?!\.w|\.h|\.sp|\.r)'), (match) {
      changed = true;
      double val = double.parse(match.group(2)!);
      if (val == 0) return match.group(0)!;
      int newVal = (val * 0.75).round();
      if (newVal == 0 && val > 0) newVal = 1;
      return '${match.group(1)}: $newVal.w';
    });

    // target: offset: Offset(0, 10) -> offset: Offset(0, 8.w)
    content = content.replaceAllMapped(RegExp(r'Offset\(\s*(\d+(\.\d+)?)\s*,\s*(\d+(\.\d+)?)\s*\)'), (match) {
      changed = true;
      double val1 = double.parse(match.group(1)!);
      double val2 = double.parse(match.group(3)!);
      int newVal1 = (val1 * 0.75).round();
      int newVal2 = (val2 * 0.75).round();
      if (newVal1 == 0 && val1 > 0) newVal1 = 1;
      if (newVal2 == 0 && val2 > 0) newVal2 = 1;
      String p1 = val1 == 0 ? "0" : "$newVal1.w";
      String p2 = val2 == 0 ? "0" : "$newVal2.w";
      return 'Offset($p1, $p2)';
    });

    // Also import flutter_screenutil if missing and we changed something
    if (changed && !content.contains('flutter_screenutil.dart')) {
      content = "import 'package:flutter_screenutil/flutter_screenutil.dart';\n" + content;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated raw sizes in ${file.path}');
    }
  }
}
