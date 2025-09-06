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
  final PageController _pageController = PageController(viewportFraction: 0.88);
  late final Razorpay _razorpay;
  bool _processingPayment = false; // local loading flag

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    // Register listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Example: preload subscribed status when controller.subscriptions changes
    ever(controller.subscriptions, (_) async {
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
    // remove listeners & clear
    try {
      _razorpay.clear();
    } catch (e) {
      debugPrint("Error clearing Razorpay: $e");
    }
    _pageController.dispose();
    super.dispose();
  }

  /// Open Razorpay checkout (safe option building + error handling)
  void _openCheckout(Map sub) {
    try {
      final price = num.tryParse(sub['discounted_price'].toString()) ?? 0;
      final amountInPaise = (price * 100).round();

      if (amountInPaise <= 0) {
        Get.snackbar("Invalid amount", "Subscription price is invalid.");
        return;
      }

      final options = {
        'key': 'rzp_test_R5aav0MP84trbb', // replace with your key (test/live)
        'amount': amountInPaise, // in paise
        'name': "Laundry App",
        'description': sub['name'] ?? 'Subscription',
        // optional prefill
        // 'prefill': {
        //   'contact': controller.userPhone ?? '',
        //   'email': controller.userEmail ?? '',
        // },
        // optional: pass a receipt/order id if you created an order on server
        // 'order_id': '<order_id_from_backend>',
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      Get.snackbar("Payment Error", "Could not start payment. Try again.");
    }
  }

  /// Listener wrapper (Razorpay's listener expects a void function, so we call an async worker)
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final sub = controller.subscriptions[_current];

      bool success = await controller.subscribeUser(sub);

      if (success) {
        // Update GetX state
        controller.subscribedStatus[sub['id']] = true;
        controller.subscribedStatus.refresh();

        // Local UI state (optional)
        setState(() {
          sub['isSubscribed'] = true;
        });

        Get.snackbar("Success", "Subscription activated!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to activate subscription",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e, st) {
      debugPrint("Payment Success Handling Error: $e\n$st");
      Get.snackbar("Error", "Something went wrong while subscribing");
    }
  }

  /// Async processing: verify on backend, insert subscription, update UI
  // Future<void> _processPaymentSuccess(PaymentSuccessResponse response) async {
  //   if (_processingPayment) return; // prevent double processing
  //   _processingPayment = true;

  //   final sub = controller.subscriptions[_current];
  //   try {
  //     // show non-dismissible loading dialog
  //     Get.dialog(
  //       Center(child: CircularProgressIndicator()),
  //       barrierDismissible: false,
  //     );

  //     // IMPORTANT: Verify payment on your server using razorpay signature (send paymentId, orderId, signature)
  //     // controller.subscribeUser should call your backend which:
  //     // 1) verifies the signature with Razorpay's secret
  //     // 2) inserts user_subscriptions record (start/end)
  //     // 3) returns success/failure
  //     //
  //     // We'll pass payment details to controller.subscribeUser for server verification
  //     final paymentPayload = {
  //       'payment_id': response.paymentId,
  //       'order_id': response.orderId,
  //       'signature': response.signature,
  //       'subscription_id': sub['id'],
  //       'amount': sub['discounted_price'],
  //     };

  //     // controller.subscribeUser should return bool or throw on failure.
  //     final subscribeResult = await controller.subscribeUser(
  //       sub,
  //       paymentPayload: paymentPayload,
  //     ).timeout(
  //       const Duration(seconds: 20),
  //       onTimeout: () => throw Exception('Server timed out while verifying payment'),
  //     );

  //     // subscribeResult may be bool or Map depending on your implementation
  //     final success = (subscribeResult is bool && subscribeResult == true) ||
  //         (subscribeResult is Map && subscribeResult['success'] == true);

  //     if (!success) {
  //       // backend reported failure
  //       Get.back(); // close loading dialog
  //       Get.snackbar("Subscription Failed",
  //           "Payment succeeded but activation failed. Contact support.");
  //       return;
  //     }

  //     // Update reactive states so UI refreshes properly
  //     controller.subscribedStatus[sub['id']] = true;
  //     controller.subscribedStatus.refresh();

  //     // If subscriptions is an RxList of Maps, update element and refresh list
  //     try {
  //       controller.subscriptions[_current]['isSubscribed'] = true;
  //       controller.subscriptions.refresh();
  //     } catch (_) {
  //       // ignore if structure different
  //     }

  //     Get.back(); // close loading dialog
  //     Get.snackbar("Success", "Subscription activated!", snackPosition: SnackPosition.TOP);
  //   } catch (e, st) {
  //     debugPrint("Payment success processing error: $e\n$st");
  //     // Close any loading dialog if open
  //     try {
  //       if (Get.isDialogOpen ?? false) Get.back();
  //     } catch (_) {}

  //     Get.snackbar("Error", "There was a problem processing the payment: $e");
  //   } finally {
  //     _processingPayment = false;
  //   }
  // }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
        "Razorpay payment error: ${response.code} - ${response.message}");
    Get.snackbar("Payment Failed", response.message ?? "Something went wrong");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("Razorpay external wallet: ${response.walletName}");
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
              onPageChanged: (index) {
                if (mounted) setState(() => _current = index);
              },
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
                    child: _buildCard(sub, isSubscribed),
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

  Widget _buildCard(Map sub, bool isSubscribed) {
    return Container(
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
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(color: Colors.black.withOpacity(0.25)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sub['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${sub['original_price']}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${sub['pieces']} pcs • ${sub['validity_days']} days",
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(223, 255, 255, 255)),
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
                backgroundColor: isSubscribed ? Colors.white70 : Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                elevation: 6,
              ),
              onPressed: isSubscribed
                  ? () {
                      Get.snackbar('Subscribed', 'Already Subscribed');
                    }
                  : () async {
                      try {
                        final alreadyHasSub =
                            await controller.hasAnyActiveSubscription();
                        if (alreadyHasSub) {
                          Get.snackbar("Not Allowed",
                              "You already have an active subscription.",
                              snackPosition: SnackPosition.TOP);
                          return;
                        }
                        _openCheckout(sub);
                      } catch (e) {
                        Get.snackbar(
                            "Error", "Could not start subscription: $e");
                      }
                    },
              child: Text(isSubscribed ? "Subscribed" : "Subscribe",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetail(
      BuildContext context, Map sub, bool isSubscribed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (sub['description'] != null)
                  Text(sub['description'],
                      style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 18),
                Row(children: [
                  Text("₹${sub['discounted_price']}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(width: 8),
                  Text("₹${sub['original_price']}",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                ]),
                const SizedBox(height: 10),
                Text("${sub['pieces']} pcs • ${sub['validity_days']} days",
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  onPressed: isSubscribed
                      ? null
                      : () async {
                          final alreadyHasSub =
                              await controller.hasAnyActiveSubscription();
                          if (alreadyHasSub) {
                            Get.snackbar("Not Allowed",
                                "You already have an active subscription.",
                                snackPosition: SnackPosition.TOP);
                            return;
                          }
                          _openCheckout(sub);
                        },
                  child: Text(isSubscribed ? "Subscribed" : "Subscribe"),
                ),
              ]),
        );
      },
    );
  }
}
