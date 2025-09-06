import 'dart:async';

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
  final List<String> splashImages = [
    'assets/icons/splashLogo.png',
    'assets/icons/app_logo.png',
    'assets/icons/splashLogo.png',
    'assets/icons/splashLogo.png',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startImageSlideshow();
    _checkLoginStatus();
  }

  void _startImageSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % splashImages.length;
      });
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 4)); // total splash time

    final session = Supabase.instance.client.auth.currentSession;

    _timer?.cancel(); // stop timer after navigation

    if (session != null && session.user != null) {
      Get.offAllNamed(AppRoutes.ROOT);
    } else {
      Get.offAllNamed(AppRoutes.GETSTARTED);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // New image: slide from right
            final slideIn = Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation);

            // Old image: instantly removed (no animation)
            if (child.key == ValueKey<int>(_currentIndex)) {
              return SlideTransition(
                position: slideIn,
                child: child,
              );
            } else {
              return const SizedBox.shrink(); // remove immediately
            }
          },
          child: Image.asset(
            splashImages[_currentIndex],
            key: ValueKey<int>(_currentIndex), // important for switching
            height: 150,
          ),
        ),
      ),
    );
  }
}
