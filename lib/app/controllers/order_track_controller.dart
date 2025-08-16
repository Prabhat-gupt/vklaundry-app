import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackOrderController extends GetxController {
  final isLoading = true.obs;
  final order = {}.obs;
  final serviceNames = <int, String>{}.obs;

  final supabase = Supabase.instance.client;
  RealtimeChannel? _orderChannel;

  @override
  void onInit() {
    super.onInit();
    fetchAllServices();
  }

  @override
  void onClose() {
    unsubscribeFromOrderChanges();
    super.onClose();
  }

  Future<void> fetchAllServices() async {
    try {
      print("Supabase service, start");
      final servicesResponse =
          await supabase.from('services').select('id, name');

      for (var service in servicesResponse) {
        serviceNames[service['id']] = service['name'] ?? '';
      }
      print("Supabase service, $servicesResponse");
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

 Future<void> fetchOrderDetails(int userID) async {
  try {
    isLoading.value = true;

    final response = await supabase
        .from('orders')
        .select('*, order_items(*, product:item_id(*))')
        .eq('user_id', userID);

    if (response == null || response.isEmpty) {
      throw Exception("No orders found for this user");
    }

    print("Service name list , $serviceNames");

    final processedOrders = response.map((orderData) {
      final statusCode = orderData['status'] as int?;
      orderData['status_text'] = _getStatusText(statusCode);

      // Ensure order_items exists
      if (orderData['order_items'] != null) {
        orderData['order_items'] = (orderData['order_items'] as List).map((item) {
          final serviceId = item['service_id'] as int?;
          return {
            ...item,
            'service_name': serviceId != null ? (serviceNames[serviceId] ?? '') : ''
          };
        }).toList();
      }

      orderData['items'] = orderData['order_items'] ?? [];
      return orderData;
    }).toList();

    order.value = {"orders": processedOrders};
    print("Order value, $order");
  } catch (e) {
    print("Error fetching orders: $e");
  } finally {
    isLoading.value = false;
  }
}

 
 void subscribeToOrderChanges(int orderId) {
    _orderChannel = supabase.channel('order_updates_$orderId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) {
          print("Order updated: ${payload.toString()}");
          fetchOrderDetails(orderId);
        },
      )
      ..subscribe();
  }

  void unsubscribeFromOrderChanges() {
    if (_orderChannel != null) {
      supabase.removeChannel(_orderChannel!);
      _orderChannel = null;
    }
  }

  String _getStatusText(int? statusCode) {
    switch (statusCode) {
      case 0:
        return 'Pending';
      case 1:
        return 'Accepted';
      case 2:
        return 'Rejected';
      case 3:
        return 'Processing';
      case 4:
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}
