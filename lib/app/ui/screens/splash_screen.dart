// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // simulate splash delay

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && session.user != null) {
      // User is already logged in
      Get.offAllNamed(AppRoutes.ROOT);
    } else {
      // No user session
      Get.offAllNamed(AppRoutes.GETSTARTED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: const Center(
        child: Image(image: AssetImage('assets/icons/splashLogo.png')),
      ),
    );
  }
}
