// home_page_controller.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageController extends GetxController {
  final supabase = Supabase.instance.client;

  var userAddress = ''.obs;
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
    // fetchUserAddress();
    fetchServices();
    // fetchSpecialItems();
  }

  // void fetchUserAddress() async {
  //   try {
  //     isLoading.value = true;
  //     final userId = supabase.auth.currentUser?.id;
  //     final response = await supabase
  //         .from('profiles')
  //         .select('address, location')
  //         .eq('id', userId!)
  //         .single();

  //     userAddress.value = response['address'] ?? '';
  //     userLocationDetails.value = response['location'] ?? '';
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load address');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void fetchServices() async {
    try {
      final response = await supabase.from('services').select('*');
      services.value = response;
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
