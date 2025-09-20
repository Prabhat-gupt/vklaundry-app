import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  final bool? isLoggedIn;
  SplashScreen({this.isLoggedIn = false, super.key});

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

  // @override
  // void initState() {
  //   super.initState();
  //   _startImageSlideshow();
  //   // _checkLoginStatus();
  //   final storages = GetStorage();

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final isLoggedIn = storages.read('isLoggedIn') ?? false;
  //     print("my login status is ::::::: $isLoggedIn");
  //     // isLoggedIn ? AppRoutes.ROOT : AppRoutes.SPLASHSCREEN;
  //     if (isLoggedIn) {
  //       Navigator.pushReplacementNamed(context, AppRoutes.ROOT);
  //     } else {
  //       Navigator.pushReplacementNamed(context, AppRoutes.SPLASHSCREEN);
  //     }
  //   });
  // }

  bool _navigated = false; // add this as a state variable

  @override
  void initState() {
    super.initState();
    _startImageSlideshow();
    final storages = GetStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigated) return; // 👈 prevent multiple calls
      _navigated = true;

      final isLoggedIn = storages.read('isLoggedIn') ?? false;
      print("my login status is ::::::: $isLoggedIn");

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppRoutes.ROOT);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.GETSTARTED);
      }
    });
  }

  void _startImageSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % splashImages.length;
      });
    });
  }

  // Future<void> _checkLoginStatus() async {
  //   await Future.delayed(const Duration(seconds: 2));

  //   final newVersion = NewVersionPlus(
  //     androidId: "com.example.laundry_app",
  //   );

  //   final status = await newVersion.getVersionStatus();

  //   print("my status is :::: printing here :::: ${status}");

  //   if (status != null && status.canUpdate) {
  //     final url = status.appStoreLink;
  //     print("my url is :::: url here :::: ${url}");

  //     if (await canLaunchUrl(Uri.parse(url))) {
  //       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //     }
  //     return;
  //   }

  //   final session = Supabase.instance.client.auth.currentSession;

  //   _timer?.cancel();

  //   if (session != null && session.user != null) {
  //     Get.offAllNamed(AppRoutes.ROOT);
  //   } else {
  //     Get.offAllNamed(AppRoutes.GETSTARTED);
  //   }
  // }

  // uncomment it when it upload to the playstore

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
              return SlideTransition(position: slideIn, child: child);
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
