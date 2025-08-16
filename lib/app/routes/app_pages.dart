// app_pages.dart
import 'package:get/get.dart';
import 'package:laundry_app/app/ui/screens/add_address.dart';
import 'package:laundry_app/app/ui/screens/address_screen.dart';
import 'package:laundry_app/app/ui/screens/all_orders.dart';
import 'package:laundry_app/app/ui/screens/checkout.dart';
import 'package:laundry_app/app/ui/screens/get_started.dart';
import 'package:laundry_app/app/ui/screens/home.dart';
import 'package:laundry_app/app/ui/screens/login.dart';
import 'package:laundry_app/app/ui/screens/notification.dart';
import 'package:laundry_app/app/ui/screens/order_details.dart';
import 'package:laundry_app/app/ui/screens/order_screen.dart';
import 'package:laundry_app/app/ui/screens/order_success.dart';
import 'package:laundry_app/app/ui/screens/order_track.dart';
import 'package:laundry_app/app/ui/screens/otp_screen.dart';
import 'package:laundry_app/app/ui/screens/payment_select.dart';
import 'package:laundry_app/app/ui/screens/profile_screen.dart';
import 'package:laundry_app/app/ui/screens/root.dart';
import 'package:laundry_app/app/ui/screens/services.dart';
import 'package:laundry_app/app/ui/screens/setting_screen.dart';
import 'package:laundry_app/app/ui/screens/setup_page.dart';
import 'package:laundry_app/app/ui/screens/splash_screen.dart';
import 'package:laundry_app/app/ui/screens/support.dart';

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
      page: () => HomeScreen(),
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
      name: AppRoutes.SETUPSCREEN,
      page: () => const SetupScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ROOT,
      page: () => const RootPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.CATEGORY,
      page: () => const ServiceScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.CHECKOUTPAGE,
      page: () =>  CheckoutPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTING,
      page: () => const SettingsScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => ProfileScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ORDERS,
      page: () => const OrdersScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ORDERDETAILS,
      page: () => const OrderDetailsPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.TRACKING,
      page: () => TrackOrderPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ADDRESS,
      page: () => const AddressScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ADDADDRESS,
      page: () => const AddAddressScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.SUCCESS,
      page: () => const OrderSuccessPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.PAYMENTSELECT,
      page: () => PaymentSelectPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.ALLORDERS,
      page: () => AllOrdersPage(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.NOTIFICATION,
      page: () => NotificationScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.SUPPORT,
      page: () => SupportPage(),
      // binding: HomeBinding(),
    ),
  ];
}
