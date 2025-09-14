// profile_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  var storages = GetStorage();

  var name = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var userId = ''.obs; // Store user ID (uuid from auth)
  var dbUserId = 0.obs; // Store user ID from 'users' table
  var isLoading = false.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   fetchUserProfile();
  // }

  Future<void> fetchUserProfile(user) async {
    print("fsaifafoighsghshhd $user");
    try {
      isLoading.value = true;
      // final user = supabase.auth.currentUser;
      // dynamic user = storages.read('userId');
      // print("my profile userid is :::::: $userId");
      if (user != null) {
        // userId.value = user.id;
        // userId.value = user.toString();

        final response = await supabase
            .from('users')
            .select('*')
            .eq('id', user)
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

  Future<void> updateProfile(
    String newName,
    String newEmail,
    int newNumber,
  ) async {
    print("my dbuservcaielues is :::::: ${dbUserId.value}");
    try {
      isLoading.value = true;
      // final user = supabase.auth.currentUser;
      // if (user != null && dbUserId.value > 0) {
      if (storages.read('userId') != null && dbUserId.value > 0) {
        await supabase
            .from('users')
            .update({'name': newName, 'email': newEmail, 'phone': newNumber})
            .eq('id', dbUserId.value);

        name.value = newName;
        email.value = newEmail;
        phone.value = newNumber.toString();
      }
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar('Error', 'Failed to update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Future<bool> hasActiveSubscription(int userId) async {
  //   try {
  //     final response = await supabase
  //         .from('user_subscriptions')
  //         .select()
  //         .eq('user_id', userId)
  //         .eq('status', 1); // 1 = active

  //     print("Active subscriptions for user $userId: $response");

  //     return response.isNotEmpty; // true if any active subscription exists
  //   } catch (e) {
  //     print("Error checking active subscriptions: $e");
  //     return false;
  //   }
  // }
  Future<int> validateAndUpdateSubscription(int userId, int itemsCount) async {
    try {
      print(
        "Validating subscription for user $userId with item count $itemsCount",
      );
      // 1. Get active subscription for user
      final userSub = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 1)
          .maybeSingle();

      if (userSub == null) {
        Get.snackbar(
          "No Subscription",
          "You do not have an active subscription.",
        );
        return 0;
      }

      final subscriptionId = userSub['subscription_id'];
      final endDateStr = userSub['end_date'];
      final currentCount = userSub['count'] ?? 0;

      // 2. Get subscription details
      final subDetails = await supabase
          .from('subscriptions')
          .select('pieces')
          .eq('id', subscriptionId)
          .maybeSingle();

      if (subDetails == null) {
        Get.snackbar("Error", "Subscription details not found.");
        return 0;
      }

      final maxPieces = subDetails['pieces'] ?? 0;

      // 3. Check date and count
      final endDate = DateTime.parse(endDateStr);
      final today = DateTime.now();

      if (today.isAfter(endDate)) {
        Get.snackbar("Subscription Ended", "Your subscription has expired.");
        return 0;
      }

      if ((currentCount + itemsCount) > maxPieces) {
        Get.snackbar(
          "Limit Exceeded",
          "You have exceeded your subscription limit.",
        );
        return 2;
      }

      // 4. Update count
      final newCount = currentCount + itemsCount;
      await supabase
          .from('user_subscriptions')
          .update({'count': newCount})
          .eq('id', userSub['id']);

      return 1;
    } catch (e) {
      print("Error validating/updating subscription: $e");
      Get.snackbar("Error", "Could not validate subscription.");
      return 0;
    }
  }
}
