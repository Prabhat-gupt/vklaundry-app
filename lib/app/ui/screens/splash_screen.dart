import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      duration: Duration(seconds: 4),
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
      duration: Duration(milliseconds: 2000),
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
      duration: Duration(seconds: 15),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_rotationController);
    _rotationController.repeat();

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);
    _backgroundController.repeat(reverse: true);

    // Scale animation for logo entrance
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1500),
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
      duration: Duration(milliseconds: 2000),
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

  void _handleNavigation() async {
    // Use SharedPreferences instead of GetStorage to match login_controller
    final prefs = await SharedPreferences.getInstance();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_navigated) return;
      _navigated = true;

      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final isGuest = prefs.getBool('isGuest') ?? false;

      // Add delay for better UX and to let Supabase session restore
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        if (isLoggedIn) {
          // Reload prefs after delay to get updated userId
          final updatedPrefs = await SharedPreferences.getInstance();

          // Check service availability before navigating
          final isServiceAvailable =
              await _checkServiceAvailability(updatedPrefs);

          if (isServiceAvailable['available'] == true) {
            Navigator.pushReplacementNamed(context, AppRoutes.ROOT);
          } else {
            // Navigate to service not available screen
            Get.off(() => ServiceNotAvailableScreen(
                  distance: isServiceAvailable['distance'] ?? 0.0,
                ));
          }
        } else if (isGuest) {
          // Guest user — go directly to home, no login needed
          Navigator.pushReplacementNamed(context, AppRoutes.ROOT);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.GETSTARTED);
        }
      }
    });
  }

  Future<Map<String, dynamic>> _checkServiceAvailability(SharedPreferences prefs) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Try to get user ID from SharedPreferences (key is 'user_id' with underscore)
      int? numericUserId = prefs.getInt('user_id');
      
      // If not in SharedPreferences, try to get from Supabase auth
      if (numericUserId == null) {
        final userId = supabase.auth.currentUser?.id;
        
        if (userId != null) {
          // Fetch numeric user ID from database
          try {
            final userResponse = await supabase
                .from('users')
                .select('id')
                .eq('uuid', userId)
                .single();
            
            numericUserId = userResponse['id'] as int;
          } catch (e) {
            // Error fetching user ID
          }
        }
      }
      
      if (numericUserId == null) {
        return {'available': true, 'distance': 0.0};
      }
      
      // Fetch user address with coordinates directly using numeric user ID
      final addressResponse = await supabase
          .from('addresses')
          .select('latitude, longitude')
          .eq('id', numericUserId)
          .limit(1);
      
      if (addressResponse.isEmpty) {
        return {'available': true, 'distance': 0.0};
      }
      
      final address = addressResponse.first;
      final latValue = address['latitude'];
      final lonValue = address['longitude'];
      
      if (latValue == null || lonValue == null) {
        return {'available': true, 'distance': 0.0};
      }
      
      final lat = (latValue as num).toDouble();
      final lon = (lonValue as num).toDouble();
      
      // Service center coordinates
      const centerLat = 17.608400;
      const centerLon = 78.466200;
      const serviceRadiusKm = 10.0;
      
      // Calculate distance using Haversine formula
      final distance = _calculateDistance(centerLat, centerLon, lat, lon);
      
      final isAvailable = distance <= serviceRadiusKm;
      
      print('🎯 Is service available: $isAvailable (distance: ${distance.toStringAsFixed(2)} km)');
      
      if (!isAvailable) {
        print('⚠️ Splash: Service not available - ${distance.toStringAsFixed(2)} km away');
      } else {
        print('✅ Splash: Service available - within ${serviceRadiusKm} km radius');
      }
      
      return {'available': isAvailable, 'distance': distance};
    } catch (e, stackTrace) {
      print('❌ Error checking service availability: $e');
      print('Stack trace: $stackTrace');
      return {'available': true, 'distance': 0.0}; // Default to available on error
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));
    
    double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _startImageSlideshow() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
                          width: 29.w,
                          height: 29.h,
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
                              padding: EdgeInsets.all(18.r),
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
                                // padding: EdgeInsets.all(18.r),
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
                                  duration: Duration(milliseconds: 500),
                                  switchInCurve: Curves.easeOutCubic,
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    final slideIn = Tween<Offset>(
                                      begin: const Offset(0.3, 0),
                                      end: Offset.zero,
                                    ).animate(animation);

                                    if (child.key ==
                                        ValueKey<int>(_currentIndex)) {
                                      return SlideTransition(
                                          position: slideIn, child: child);
                                    } else {
                                      return SizedBox.shrink();
                                    }
                                  },
                                  child: Image.asset(
                                    splashImages[_currentIndex],
                                    key: ValueKey<int>(_currentIndex),
                                    height: 188.h,
                                    width: 188.w,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 56.h),

                      // App title with fade-in animation
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: Column(
                          children: [
                            // Text(
                            //   'Laundry App',
                            //   style: TextStyle(
                            //     fontSize: 40.sp,
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
                                  'VK Laundry',
                                  style: TextStyle(
                                    fontSize: 40.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 7.h),
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
                                      fontSize: 18.sp,
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

                      SizedBox(height: 75.h),

                      // Loading indicator
                      // AnimatedBuilder(
                      //   animation: _pulseAnimation,
                      //   builder: (context, child) {
                      //     return Transform.scale(
                      //       scale: _pulseAnimation.value,
                      //       child: Column(
                      //         children: [
                      //           Container(
                      //             width: 38.w,
                      //             height: 38.h,
                      //             decoration: BoxDecoration(
                      //               shape: BoxShape.circle,
                      //               border: Border.all(
                      //                 color: Colors.white,
                      //                 width: 3.w,
                      //               ),
                      //             ),
                      //             child: const CircularProgressIndicator(
                      //               strokeWidth: 2,
                      //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //             ),
                      //           ),
                      //           SizedBox(height: 15.h),
                      //           Text(
                      //             'Loading...',
                      //             style: TextStyle(
                      //               color: Colors.white.withOpacity(0.8),
                      //               fontSize: 14.sp,
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
                      final angle =
                          _rotationAnimation.value * (index.isEven ? 1 : -1) +
                              (index * pi / 4);
                      final radius = (size.width * 0.6) + (index * 10);
                      final x = size.width / 2 + cos(angle) * radius;
                      final y = size.height / 2 + sin(angle) * radius;

                      return Positioned(
                        left: x - 3,
                        top: y - 3,
                        child: Container(
                          width: 6.w,
                          height: 6.h,
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
