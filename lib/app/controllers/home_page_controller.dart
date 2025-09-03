import 'dart:ui';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageController extends GetxController {
  final supabase = Supabase.instance.client;

  var userAddress = <Map<String, dynamic>>[].obs;
  var userLocationDetails = ''.obs;

  var services = [].obs;
  var specialItems = [].obs;
  var subscriptions = [].obs;
  var isLoading = false.obs;

  // Static list of icons mapped to index
  final List<String> serviceIcons = [
    'assets/icons/dry_wash.png',
    'assets/icons/steam_iron.png',
    'assets/icons/wash.png',
    'assets/icons/home_iron.png',
    'assets/icons/wash_fold.png',
    'assets/icons/others.png',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchUserDetails();
    fetchServices();
    fetchUserAddress();
    fetchSubscriptions();
  }

  final RxMap<int, bool> subscribedStatus = <int, bool>{}.obs;

  Future<void> preloadSubscribedStatus(int userId) async {
    // Query user_subscriptions table for this user
    // For each plan, set true/false in subscribedStatus
    for (var sub in subscriptions) {
      final planId = sub['id'];
      subscribedStatus[planId] = await isUserSubscribedTo(planId);
    }
    print("Preloaded subscribedStatus: $subscribedStatus");
  }

  /// ✅ Fetch User ID
  Future<int> fetchUserDetails() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      final response =
          await supabase.from('users').select('*').eq('uuid', userId!).single();
      if (response != null && response['id'] != null) {
        return response['id'] as int;
      }
      throw Exception('User ID not found');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user details');
      throw Exception('Failed to load user details');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Fetch services
  void fetchServices() async {
    try {
      final response = await supabase.from('services').select('*');
      services.value = response;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load services');
    }
  }

  /// ✅ Fetch user address
  void fetchUserAddress() async {
    try {
      int userId = await fetchUserDetails();
      final response = await supabase
          .from('addresses')
          .select('*')
          .eq('id', userId)
          .limit(1);
      userAddress.value = response;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load address');
    }
  }

  /// ✅ Fetch active subscriptions
  void fetchSubscriptions() async {
    try {
      final response =
          await supabase.from('subscriptions').select('*').eq('active', true);
      subscriptions.value = response;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load subscriptions');
    }
  }

  Future<bool> isUserSubscribedTo(int planId) async {
    try {
      int userId = await fetchUserDetails();

      // Fetch from "user_subscriptions" instead of local subscriptions list
      final response = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('subscription_id', planId)
          .eq('status', 1)
          .single(); // will return null if no record exists

      print("User Subscription Response: $response");

      return response != null; // true if subscription exists
    } catch (e) {
      print("Error checking subscription: $e");
      return false;
    }
  }

  /// ✅ Check if user already has any active subscription
  Future<bool> hasAnyActiveSubscription() async {
    try {
      int userId = await fetchUserDetails();

      final response = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 1); // 1 = active

      print("Active subscriptions for user $userId: $response");

      return response.isNotEmpty; // true if any active subscription exists
    } catch (e) {
      print("Error checking active subscriptions: $e");
      return false;
    }
  }

  // Future<bool> hasAnyActiveSubscription(int userId) async {
  //   bool temp = subscriptions.any((sub) => sub['user_id'] == userId);
  //   print("Checking any active subscription for user $userId: $temp");
  //   return subscriptions.any((sub) => sub['id'] == userId);
  // }

  /// ✅ Subscribe User after payment
  Future<void> subscribeUser(Map<String, dynamic> sub) async {
    try {
      int userId = await fetchUserDetails();

      // Example: subscription for 30 days
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30));

      final insertResponse = await supabase.from('user_subscriptions').insert({
        'user_id': userId,
        'subscription_id': sub['id'],
        'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate),
        'status': 1,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (insertResponse.isNotEmpty) {
        Get.snackbar(
          'Success',
          'You have subscribed to ${sub['name']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF59A892),
          colorText: const Color(0xFFFFFFFF),
        );
      }
    } catch (e) {
      print("Subscription Error: $e");
      Get.snackbar('Error', 'Subscription failed: $e');
    }
  }
}
