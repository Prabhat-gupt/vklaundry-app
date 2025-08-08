import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text('Track Order',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Order Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Order #123456',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Placed on Dec 15, 2024',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Quality Check',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Delivery',
                              style: TextStyle(color: Colors.grey)),
                          Text('Dec 18, 2024 · 2:00 PM',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Icon(Icons.local_shipping, color: Colors.blue),
                      SizedBox(width: 8),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Timeline Card
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
                children: _buildTimelineSteps(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineSteps() {
    final steps = [
      {
        'title': 'Order Confirmed',
        'date': 'Dec 15, 2024 · 10:30 AM',
        'desc': 'Your order has been confirmed and is being prepared.',
        'status': 'completed'
      },
      {
        'title': 'Picked Up',
        'date': 'Dec 15, 2024 · 3:45 PM',
        'desc': 'Items collected from your location successfully.',
        'status': 'completed'
      },
      {
        'title': 'In Process',
        'date': 'Dec 16, 2024 · 9:00 AM',
        'desc': 'Your items are being processed at our facility.',
        'status': 'current'
      },
      {
        'title': 'Quality Check',
        'date': 'Pending',
        'desc': 'Items will undergo quality inspection.',
        'status': 'pending'
      },
      {
        'title': 'Out for Delivery',
        'date': 'Pending',
        'desc': 'Items will be delivered to your location.',
        'status': 'pending'
      },
    ];

    return [
      FixedTimeline.tileBuilder(
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: steps.length,
          nodePositionBuilder: (context, index) => 0.1,
          indicatorPositionBuilder: (context, index) => 0,
          indicatorBuilder: (context, index) {
            final step = steps[index];
            if (step['status'] == 'completed') {
              return const DotIndicator(
                  size: 28,
                  color: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 18));
            } else if (step['status'] == 'current') {
              return const DotIndicator(
                size: 28,
                  color: Colors.blue,
                  child: Icon(Icons.radio_button_checked,
                      color: Colors.white, size: 18));
            } else {
              return const DotIndicator(
                size: 28,
                  color: Colors.grey,
                  child: Icon(Icons.radio_button_unchecked,
                      color: Colors.white, size: 18));
            }
          },
          connectorBuilder: (_, index, __) =>
              const SolidLineConnector(color: Colors.grey),
          contentsBuilder: (context, index) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.only(left: 18.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(step['date']!,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(step['desc']!,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }
}
