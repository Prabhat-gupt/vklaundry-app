import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderData = Get.arguments['order'];

    final statusText = orderData['status_text'] ?? "Pending";
    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case "pending":
          return Colors.grey;
        case "processing":
          return const Color.fromARGB(140, 255, 153, 0);
        case "completed":
          return Colors.green;
        case "cancelled":
          return Colors.red;
        default:
          return Colors.blue; // fallback color
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 5)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${orderData['id']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${DateFormat('yyyy-MM-dd : HH:mm').format(DateTime.parse(orderData['created_at']).toLocal())}',
                            style: const TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(statusText),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Delivery Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Delivery',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '${orderData['delivery_time']?.toString() ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping,
                            color: Colors.blue),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Timeline Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 5)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeline(orderData['status'] as int? ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(int currentStatus) {
    final steps = [
      {'title': 'Order Confirmed', 'desc': 'Order confirmed'},
      {'title': 'Picked Up', 'desc': 'Items collected from your location'},
      {'title': 'In Process', 'desc': 'Processing at facility'},
      // {'title': 'Quality Check', 'desc': 'Items undergoing inspection'},
      {'title': 'Out for Delivery', 'desc': 'En route to your address'},
    ];

    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        connectorTheme:
            const ConnectorThemeData(thickness: 2.5, color: Colors.grey),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        itemCount: steps.length,
        nodePositionBuilder: (context, index) => 0.05,
        indicatorPositionBuilder: (context, index) => 0.3,
        contentsBuilder: (context, index) {
          final isActive = index <= currentStatus;
          return Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[index]['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? Colors.blue : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index]['desc']!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
        indicatorBuilder: (context, index) {
          if (index < currentStatus) {
            return const DotIndicator(
              size: 24,
              color: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 16),
            );
          } else if (index == currentStatus) {
            return const DotIndicator(
              size: 26,
              color: Colors.blue,
              child: Icon(Icons.radio_button_checked,
                  color: Colors.white, size: 18),
            );
          } else {
            return const DotIndicator(
              size: 24,
              color: Colors.grey,
              child: Icon(Icons.radio_button_unchecked,
                  color: Colors.white, size: 16),
            );
          }
        },
        connectorBuilder: (context, index, connectorType) {
          if (index < currentStatus) {
            return const SolidLineConnector(color: Colors.green);
          } else {
            return const SolidLineConnector(color: Colors.grey);
          }
        },
      ),
    );
  }
}
