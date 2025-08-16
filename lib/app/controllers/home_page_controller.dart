// home_page_controller.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageController extends GetxController {
  final supabase = Supabase.instance.client;

  var userAddress = <Map<String, dynamic>>[].obs;
  var userLocationDetails = ''.obs;

  var services = [].obs;
  var specialItems = [].obs;
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
    // fetchSpecialItems();
  }

  Future<int> fetchUserDetails() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      final response = await supabase
          .from('users')
          .select('*')
          .eq('uuid', userId!)
          .single();
      print("User Details: $response");
      if (response != null && response['id'] != null) {
        return response['id'] as int;
      }
      throw Exception('User ID not found');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load address');
      throw Exception('Failed to load address');
    } finally {
      isLoading.value = false;
    }
  }

  void fetchServices() async {
    try {
      final response = await supabase.from('services').select('*');
      services.value = response;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load services');
    }
  }

  void fetchUserAddress() async {
    try {
      int userId = await fetchUserDetails();
      final response = await supabase.from('addresses').select('*').eq('id', userId).limit(1);
      userAddress.value = response;
      print(  "User Address: $userAddress");
    } catch (e) {
      Get.snackbar('Error', 'Failed to load services');
    }
  }

  // void fetchSpecialItems() async {
  //   try {
  //     final response = await supabase.from('specials').select('*');
  //     specialItems.value = response;
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load specials');
  //   }
  // }
}
