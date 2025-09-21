import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Add this line

class SplashScreen extends StatefulWidget {
  final bool? isLoggedIn;
  SplashScreen({this.isLoggedIn = false, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final List<String> splashImages = [
    'assets/icons/app_logo.png',
  ];

  int _currentIndex = 0;
  Timer? _timer;
  bool _navigated = false;

  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _backgroundController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startImageSlideshow();
    _handleNavigation();
  }

  void _setupAnimations() {
    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    _floatingController.repeat(reverse: true);

    // Pulse animation for text elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Rotation animation for decorative elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotationController);
    _rotationController.repeat();

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);
    _backgroundController.repeat(reverse: true);

    // Scale animation for logo entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    _scaleController.forward();

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  void _handleNavigation() {
    final storages = GetStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigated) return;
      _navigated = true;

      final isLoggedIn = storages.read('isLoggedIn') ?? false;
      print("my login status is ::::::: $isLoggedIn");

      // Add delay for better UX
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          if (isLoggedIn) {
            Navigator.pushReplacementNamed(context, AppRoutes.ROOT);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.GETSTARTED);
          }
        }
      });
    });
  }

  void _startImageSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % splashImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _floatingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _backgroundController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.primaryColor,
                ],
                stops: [
                  0.0,
                  _backgroundAnimation.value,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background decoration circles
                ...List.generate(6, (index) {
                  return AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = _rotationAnimation.value + (index * pi / 3);
                      final radius = size.width * 0.4;
                      final x = size.width / 2 + cos(angle) * radius;
                      final y = size.height / 2 + sin(angle) * radius;

                      return Positioned(
                        left: x - 15,
                        top: y - 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container with enhanced animations
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -_floatingAnimation.value),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(
                                // padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  switchInCurve: Curves.easeOutCubic,
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    final slideIn = Tween<Offset>(
                                      begin: const Offset(0.3, 0),
                                      end: Offset.zero,
                                    ).animate(animation);

                                    if (child.key == ValueKey<int>(_currentIndex)) {
                                      return SlideTransition(position: slideIn, child: child);
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                  child: Image.asset(
                                    splashImages[_currentIndex],
                                    key: ValueKey<int>(_currentIndex),
                                    height: 200,
                                    width: 200,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // App title with fade-in animation
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: Column(
                          children: [
                            // Text(
                            //   'Laundry App',
                            //   style: TextStyle(
                            //     fontSize: 42,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.white,
                            //     letterSpacing: 1.5,
                            //     shadows: [
                            //       Shadow(
                            //         color: Colors.black.withOpacity(0.3),
                            //         offset: const Offset(0, 2),
                            //         blurRadius: 4,
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VK Laundary',
                                  style: TextStyle(
                                    fontSize: 42,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(seconds: 2),
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                  child: Text(
                                    'Your Laundry, Our Priority',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            //



                          ],
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Loading indicator
                      // AnimatedBuilder(
                      //   animation: _pulseAnimation,
                      //   builder: (context, child) {
                      //     return Transform.scale(
                      //       scale: _pulseAnimation.value,
                      //       child: Column(
                      //         children: [
                      //           Container(
                      //             width: 40,
                      //             height: 40,
                      //             decoration: BoxDecoration(
                      //               shape: BoxShape.circle,
                      //               border: Border.all(
                      //                 color: Colors.white,
                      //                 width: 3,
                      //               ),
                      //             ),
                      //             child: const CircularProgressIndicator(
                      //               strokeWidth: 2,
                      //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //             ),
                      //           ),
                      //           const SizedBox(height: 16),
                      //           Text(
                      //             'Loading...',
                      //             style: TextStyle(
                      //               color: Colors.white.withOpacity(0.8),
                      //               fontSize: 14,
                      //               letterSpacing: 1.0,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),

                // Floating particles animation
                ...List.generate(8, (index) {
                  return AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = _rotationAnimation.value * (index.isEven ? 1 : -1) + (index * pi / 4);
                      final radius = (size.width * 0.6) + (index * 10);
                      final x = size.width / 2 + cos(angle) * radius;
                      final y = size.height / 2 + sin(angle) * radius;

                      return Positioned(
                        left: x - 3,
                        top: y - 3,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}