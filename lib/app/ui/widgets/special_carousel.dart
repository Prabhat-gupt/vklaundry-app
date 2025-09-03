import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SpecialCarousel extends StatefulWidget {
  const SpecialCarousel({super.key});

  @override
  State<SpecialCarousel> createState() => _SpecialCarouselState();
}

class _SpecialCarouselState extends State<SpecialCarousel> {
  final HomePageController controller = Get.find<HomePageController>();
  int _current = 0;
  final PageController _controller = PageController(viewportFraction: 0.88);
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    ever(controller.subscriptions, (_) async {
      int userId = await controller.fetchUserDetails();
      await controller.preloadSubscribedStatus(userId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  /// Start Razorpay Checkout
  void _openCheckout(Map sub) {
    var options = {
      'key': 'rzp_test_R5aav0MP84trbb', // Replace with your Razorpay Key
      'amount': sub['discounted_price'] * 100, // in paise
      'name': "Laundry App",
      'description': sub['name'],
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Handle Success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final sub = controller.subscriptions[_current];

    DateTime startDate = DateTime.now();
    DateTime endDate = startDate.add(Duration(days: sub['validity_days']));

    // Call backend API to insert into "user_subscriptions"
    await controller.subscribeUser(sub);

    // 🔥 Instead of setState, update GetX reactive map
    controller.subscribedStatus[sub['id']] = true;
    controller.subscribedStatus.refresh();

    // Old code (kept as per your request)
    setState(() {
      sub['isSubscribed'] = true;
    });

    // ✅ Show snackbar before closing anything
    Get.snackbar("Success", "Subscription activated!",
        snackPosition: SnackPosition.TOP);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar("Payment Failed", response.message ?? "Something went wrong");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar("External Wallet", response.walletName ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.subscriptions.isEmpty) {
        return const Center(child: Text("No subscriptions available"));
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _controller,
              itemCount: controller.subscriptions.length,
              onPageChanged: (index) {
                setState(() => _current = index);
              },
              itemBuilder: (context, index) {
                final sub = controller.subscriptions[index];

                // ❌ Removed FutureBuilder to avoid build-time async issues
                // ✅ Use Obx reactive state instead
                final isSubscribed =
                    controller.subscribedStatus[sub['id']] ?? false;

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub['name'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (sub['description'] != null)
                                Text(
                                  sub['description'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Text(
                                    "₹${sub['discounted_price']}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${sub['original_price']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${sub['pieces']} pcs • ${sub['validity_days']} days",
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: isSubscribed
                                    ? null
                                    : () async {
                                        bool alreadyHasSub = await controller
                                            .hasAnyActiveSubscription();
                                        if (alreadyHasSub) {
                                          print(
                                              "User already has an active subscription.");
                                          Get.snackbar(
                                            "Not Allowed",
                                            "You already have an active subscription.",
                                            snackPosition: SnackPosition.TOP,
                                          );
                                          return;
                                        }
                                        _openCheckout(sub);
                                      },
                                child: Text(
                                  isSubscribed ? "Subscribed" : "Subscribe",
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_controller.position.haveDimensions) {
                        value = (_controller.page! - index).abs();
                        value = (1 - (value * 0.2)).clamp(0.8, 1.0);
                      }
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 30, right: 10),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                image: const DecorationImage(
                                  image: AssetImage("assets/icons/special.png"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 2, sigmaY: 2),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.25),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sub['name'],
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${sub['discounted_price']}",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "₹${sub['original_price']}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white70,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor: Colors.white,
                                                decorationThickness: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${sub['pieces']} pcs • ${sub['validity_days']} days",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(
                                                223, 255, 255, 255),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Floating Subscribe Button
                          Positioned(
                            right: 20,
                            bottom: -18,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 12),
                                elevation: 6,
                              ),
                              onPressed: isSubscribed
                                  ? () {
                                      Get.snackbar(
                                          'Subscribed', 'Already Subscribed');
                                    }
                                  : () async {
                                      bool alreadyHasSub = await controller
                                          .hasAnyActiveSubscription();
                                      if (alreadyHasSub) {
                                        print(
                                            "User already has an active subscription.");
                                        Get.snackbar(
                                          "Not Allowed",
                                          "You already have an active subscription.",
                                          snackPosition: SnackPosition.TOP,
                                        );
                                        return;
                                      }

                                      _openCheckout(sub);
                                    },
                              child: Text(
                                isSubscribed ? "Subscribed" : "Subscribe",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Dots Indicator
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
