import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderController extends GetxController {
  final supabase = Supabase.instance.client;

  Future<int?> placeOrder({
    required List<Map<String, dynamic>> selectedItems,
    required double totalAmount,
    required String paymentMethod,
    required String paymentStatus,
    required int userId,
    required int addressId,
    required String deliveryDateTime,
    required String pickupDateTime
  }) async {
    print("Selected items: $selectedItems");

    try {
      // Step 1: Insert into 'orders' table
      final orderResponse = await supabase
          .from('orders')
          .insert({
            'status': 0, // Assuming 1 = pending
            'amount': totalAmount,
            'payment_method': 1,
            'payment_status': 1,
            'pickup_datetime': pickupDateTime,
            'delivery_datetime': deliveryDateTime,
            'user_id': userId,
            'address_id': addressId,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Step 2: Prepare 'order_items' data
      final List<Map<String, dynamic>> orderItems = selectedItems.map((item) {
        return {
          'order_id': orderId,
          'item_id': item['product']['id'],
          'service_id': item['service'],
          'quantity': item['quantity'],
          'price': item['product']['price'],
          'amount': item['quantity'] * item['product']['price'],
        };
      }).toList();

      // Step 3: Insert into 'order_items' table
      await supabase.from('order_items').insert(orderItems);

      await supabase.from('notifications').insert({
        'type': 4,
        'title': 'Order Placed',
        'message': 'Your order has been placed successfully. Order ID: $orderId',
        'user_id': userId,
      });
      print('Order placed successfully');
      return orderId; // Return order ID on success
    } catch (e) {
      print('Error placing order: $e');
      return null; // Return null on error
    }
  }
}
