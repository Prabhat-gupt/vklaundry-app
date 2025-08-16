import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/ui/widgets/order_card.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {

  final orderTrackController = Get.find<TrackOrderController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("All Orders", style: TextStyle(fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 16.0),
        child: Obx(() {
          final ordersData = orderTrackController.order['orders'] ?? [];
          if (ordersData.isEmpty) {
            return const Text("No orders found");
          }
          return OrderCard(orders: List<Map<String, dynamic>>.from(orderTrackController.order['orders'] ?? []), numbersOrders: List<Map<String, dynamic>>.from(orderTrackController.order['orders'] ?? []).length,);
        }),
      ),
    );
  }
}