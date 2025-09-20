import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SpecialCarousel extends StatefulWidget {
  const SpecialCarousel({super.key});

  @override
  State<SpecialCarousel> createState() => _SpecialCarouselState();
}

class _SpecialCarouselState extends State<SpecialCarousel> {
  final HomePageController controller = Get.find<HomePageController>();
  final ProfileController profileController = Get.find<ProfileController>();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  late final Razorpay _razorpay;
  int _current = 0;
  final storage = GetStorage();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

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
    super.dispose();
  }

  /// Open Razorpay checkout
  void _openCheckout(Map sub) {
    if (_isProcessingPayment) return;

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

      _isProcessingPayment = true;
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      _isProcessingPayment = false;
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

      // Save transaction
      await controller.supabase.from('transactions').insert(subscriptionData);

      // Update subscription in Supabase
      final success = await controller.subscribeUser(sub);

      if (success) {
        // Update the subscription status without triggering multiple rebuilds
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

          // Update both states in a single operation
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
      _isProcessingPayment = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessingPayment = false;
    Get.snackbar("Payment Failed", response.message ?? "Something went wrong");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessingPayment = false;
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
              controller: _pageController,
              itemCount: controller.subscriptions.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                final sub = controller.subscriptions[index];
                final isSubscribed =
                    controller.subscribedStatus[sub['id']] ?? false;

                return GestureDetector(
                  onTap: () =>
                      _showSubscriptionDetail(context, sub, isSubscribed),
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
                      onSubscribe: _isProcessingPayment
                          ? null
                          : () => _openCheckout(sub),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Dots indicator
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

  void _showSubscriptionDetail(
    BuildContext context,
    Map sub,
    bool isSubscribed,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sub['name'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (sub['description'] != null)
                Text(sub['description'], style: const TextStyle(fontSize: 16)),
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
              SubscribeButton(
                isSubscribed: isSubscribed,
                onSubscribe:
                    _isProcessingPayment ? null : () => _openCheckout(sub),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card widget
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
      margin: const EdgeInsets.only(bottom: 30, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background
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
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(color: Colors.black.withOpacity(0.25)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
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

          // Floating button
          Positioned(
            right: 20,
            bottom: -18,
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

/// Reusable Subscribe Button
class SubscribeButton extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback? onSubscribe;

  const SubscribeButton({
    super.key,
    required this.isSubscribed,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed ? Colors.white70 : Colors.white,
        foregroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        elevation: 6,
      ),
      onPressed: isSubscribed
          ? () => Get.snackbar('Subscribed', 'Already Subscribed')
          : onSubscribe,
      child: Text(
        isSubscribed ? "Subscribed" : "Subscribe",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
