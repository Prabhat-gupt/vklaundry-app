import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  @override
  void initState() {
    super.initState();
    notificationController.fetchNotifications(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet!',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notif = notificationController.notifications[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              child: ListTile(
                title: Text(
                  notif['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(notif['message'] ?? ''),
                // trailing: notif['type'] != null
                //     ? Chip(
                //         label: Text(
                //           notif['type'].toString()?? '',
                //           style: const TextStyle(color: Colors.white),
                //         ),
                //         backgroundColor: Colors.blue,
                //       )
                //     : null,
              ),
            );
          },
        );
      }),
    );
  }
}
