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
      final servicesResponse = await supabase
          .from('services')
          .select('id, name');

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

      // Make sure services are loaded
      if (serviceNames.isEmpty) {
        await fetchAllServices();
      }

      final response = await supabase
          .from('orders')
          .select('*, order_items(*, product:item_id(*))')
          .eq('user_id', userID);

      if (response == null || response.isEmpty) {
        throw Exception("No orders found for this user");
      }

      final processedOrders = response.map((orderData) {
        final statusCode = orderData['status'] as int?;
        orderData['status_text'] = _getStatusText(statusCode);

        if (orderData['order_items'] != null) {
          orderData['order_items'] = (orderData['order_items'] as List).map((
            item,
          ) {
            final serviceId = item['service_id'] as int?;
            return {
              ...item,
              'service_name': serviceId != null
                  ? (serviceNames[serviceId] ?? '')
                  : '',
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
        callback: (payload) async {
          print("Order updated: $payload");

          // Fetch only this order by ID
          final response = await supabase
              .from('orders')
              .select('*, order_items(*, product:item_id(*))')
              .eq('id', orderId)
              .single();

          if (response != null) {
            final updatedOrder = _processOrder(response);

            final ordersList = order.value['orders'] as List<dynamic>? ?? [];
            final index = ordersList.indexWhere((o) => o['id'] == orderId);

            if (index != -1) {
              ordersList[index] = updatedOrder; // Update the order
            } else {
              ordersList.add(updatedOrder); // Or add if missing
            }

            order.value = {"orders": ordersList}; // Trigger UI update
          }
        },
      )
      ..subscribe();
  }

  Map<String, dynamic> _processOrder(Map<String, dynamic> orderData) {
    final statusCode = orderData['status'] as int?;
    orderData['status_text'] = _getStatusText(statusCode);

    if (orderData['order_items'] != null) {
      orderData['order_items'] = (orderData['order_items'] as List).map((item) {
        final serviceId = item['service_id'] as int?;
        return {
          ...item,
          'service_name': serviceId != null
              ? (serviceNames[serviceId] ?? '')
              : '',
        };
      }).toList();
    }

    orderData['items'] = orderData['order_items'] ?? [];
    return orderData;
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
