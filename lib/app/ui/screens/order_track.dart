import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

/// 🔹 Status mapping (reused)
const ORDER_STATUS = {
  'PENDING': 0,
  'ACCEPTED': 1,
  'PROCESSING': 2,
  'COMPLETED': 3,
  'REJECTED': 4,
};

class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderData = Get.arguments['order'];

    final int status = orderData['status'] ?? 0;
    final statusText = _getStatusText(status);

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Order Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderData['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${DateFormat('yyyy-MM-dd : HH:mm').format(DateTime.parse(orderData['created_at']).toLocal())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                          const Text(
                            'Estimated Delivery',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            orderData['delivery_datetime'] ?? 'N/A',
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
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Timeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
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
                  _buildTimeline(status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Status Text
String _getStatusText(int status) {
  switch (status) {
    case 0:
      return "Pending";
    case 1:
      return "Accepted";
    case 2:
      return "Processing";
    case 3:
      return "Completed";
    case 4:
      return "Rejected";
    default:
      return "Unknown";
  }
}

/// 🔹 Status Color
Color _getStatusColor(int status) {
  switch (status) {
    case 0:
      return Colors.grey;
    case 1:
      return Colors.orange;
    case 2:
      return Colors.blue;
    case 3:
      return Colors.green;
    case 4:
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

Widget _buildTimeline(int currentStatus) {
  final steps = [
    {'title': 'Pending', 'desc': 'Waiting for confirmation'},
    {'title': 'Accepted', 'desc': 'Order accepted'},
    {'title': 'Processing', 'desc': 'Being processed'},
    {'title': 'Completed', 'desc': 'Order delivered'},
  ];

  if (currentStatus == 4) {
    steps[3] = {'title': 'Rejected', 'desc': 'Order cancelled'};
  }

  return FixedTimeline.tileBuilder(
    theme: TimelineThemeData(
      connectorTheme: const ConnectorThemeData(
        thickness: 2.5,
        color: Colors.grey,
      ),
    ),
    builder: TimelineTileBuilder.connected(
      connectionDirection: ConnectionDirection.before,
      itemCount: steps.length,
      nodePositionBuilder: (context, index) => 0.1,
      indicatorPositionBuilder: (context, index) => 0.1,
      contentsBuilder: (context, index) {
        final isActive =
            (currentStatus != 4 && index <= currentStatus) ||
            (currentStatus == 4 && index == 3);

        return Padding(
          padding: const EdgeInsets.only(left: 24.0, bottom: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                steps[index]['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive
                      ? (currentStatus == 4 && index == 3
                            ? Colors.red
                            : Colors.blue)
                      : Colors.black87,
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
        final isCompleted = currentStatus == 3;
        final isRejected = currentStatus == 4;

        if (isRejected) {
          if (index == 3) {
            return const DotIndicator(
              size: 24,
              color: Colors.red,
              child: Icon(Icons.close, color: Colors.white, size: 18),
            );
          } else {
            return const DotIndicator(
              size: 24,
              color: Colors.grey,
              child: Icon(
                Icons.radio_button_unchecked,
                color: Colors.white,
                size: 16,
              ),
            );
          }
        }

        if (index < currentStatus) {
          return const DotIndicator(
            size: 24,
            color: Colors.green,
            child: Icon(Icons.check, color: Colors.white, size: 16),
          );
        } else if (index == currentStatus) {
          if (isCompleted) {
            return const DotIndicator(
              size: 24,
              color: Colors.green,
              child: Icon(Icons.check_circle, color: Colors.white, size: 18),
            );
          } else {
            return const DotIndicator(
              size: 24,
              color: Colors.blue,
              child: Icon(
                Icons.radio_button_checked,
                color: Colors.white,
                size: 18,
              ),
            );
          }
        } else {
          return const DotIndicator(
            size: 24,
            color: Colors.grey,
            child: Icon(
              Icons.radio_button_unchecked,
              color: Colors.white,
              size: 16,
            ),
          );
        }
      },
      connectorBuilder: (context, index, connectorType) {
        if (currentStatus == 4) {
          return const SolidLineConnector(color: Colors.grey);
        } else if (index < currentStatus) {
          return const SolidLineConnector(color: Colors.green);
        } else {
          return const SolidLineConnector(color: Colors.grey);
        }
      },
    ),
  );
}
