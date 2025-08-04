// profile_controller.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var name = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var userId = ''.obs; // Store user ID (uuid from auth)
  var dbUserId = 0.obs; // Store user ID from 'users' table
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      final user = supabase.auth.currentUser;
      if (user != null) {
        userId.value = user.id;

        final response = await supabase
            .from('users')
            .select('*')
            .eq('uuid', user.id)
            .maybeSingle();
        print("Response from the user $response");
        if (response != null) {
          dbUserId.value = response['id'] ?? 0;
          name.value = response['name'] ?? '';
          email.value = response['email'] ?? '';
          phone.value = response['phone']?.toString() ?? '';
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
