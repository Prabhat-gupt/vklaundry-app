import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';

class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackOrderController(orderId: Get.arguments['order_id']));

    final List<String> statusSteps = [
      "Pending",
      "Accepted",
      "Processing",
      "Delivered",
    ];

    int getCurrentStep(String? status) {
      return status != null ? statusSteps.indexOf(status) : 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text("Track Order #${controller.order.value['id'] ?? ''}")),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: controller.order.stream, // Use the Rx stream for realtime updates
        builder: (context, snapshot) {
          if (!snapshot.hasData || controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderDetails = snapshot.data as Map<String, dynamic>;
          final currentStep = getCurrentStep(orderDetails['status_text']);
          final items = orderDetails['order_items'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Order ID:"),
                            Text("#${orderDetails['id'] ?? '-'}")
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Amount:"),
                            Text("₹${orderDetails['amount'] ?? 0}")
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Payment Status:"),
                            Text(orderDetails['payment_status'] == 1 ? "Paid" : "Unpaid")
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Placed On:"),
                            Text(orderDetails['created_at']?.toString().split('T').first ?? '-')
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Order Status Timeline
                const Text("Order Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Stepper(
                  physics: const NeverScrollableScrollPhysics(),
                  currentStep: currentStep,
                  controlsBuilder: (context, details) => const SizedBox(),
                  steps: statusSteps.map((step) {
                    int index = statusSteps.indexOf(step);
                    return Step(
                      title: Text(step),
                      content: const SizedBox.shrink(),
                      isActive: index <= currentStep,
                      state: index < currentStep
                          ? StepState.complete
                          : index == currentStep
                              ? StepState.editing
                              : StepState.indexed,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Ordered Items
                const Text("Ordered Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...items.map((item) {
                  final product = item['product'] ?? {};
                  final price = item['price'] ?? 0;
                  final quantity = item['quantity'] ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                        ),
                      ),
                      title: Text(product['name'] ?? 'Unknown Product'),
                      subtitle: Text("Quantity: $quantity"),
                      trailing: Text(
                        "₹${price * quantity}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
