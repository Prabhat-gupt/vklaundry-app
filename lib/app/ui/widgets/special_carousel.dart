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
      duration: Duration(milliseconds: 600),
    );

    // Load subscription status on widget initialization
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      _isLoadingStatus.value = true;
      
      // Wait for subscriptions to be loaded if not already
      if (controller.subscriptions.isEmpty) {
        await Future.delayed(Duration(milliseconds: 500));
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
              borderRadius: BorderRadius.circular(13.r)),
          title: Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFF3D52A0)),
              SizedBox(width: 7.w),
              Text('Login Required'),
            ],
          ),
          content: Text(
              'Please login or create an account to purchase a subscription.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3D52A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
                Get.back();
                Get.toNamed('/login');
              },
              child: Text('Login',
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
        duration: Duration(seconds: 2),
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
        return Center(
          child: Text(
            "No special offers available",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      // Show loading while subscription status is being fetched
      if (_isLoadingStatus.value) {
        return SizedBox(
          height: 165.h,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 165.h,
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
          SizedBox(height: 7.h),

          // Dots indicator with dynamic animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.subscriptions.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 5.h,
                width: _current == index ? 22 : 8,
                decoration: BoxDecoration(
                  color: _current == index
                      ? AppTheme.primaryColor
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(7.r),
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
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable handle
              Container(
                height: 4.h,
                width: 32.w,
                margin: EdgeInsets.symmetric(vertical: 11.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon / Illustration
                    Container(
                      padding: EdgeInsets.all(13.r),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppTheme.primaryColor,
                        size: 31.sp,
                      ),
                    ),
                    SizedBox(height: 11.h),
                    
                    // Title
                    Text(
                      sub['name'] ?? 'Subscription Plan',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2340),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5.h),
                    
                    // Description
                    if (sub['description'] != null && sub['description'].toString().isNotEmpty)
                      _buildParsedDescription(sub['description'].toString()),
                    SizedBox(height: 16.h),

                    // Price Info Box
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 13.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(11.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${sub['discounted_price']}",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (sub['original_price'] != null)
                                Text(
                                  "₹${sub['original_price']}",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: 13.w),
                          Container(
                            width: 1.w,
                            height: 27.h,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(width: 13.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.checkroom_rounded, size: 11.sp, color: Colors.grey[600]),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "${sub['pieces']} pieces",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A2340),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 11.sp, color: Colors.grey[600]),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "${sub['validity_days']} days",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A2340),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 21.h),

                    // Subscribe Button
                    SafeArea(
                      top: false,
                      child: Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 36.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSubscribed ? Colors.grey[400] : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: isSubscribed ? 0 : 4,
                              shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11.r),
                              ),
                            ),
                            onPressed: isSubscribed
                                ? () => Get.snackbar('Subscribed', 'Already Subscribed')
                                : (isProcessingPayment.value
                                    ? null
                                    : () => openCheckout(sub)),
                            child: isProcessingPayment.value
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    isSubscribed ? "Subscribed" : "Subscribe Now",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 11.h), // Extra padding above the safe area bottom
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

Widget _buildParsedDescription(String description) {
  if (!description.contains('Includes') && !description.contains('Eligible Garments')) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 11.sp,
        color: Colors.grey[600],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  List<String> lines = description.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  
  List<Widget> includeWidgets = [];
  List<Widget> eligibleWidgets = [];
  
  bool isEligibleSection = false;
  bool isIncludesSection = false;
  
  for (String line in lines) {
    if (line.toLowerCase() == 'includes') {
      isIncludesSection = true;
      isEligibleSection = false;
      continue;
    } else if (line.toLowerCase() == 'eligible garments' || line.toLowerCase() == 'eligible items') {
      isEligibleSection = true;
      continue;
    }
    
    if (isEligibleSection) {
      eligibleWidgets.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            line,
            style: TextStyle(fontSize: 10.sp, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
        )
      );
    } else if (isIncludesSection) {
      includeWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 14.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        )
      );
    } else {
       includeWidgets.add(
         Padding(
           padding: EdgeInsets.only(bottom: 6.h),
           child: Text(
             line,
             style: TextStyle(fontSize: 11.sp, color: Colors.grey[800]),
           ),
         )
       );
    }
  }

  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeWidgets.isNotEmpty) ...[
          Text(
            'Includes',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          SizedBox(height: 10.h),
          ...includeWidgets,
          SizedBox(height: 12.h),
        ],
        if (eligibleWidgets.isNotEmpty) ...[
          Text(
            'Eligible Garments',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: eligibleWidgets,
          ),
        ]
      ],
    ),
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
      duration: Duration(seconds: 15),
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
      margin: EdgeInsets.only(bottom: 20.h, right: 11.w, left: 4.w),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
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
              borderRadius: BorderRadius.circular(16.r),
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
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['name'] ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${sub['discounted_price']}",
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB5FFC8),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "₹${sub['original_price']}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white70,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "${sub['pieces']} pcs • ${sub['validity_days']} days",
                          style: TextStyle(
                            fontSize: 10.sp,
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
            right: 12.w,
            bottom: -13.w,
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
      duration: Duration(milliseconds: 150),
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
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.w),
          decoration: BoxDecoration(
            color: widget.isSubscribed ? Colors.grey[400] : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
              fontSize: 12.sp,
              color: widget.isSubscribed ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}