import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app/routes/app_pages.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!);
//   runApp(const MyApp());
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Removed GetStorage.init() - using SharedPreferences instead

  await dotenv.load(fileName: ".env");
  // Removed GetStorage - using SharedPreferences instead

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VK Laundry',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.SPLASHSCREEN,
          getPages: AppPages.routes,
          builder: (context, child) {
            return child!;
          },
        );
      },
    );
  }
}
