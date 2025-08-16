import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends GetxController {
  var notifications = [].obs;
  var isLoading = false.obs;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> fetchNotifications(int userId) async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', 1)
          .order('id', ascending: false);

      notifications.value = response;
    } catch (e) {
      print('Error fetching notifications: $e');
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
