import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderController extends GetxController {
  final supabase = Supabase.instance.client;

  Future<void> placeOrder({
    required List<Map<String, dynamic>> selectedItems,
    required double totalAmount,
    required String paymentMethod,
    required String paymentStatus,
    required int userId,
    required int addressId,
  }) async {
    print("This is the selected services $selectedItems");
    try {
      // 1. Insert into orders table
      final orderResponse = await supabase.from('orders').insert({
        'status': 1,
        'amount': totalAmount,
        'payment_method': 1,
        'payment_status': 1,
        'user_id': userId,
        'address_id': addressId,
      }).select().single();

      final orderId = orderResponse['id'];

      // 2. Insert items into order_items
      final List<Map<String, dynamic>> orderItems = selectedItems.map((item) {
        return {
          'order_id': orderId,
          'item_id': item['product']['id'],
          'service_id': 5, // Ensure this key exists in your cart items
          'quantity': item['quantity'],
          'price': item['product']['price'],
          'amount': item['quantity'] * item['product']['price'],
        };
      }).toList();

      await supabase.from('order_items').insert(orderItems);

      print('Order placed successfully');
    } catch (e) {
      print('Error placing order: $e');
      rethrow;
    }
  }
}
