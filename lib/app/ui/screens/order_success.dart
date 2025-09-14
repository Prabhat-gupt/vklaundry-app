import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/routes/app_pages.dart'; // Make sure this import has your root route

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = Get.arguments['order_id'];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                "Order Placed Successfully!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Thank you for your order. We'll notify you when it is on the way.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed(AppRoutes.ROOT);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Continue Shopping",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // TextButton(
              //   onPressed: () {
              //     // Navigate to Order Details/Tracking
              //     Get.offNamed(AppRoutes.TRACKING, arguments: {'order_id': orderId}); // Replace with actual order ID
              //   },
              //   child: const Text("Track Order", style: TextStyle(color: Color(0xFF1B1C39))),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
