// app_pages.dart
import 'package:get/get.dart';
import 'package:laundry_app/app/ui/screens/category.dart';
import 'package:laundry_app/app/ui/screens/get_started.dart';
import 'package:laundry_app/app/ui/screens/home.dart';
import 'package:laundry_app/app/ui/screens/login.dart';
import 'package:laundry_app/app/ui/screens/order.dart';
import 'package:laundry_app/app/ui/screens/otp_screen.dart';
import 'package:laundry_app/app/ui/screens/root.dart';
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
      name: AppRoutes.GETSTARTED,
      page: () => const GetStarted(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.OTPSCREEN,
      page: () => const OtpScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ROOT,
      page: () => const RootPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.CATEGORY,
      page: () => const CategoryScreen(),
      // binding: HomeBinding(),
    ),
    // Add more pages here
  ];
}
