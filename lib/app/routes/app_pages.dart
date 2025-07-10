// app_pages.dart
import 'package:get/get.dart';
import 'package:laundry_app/app/ui/screens/home.dart';
import 'package:laundry_app/app/ui/screens/login.dart';
import 'package:laundry_app/app/ui/screens/order.dart';
import 'package:laundry_app/app/ui/screens/splash_screen.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.SPLASHSCREEN;

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASHSCREEN, 
      page: () => const SplashScreen()
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeScreen(),
      // binding: HomeBinding(),
    ),

    GetPage(
      name: AppRoutes.ORDERS,
      page: () => const OrderScreen(),
      // binding: HomeBinding(),
    ),

    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
      // binding: HomeBinding(),
    ),
    // Add more pages here
  ];
}
