import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackOrderController extends GetxController {
  final int orderId;
  TrackOrderController({required this.orderId});

  final isLoading = true.obs;
  final order = {}.obs;

  final supabase = Supabase.instance.client;
  RealtimeChannel? _orderChannel;

  @override
  void onInit() {
    super.onInit();
    fetchOrderDetails();
    _subscribeToOrderChanges();
  }

  @override
  void onClose() {
    _unsubscribeFromOrderChanges();
    super.onClose();
  }

  Future<void> fetchOrderDetails() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('orders')
          .select('*, order_items(*, product:item_id(*))')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) {
        throw Exception("Order not found");
      }

      final statusCode = response['status'];
      response['status_text'] = _getStatusText(statusCode);
      response['items'] = response['order_items'] ?? [];

      order.value = response;
    } catch (e) {
      print("Error fetching order: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToOrderChanges() {
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
          fetchOrderDetails();
        },
      )
      ..subscribe();
  }

  void _unsubscribeFromOrderChanges() {
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
