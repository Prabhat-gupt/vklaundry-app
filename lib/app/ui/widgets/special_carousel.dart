import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  final storage = GetStorage();
  final RxBool _isProcessingPayment = false.obs; // Made this an RxBool to be passed to other widgets

  late final AnimationController _cardAnimationController;

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

    once(controller.subscriptions, (_) async {
      try {
        int userId = await controller.fetchUserDetails();
        await controller.preloadSubscribedStatus(userId);
      } catch (e) {
        debugPrint("Error preloading subscription status: $e");
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pageController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _openCheckout(Map sub) {
    if (_isProcessingPayment.value) return;

    try {
      final price = num.tryParse(sub['discounted_price'].toString()) ?? 0;
      final amountInPaise = (price * 100).round();

      if (amountInPaise <= 0) {
        Get.snackbar("Invalid amount", "Subscription price is invalid.");
        return;
      }

      final options = {
        'key': 'rzp_test_R5aav0MP84trbb',
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
      final userId = "${storage.read('userId')}";

      final subscriptionData = {
        'user_id': userId,
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
          controller.subscribedStatus[sub['id']] = true;
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

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: controller.subscriptions.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                final sub = controller.subscriptions[index];
                final isSubscribed =
                    controller.subscribedStatus[sub['id']] ?? false;

                return GestureDetector(
                  onTap: () =>
                      _showSubscriptionDetail(context, sub, isSubscribed, _openCheckout, _isProcessingPayment),
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
                      child: SubscriptionCard(
                        sub: sub,
                        isSubscribed: isSubscribed,
                        onSubscribe: _isProcessingPayment.value
                            ? null
                            : () => _openCheckout(sub),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Dots indicator with dynamic animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.subscriptions.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _current == index ? 22 : 8,
                decoration: BoxDecoration(
                  color: _current == index
                      ? AppTheme.primaryColor
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Stack(
            children: [
              // Animated Background Layer
              const Positioned.fill(
                child: _AnimatedBackground(),
              ),
              // Main Content Layer
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Draggable handle
                    Container(
                      height: 4,
                      width: 60,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Hero(
                        tag: 'subscription-card-${sub['id']}',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  const Color(0xFF232F46),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sub['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 36,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (sub['description'] != null)
                                  Text(
                                    sub['description'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${sub['discounted_price']}",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB5FFC8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "₹${sub['original_price']}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white54,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "${sub['pieces']} pcs • ${sub['validity_days']} days",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Separated button section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Obx(() => SubscribeButton(
                        isSubscribed: isSubscribed,
                        onSubscribe: isProcessingPayment.value
                            ? null
                            : () {
                          openCheckout(sub);
                        },
                      ),),
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

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
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
      margin: const EdgeInsets.only(bottom: 30, right: 15, left: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.9),
                  const Color(0xFF232F46).withOpacity(0.9),
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
              borderRadius: BorderRadius.circular(24),
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
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
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB5FFC8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "₹${sub['original_price']}",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${sub['pieces']} pcs • ${sub['validity_days']} days",
                          style: const TextStyle(
                            fontSize: 14,
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
      onTap: widget.isSubscribed ? () => Get.snackbar('Subscribed', 'Already Subscribed') : widget.onSubscribe,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSubscribed ? Colors.grey[400] : Colors.white,
            borderRadius: BorderRadius.circular(30),
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
              fontSize: 14,
              color: widget.isSubscribed ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}