import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackOrderController extends GetxController {
  final int orderId;
  TrackOrderController({required this.orderId});

  final isLoading = true.obs;
  final order = {}.obs;

  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('orders')
          .select(
              '*, order_items(*, product:item_id(*))') // aliasing item_id to product
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) {
        throw Exception("Order not found");
      }

      final statusCode = response['status'];
      response['status_text'] = _getStatusText(statusCode);

      response['items'] = response['order_items'] ?? [];
      print("Response from the order track: $response");
      order.value = response;
    } catch (e) {
      print("Error fetching order: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String _getStatusText(int? statusCode) {
    switch (statusCode) {
      case 1:
        return 'Pending';
      case 2:
        return 'Accepted';
      case 3:
        return 'Processing';
      case 4:
        return 'Delivered';
      default:
        return 'Pending';
    }
  }
}
