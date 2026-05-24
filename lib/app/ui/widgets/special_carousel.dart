import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
// Removed get_storage import - using SharedPreferences instead
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show sin, cos, pi;

class SpecialCarousel extends StatefulWidget {
  const SpecialCarousel({super.key});

  @override
  State<SpecialCarousel> createState() => _SpecialCarouselState();
}

class _SpecialCarouselState extends State<SpecialCarousel>
    with TickerProviderStateMixin {
  final HomePageController controller = Get.find<HomePageController>();
  final ProfileController profileController = Get.find<ProfileController>();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  late final Razorpay _razorpay;
  int _current = 0;
  // Removed GetStorage - using SharedPreferences instead
  final RxBool _isProcessingPayment =
      false.obs; // Made this an RxBool to be passed to other widgets

  late final AnimationController _cardAnimationController;
  
  // Add loading state for subscription status
  final RxBool _isLoadingStatus = true.obs;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Load subscription status on widget initialization
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      _isLoadingStatus.value = true;
      
      // Wait for subscriptions to be loaded if not already
      if (controller.subscriptions.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      int userId = await controller.fetchUserDetails();
      await controller.preloadSubscribedStatus(userId);
    } catch (e) {
      debugPrint("Error loading subscription status: $e");
    } finally {
      _isLoadingStatus.value = false;
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pageController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _openCheckout(Map sub) {
    if (controller.isGuestMode.value) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFF3D52A0)),
              SizedBox(width: 10.w),
              const Text('Login Required'),
            ],
          ),
          content: const Text(
              'Please login or create an account to purchase a subscription.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D52A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                Get.back();
                Get.toNamed('/login');
              },
              child: const Text('Login',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (_isProcessingPayment.value) return;

    // Check if user already has any active subscription (force reactive read)
    final hasActiveSubscription =
        controller.subscribedStatus.value.values.any((status) => status == true);

    if (hasActiveSubscription) {
      Get.snackbar(
        "Already Subscribed",
        "You already have an active subscription. Please complete or cancel it before subscribing to another plan.",
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final price = num.tryParse(sub['discounted_price'].toString()) ?? 0;
      final amountInPaise = (price * 100).round();

      if (amountInPaise <= 0) {
        Get.snackbar("Invalid amount", "Subscription price is invalid.");
        return;
      }

      final options = {
        'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
        'amount': amountInPaise,
        'name': "Laundry App",
        'description': sub['name'] ?? 'Subscription',
      };

      _isProcessingPayment.value = true;
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      _isProcessingPayment.value = false;
      Get.snackbar("Payment Error", "Could not start payment. Try again.");
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final sub = controller.subscriptions[_current];
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        Get.snackbar('Error', 'User not logged in');
        _isProcessingPayment.value = false;
        return;
      }

      final subscriptionData = {
        'user_id': '$userId',
        'payment_method': 0,
        'amount': sub['discounted_price'],
        'transaction_id': response.paymentId,
        'created_at': DateTime.now().toIso8601String(),
        "order_id": "0",
        "status": 1,
      };

      await controller.supabase.from('transactions').insert(subscriptionData);
      final success = await controller.subscribeUser(sub);

      if (success) {
        // Refresh subscription status from database after successful subscription
        int userId = await controller.fetchUserDetails();
        await controller.preloadSubscribedStatus(userId);
        
        final updatedSubscriptions = List<Map<String, dynamic>>.from(
          controller.subscriptions,
        );
        final index = updatedSubscriptions.indexWhere(
          (s) => s['id'] == sub['id'],
        );

        if (index != -1) {
          updatedSubscriptions[index] = {
            ...updatedSubscriptions[index],
            'isSubscribed': true,
          };
          controller.subscriptions.value = updatedSubscriptions;
        }

        Get.snackbar(
          "Success",
          "Subscription activated!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to activate subscription",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, st) {
      debugPrint("Payment Success Handling Error: $e\n$st");
      Get.snackbar(
        "Error",
        "Something went wrong while subscribing",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isProcessingPayment.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessingPayment.value = false;
    Get.snackbar("Payment Failed", response.message ?? "Something went wrong");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessingPayment.value = false;
    Get.snackbar("External Wallet", response.walletName ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.subscriptions.isEmpty) {
        return const Center(
          child: Text(
            "No special offers available",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      // Show loading while subscription status is being fetched
      if (_isLoadingStatus.value) {
        return SizedBox(
          height: 200.h,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: controller.subscriptions.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                final sub = controller.subscriptions[index];

                return GestureDetector(
                  onTap: () {
                    final isSubscribed = controller.subscribedStatus.value[sub['id']] ?? false;
                    _showSubscriptionDetail(context, sub, isSubscribed, _openCheckout, _isProcessingPayment);
                  },
                  child: Hero(
                    tag: 'subscription-card-${sub['id']}',
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = (_pageController.page! - index).abs();
                          value = (1 - (value * 0.2)).clamp(0.8, 1.0);
                        }
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Obx(() {
                        // Reactive read of subscription status for this specific card
                        final isSubscribed = controller.subscribedStatus.value[sub['id']] ?? false;
                        
                        return SubscriptionCard(
                          sub: sub,
                          isSubscribed: isSubscribed,
                          onSubscribe: _isProcessingPayment.value
                              ? null
                              : () => _openCheckout(sub),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10.h),

          // Dots indicator with dynamic animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.subscriptions.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 8.h,
                width: _current == index ? 22 : 8,
                decoration: BoxDecoration(
                  color: _current == index
                      ? AppTheme.primaryColor
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}

// Global function and widgets must be defined outside the class
void _showSubscriptionDetail(
  BuildContext context,
  Map sub,
  bool isSubscribed,
  Function(Map) openCheckout,
  RxBool isProcessingPayment,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Stack(
            children: [
              // Animated Background Layer
              const Positioned.fill(
                child: _AnimatedBackground(),
              ),
              // Main Content Layer
              Padding(
                padding: EdgeInsets.only(top: 16.0.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Draggable handle
                    Container(
                      height: 4.h,
                      width: 60.w,
                      margin: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Hero(
                        tag: 'subscription-card-${sub['id']}',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  const Color(0xFF232F46),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sub['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 28.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 36.sp,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                if (sub['description'] != null)
                                  Text(
                                    sub['description'],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                SizedBox(height: 20.h),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${sub['discounted_price']}",
                                      style: TextStyle(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB5FFC8),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "₹${sub['original_price']}",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: Colors.white54,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "${sub['pieces']} pcs • ${sub['validity_days']} days",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                    // Separated button section
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0.w, vertical: 16.0.h),
                      child: Obx(
                        () => SubscribeButton(
                          isSubscribed: isSubscribed,
                          onSubscribe: isProcessingPayment.value
                              ? null
                              : () {
                                  openCheckout(sub);
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Custom widget for the animated background
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavyDotsPainter(
            animationValue: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _WavyDotsPainter extends CustomPainter {
  final double animationValue;

  _WavyDotsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double i = 0; i <= size.width; i += 40) {
      for (double j = 0; j <= size.height; j += 40) {
        final xOffset = i + 10 * sin(animationValue * 2 * pi + j / 100);
        final yOffset = j + 10 * cos(animationValue * 2 * pi + i / 100);

        canvas.drawCircle(Offset(xOffset, yOffset), 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = oldDelegate as _WavyDotsPainter;
    return old.animationValue != animationValue;
  }
}

class SubscriptionCard extends StatelessWidget {
  final Map sub;
  final bool isSubscribed;
  final VoidCallback? onSubscribe;

  const SubscriptionCard({
    super.key,
    required this.sub,
    required this.isSubscribed,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30.h, right: 15.w, left: 5.w),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.9),
                  Color(0xFF232F46).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.2,
                      child: Image.asset(
                        "assets/icons/special.png",
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['name'] ?? '',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${sub['discounted_price']}",
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB5FFC8),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              "₹${sub['original_price']}",
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.white70,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "${sub['pieces']} pcs • ${sub['validity_days']} days",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Color.fromARGB(223, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -20,
            child: SubscribeButton(
              isSubscribed: isSubscribed,
              onSubscribe: onSubscribe,
            ),
          ),
        ],
      ),
    );
  }
}

class SubscribeButton extends StatefulWidget {
  final bool isSubscribed;
  final VoidCallback? onSubscribe;

  const SubscribeButton({
    super.key,
    required this.isSubscribed,
    required this.onSubscribe,
  });

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isSubscribed) _controller.forward();
      },
      onTapUp: (_) {
        if (!widget.isSubscribed) _controller.reverse();
      },
      onTapCancel: () {
        if (!widget.isSubscribed) _controller.reverse();
      },
      onTap: widget.isSubscribed
          ? () => Get.snackbar('Subscribed', 'Already Subscribed')
          : widget.onSubscribe,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: widget.isSubscribed ? Colors.grey[400] : Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            widget.isSubscribed ? "Subscribed" : "Subscribe",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: widget.isSubscribed ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}