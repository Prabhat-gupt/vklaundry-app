import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  await GetStorage.init();

  await dotenv.load(fileName: ".env");
  final storages = GetStorage();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  final isLoggedIn = storages.read('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VK Laundry',
      theme: AppTheme.lightTheme,
      // initialRoute: isLoggedIn AppPages.Homepage,
      initialRoute: isLoggedIn ? AppRoutes.ROOT : AppRoutes.SPLASHSCREEN,

      getPages: AppPages.routes,
    );
  }
}
