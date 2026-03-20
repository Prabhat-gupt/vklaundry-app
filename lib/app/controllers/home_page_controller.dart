import 'dart:math' show cos, sin, sqrt, asin, pi;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageController extends GetxController {
  final supabase = Supabase.instance.client;

  // Bottom nav index — any page can switch tabs by setting this
  var currentNavIndex = 0.obs;

  var userAddress = <Map<String, dynamic>>[].obs;
  var userLocationDetails = ''.obs;

  var services = [].obs;
  var specialItems = [].obs;
  var subscriptions = [].obs;
  var isLoading = false.obs;
  var isServiceAvailable = true.obs;
  var userDistanceFromCenter = 0.0.obs;

  // Service center coordinates
  static const double centerLatitude = 17.608400;
  static const double centerLongitude = 78.466200;
  static const double serviceRadiusKm = 10.0;

  // Cache userId to avoid repeated SharedPreferences calls
  int? _cachedUserId;

  // Public getter for cached userId
  int? get cachedUserId => _cachedUserId;

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
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;

      // Fetch user details first (sets _cachedUserId)
      await fetchUserDetails();

      // Then fetch other data using cached userId
      await Future.wait([
        Future(() => fetchServices()),
        Future(() => fetchUserAddress()),
        Future(() => fetchSubscriptions()),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  final RxMap<int, bool> subscribedStatus = <int, bool>{}.obs;

  Future<void> preloadSubscribedStatus(int userId) async {
    // Query user_subscriptions table for this user
    // Create a new map to trigger reactive update
    final Map<int, bool> newStatus = {};

    for (var sub in subscriptions) {
      final planId = sub['id'];
      newStatus[planId] = await isUserSubscribedTo(planId);
    }

    // Update the entire map to trigger reactive listeners
    subscribedStatus.value = newStatus;
    print("Preloaded subscribedStatus: $subscribedStatus");
  }

  /// ✅ Fetch User ID
  // Future<int> fetchUserDetails() async {
  //   try {
  //     isLoading.value = true;
  //     final userId = supabase.auth.currentUser?.id ?? storages.read('userId');
  //     print("myuserid is getting in homepage :::: ----- $userId");
  //     final response = await supabase
  //         .from('users')
  //         .select('*')
  //         .eq('uuid', userId!)
  //         .single();

  //     // print("response is printing homepage ::::::::: $response");
  //     if (response != null && response['id'] != null) {
  //       return response['id'] as int;
  //       // return storages.read('userId');
  //     }
  //     throw Exception('User ID not found');
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load user details');
  //     throw Exception('Failed to load user details');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<int> fetchUserDetails() async {
    try {
      // Return cached userId if available
      if (_cachedUserId != null) {
        return _cachedUserId!;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      print("my userId from SharedPreferences: $userId");
      if (userId == null) throw Exception('User not logged in');

      final response =
          await supabase.from('users').select('*').eq('id', userId).single();

      print("my userdetails: $response");

      if (response != null && response['id'] != null) {
        _cachedUserId = response['id'] as int;
        return _cachedUserId!;
      }

      throw Exception('User ID not found');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user details');
      throw Exception('Failed to load user details: $e');
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

  /// Calculate distance between two coordinates using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _checkServiceAvailability(double? userLat, double? userLon) {
    print(
        '🔍 Checking service availability - userLat: $userLat, userLon: $userLon');

    if (userLat == null || userLon == null) {
      print('⚠️ Missing coordinates - assuming service is available');
      isServiceAvailable.value = true; // Assume available if no coordinates
      return;
    }

    double distance =
        calculateDistance(centerLatitude, centerLongitude, userLat, userLon);

    userDistanceFromCenter.value = distance;

    print('📍 Distance from service center: ${distance.toStringAsFixed(2)} km');
    print('📍 Service radius: $serviceRadiusKm km');
    isServiceAvailable.value = distance <= serviceRadiusKm;

    if (!isServiceAvailable.value) {
      print(
          '⚠️ Service not available - user is ${distance.toStringAsFixed(2)} km away (max: $serviceRadiusKm km)');
    } else {
      print('✅ Service available - user is within service area');
    }
  }

  /// ✅ Fetch user address
  void fetchUserAddress() async {
    try {
      // Use cached userId if available, otherwise fetch
      int userId = _cachedUserId ?? await fetchUserDetails();

      final response = await supabase
          .from('addresses')
          .select('*')
          .eq('id', userId)
          .limit(1);
      userAddress.value = response;

      // Check service availability if coordinates exist
      if (response.isNotEmpty) {
        final address = response.first;
        print('🏠 Fetched address: $address');

        // Handle different numeric types from Supabase
        final latValue = address['latitude'];
        final lonValue = address['longitude'];

        print(
            '📍 Raw coordinates - lat: $latValue (${latValue.runtimeType}), lon: $lonValue (${lonValue.runtimeType})');

        final lat = latValue != null ? (latValue as num).toDouble() : null;
        final lon = lonValue != null ? (lonValue as num).toDouble() : null;

        if (lat != null && lon != null) {
          print('📍 Converted coordinates - lat: $lat, lon: $lon');
          _checkServiceAvailability(lat, lon);
        } else {
          print('⚠️ No coordinates found in address');
          isServiceAvailable.value = true; // Assume available if no coordinates
        }
      }
    } catch (e) {
      print('❌ Error fetching address: $e');
      Get.snackbar('Error', 'Failed to load address');
    }
  }

  Future<void> fetchSubscriptions() async {
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
  Future<bool> subscribeUser(Map<String, dynamic> sub) async {
    try {
      int userId = await fetchUserDetails();

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
        return true; // ✅ Subscription added successfully
      } else {
        return false; // ❌ Insert failed (no rows returned)
      }
    } catch (e, st) {
      print("Subscription Error: $e\n$st");
      return false;
    }
  }
}
