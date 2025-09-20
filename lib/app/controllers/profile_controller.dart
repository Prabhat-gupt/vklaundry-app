// profile_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  // final ProductListController controller = Get.find<ProductListController>();

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
  int currentCount = 0;
  int? totalPreviousCount;

  Future<int?> validateAndUpdateSubscription(int userId) async {
    try {
      print("Validating subscription for user $userId with item count ");

      // 1. Get active subscription for user (status = 1)
      final userSub = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 1)
          .maybeSingle();

      totalPreviousCount = userSub?['count'];

      if (userSub == null) {
        // storages.write('subscriptionCheck', 0);

        // print(
        //   "getting my status is ::::::: ${storages.read('subscriptionCheck')}",
        // );
        // Get.snackbar(
        //   "No Subscription",
        //   "You do not have an active subscription.",
        // );
        return 0; // no subscription
      }

      final subscriptionId = userSub['subscription_id'];
      final endDateStr = userSub['end_date'];
      currentCount = userSub['count'] ?? 0;
      print("i am getting my status is ::::::: ${userSub['status']}");
      storages.write('subscriptionCheck', userSub['status']);
      storages.write('currentCount', currentCount);

      return userSub['status'] as int?;
    } catch (e) {
      print("Error validating/updating subscription: $e");
      Get.snackbar("Error", "Could not validate subscription.");
      return null;
    }
  }

  Future<int?> UpdateSubscription(int userId, count, newitem) async {
    try {
      print("Validating subscription for user $userId with item count ");

      // 1. Get active subscription for user (status = 1)
      final userSub = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 1)
          .maybeSingle();

      totalPreviousCount = userSub?['count'];

      if (userSub == null) {
        // storages.write('subscriptionCheck', 0);

        // print(
        //   "getting my status is ::::::: ${storages.read('subscriptionCheck')}",
        // );
        // Get.snackbar(
        //   "No Subscription",
        //   "You do not have an active subscription.",
        // );
        return 0; // no subscription
      }

      final subscriptionId = userSub['subscription_id'];
      final endDateStr = userSub['end_date'];
      // currentCount = userSub['count'] ?? 0;
      print("i am getting my status is ::::::: ${userSub['status']}");
      // storages.write('subscriptionCheck', userSub['status']);
      // storages.write('currentCount', currentCount);

      // 2. Get subscription details
      final subDetails = await supabase
          .from('subscriptions')
          .select('pieces')
          .eq('id', subscriptionId)
          .maybeSingle();

      if (subDetails == null) {
        // Get.snackbar("Error", "Subscription details not found.");
        return 0;
      }

      // final maxPieces = subDetails['pieces'] ?? 0;

      // 3. Check date and count
      final endDate = DateTime.parse(endDateStr);
      final today = DateTime.now();

      currentCount = (userSub['count'] ?? 0) as int;
      final int newItem = (newitem ?? 0) as int;
      final int maxPieces = (subDetails['pieces'] ?? 0) as int;

      print(
        "Debug => today: $today, endDate: $endDate, currentCount: $currentCount, newitem: $newitem, maxPieces: $maxPieces",
      );

      if (today.isAfter(endDate) || (currentCount + newItem) >= maxPieces) {
        print(
          "Blocking order: count=$currentCount, new=$newItem, max=$maxPieces",
        );

        final updateResponse = await supabase
            .from('user_subscriptions')
            .update({'status': 0, "count": 0})
            .eq('id', userSub['id'])
            .select();

        print("Update response: $updateResponse");

        final updatedSub = await supabase
            .from('user_subscriptions')
            .select('status')
            .eq('id', userSub['id'])
            .maybeSingle();

        return updatedSub?['status'] as int?;
      }

      // if (today.isAfter(endDate) || (currentCount + newitem) == maxPieces) {
      //   // Expired OR limit exceeded → set status = 0
      //   await supabase
      //       .from('user_subscriptions')
      //       .update({'status': 0, "count": 0})
      //       .eq('id', userSub['id']);

      //   final updatedSub = await supabase
      //       .from('user_subscriptions')
      //       .select('status')
      //       .eq('id', userSub['id'])
      //       .maybeSingle();

      //   return updatedSub?['status'] as int?;
      // }

      // 4. Update count
      final newCount = currentCount + newitem;
      print("my new count is displaying ::::::: $newitem");
      await supabase
          .from('user_subscriptions')
          .update({'count': newCount})
          .eq('id', userSub['id']);

      final updatedSub = await supabase
          .from('user_subscriptions')
          .select('status')
          .eq('id', userSub['id'])
          .maybeSingle();

      return updatedSub?['status'] as int?;
    } catch (e) {
      print("Error validating/updating subscription: $e");
      Get.snackbar("Error", "Could not validate subscription.");
      return null;
    }
  }

  // get the addres details
  Future<bool> checkUserPincode(int userId) async {
    try {
      final result = await supabase
          .from('addresses')
          .select('landmark_pincode')
          .eq('id', userId)
          .maybeSingle();

      print("my result is ::::::: $result");

      if (result == null) {
        print("No address found for user $userId");
        return false;
      }

      final landmarkPincode = result['landmark_pincode'] ?? '';
      print("my lanfmarkpincode is :::::::: $landmarkPincode");
      if (landmarkPincode.toString().trim().isEmpty) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      print("Error fetching pincode: $e");
      return false;
    }
  }

  // update the data in the table transaction
  updateAmountTransactionTable(amount, transactionId) async {
    try {
      final subscriptionData = {
        'user_id': "${storages.read('userId')}",
        'payment_method': 0,
        'amount': amount,
        'transaction_id': transactionId,
        'created_at': DateTime.now().toIso8601String(),
        "order_id": "0",
        "status": 0,
      };

      // Insert subscription into Supabase
      await supabase.from('transactions').insert(subscriptionData).select();

      debugPrint("Subscription saved successfully:");
    } catch (e, st) {
      debugPrint("Payment Success Handling Error: $e\n$st");
      Get.snackbar(
        "Error",
        "Something went wrong while subscribing",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
