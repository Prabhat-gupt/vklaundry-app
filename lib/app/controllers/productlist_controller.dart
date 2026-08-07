import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:laundry_app/app/controllers/profile_controller.dart';

class ProductListController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var products = <Map<String, dynamic>>[].obs; // current service products
  var filteredProducts = <Map<String, dynamic>>[].obs;
  var currentService = ''.obs;
  var selectedCategoryId = RxnInt();

  // Cart Data
  var cartQuantities = <String, int>{}.obs; // key = "service_productId"
  var cartProductDetails =
      <String, Map<String, dynamic>>{}.obs; // full product details

  // Categories & Services
  var categories = <Map<String, dynamic>>[].obs;
  var serviceNamesCache = <String, String>{}.obs; // Cache service names
  var isGuestMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkGuestMode();
    loadCategoriesFromSupabase();
    preloadServiceNames();
    fetchActiveOffer();
    _loadCartFromStorage();
  }

  void setService(String service) {
    currentService.value = service;
  }

  Future<void> checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isGuest = prefs.getBool('isGuest') ?? false;
    isGuestMode.value = !isLoggedIn || isGuest;
  }

  RxList activeOffer = [].obs;

  var activeOfferselected = <String, dynamic>{}.obs;
  Future<void> fetchActiveOffer() async {
    final response = await Supabase.instance.client
        .from('offers')
        .select()
        .eq('active', true);

    print("Fetched active offers: $response");

    if (response != null) {
      bool isFirstApply = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        if (userId != null) {
          final userRes = await Supabase.instance.client
              .from('users')
              .select('is_firstApply')
              .eq('id', userId)
              .maybeSingle();
          if (userRes != null) {
            isFirstApply = userRes['is_firstApply'] ?? false;
          }
        }
      } catch (e) {
        print("Error fetching user for offer filter: $e");
      }

      var validOffers = (response as List).where((offer) {
        if (offer['type'] == 'first_order' && isFirstApply) {
          return false;
        }
        return true;
      }).toList();

      activeOffer.value = List<Map<String, dynamic>>.from(validOffers);
    }
  }

  Future<void> loadProductsFromSupabase(int serviceId) async {
    try {
      isLoading.value = true;

      final pricesResponse = await supabase
          .from('prices')
          .select('*, item_id')
          .eq('service_id', serviceId);

      final List<Map<String, dynamic>> prices = List<Map<String, dynamic>>.from(
        pricesResponse,
      );

      if (prices.isEmpty) {
        products.value = [];
        filteredProducts.value = [];
        return;
      }

      final itemIds = prices.map((e) => e['item_id']).toSet().toList();

      final itemsResponse = await supabase
          .from('items')
          .select('*')
          .inFilter('id', itemIds)
          .order('sort_order', ascending: true);

      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        itemsResponse,
      );

      final enrichedProducts = items.map((item) {
        final itemId = item['id'];
        final priceData = prices.firstWhere(
          (p) => p['item_id'] == itemId,
          orElse: () => {},
        );
        final price = priceData['price'] ?? 0;
        final rawOldPrice = priceData['old_price'];
        
        // Add 20% to the actual price if old_price is 0 or null
        final oldPrice = (rawOldPrice == null || rawOldPrice == 0)
            ? (price * 1.2).toInt()
            : rawOldPrice;

        return {
          'id': itemId,
          'name': item['name'],
          'image': item['image_url'] ??
              'https://eu-images.contentstack.com/v3/assets/blte6b9e99033a702bd/blt7e5c15dd5c6fb1a3/67cacb6c91d4b6c9af49e7e3/Top_Shape_1.jpg?width=954&height=637&format=jpg&quality=80',
          'price': price,
          'oldPrice': oldPrice,
          'discount': priceData['discount'] ?? '',
          'rating': item['rating'] ?? 0.0,
          'reviews': item['reviews'] ?? 0,
          'category_id': item['category_id'],
          'service_id': serviceId,
        };
      }).toList();

      // ✅ Replace instead of append to avoid duplicates
      products.value = enrichedProducts;
      filteredProducts.value = enrichedProducts;
    } catch (e) {
      print('Error loading products for service $serviceId: $e');
      products.value = [];
      filteredProducts.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  var currentSort = 'none'.obs; // 'none', 'lowToHigh', 'highToLow'
  var searchQuery = ''.obs;

  void sortProducts(String sortOrder) {
    currentSort.value = sortOrder;
    filterProductsByCategory(selectedCategoryId.value, int.tryParse(currentService.value));
  }

  void searchProducts(String query) {
    searchQuery.value = query.toLowerCase();
    filterProductsByCategory(selectedCategoryId.value, int.tryParse(currentService.value));
  }

  void filterProductsByCategory(int? categoryId, int? serviceId) {
    selectedCategoryId.value = categoryId;
    final originalList = List<Map<String, dynamic>>.from(products);
    
    var filtered = originalList.where((product) {
      final matchesCategory = categoryId == null ||
          (product['category_id'] == categoryId &&
              (serviceId == null || product['service_id'] == serviceId));
      
      final matchesSearch = searchQuery.value.isEmpty ||
          (product['name']?.toString().toLowerCase().contains(searchQuery.value) ?? false);
          
      return matchesCategory && matchesSearch;
    }).toList();
            
    if (currentSort.value == 'lowToHigh') {
      filtered.sort((a, b) => (a['price'] as num? ?? 0).compareTo(b['price'] as num? ?? 0));
    } else if (currentSort.value == 'highToLow') {
      filtered.sort((a, b) => (b['price'] as num? ?? 0).compareTo(a['price'] as num? ?? 0));
    }
    
    filteredProducts.value = filtered;
  }

  /// Add [quantity] of [product] to cart. Default is 1.
  /// Merges with existing quantity so items are not duplicated.
  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    if (quantity <= 0) return;
    if (isGuestMode.value) {
      _showLoginPopup();
      return;
    }

    final service = product['service_id'].toString();
    final productId = product['id'];
    final key = '${service}_$productId';

    cartQuantities[key] = (cartQuantities[key] ?? 0) + quantity;

    // Store full product details so cart works after service switch
    cartProductDetails[key] = product;
    _saveCartToStorage();
  }

  /// Convenience for bulk add (kept for compatibility)
  void addBulkToCart(Map<String, dynamic> product, int quantity) {
    addToCart(product, quantity: quantity);
  }

  void removeFromCart(Map<String, dynamic> product) {
    final service = product['service_id'].toString();
    final productId = product['id'];
    final key = '${service}_$productId';

    if (cartQuantities[key] != null && cartQuantities[key]! > 0) {
      cartQuantities[key] = cartQuantities[key]! - 1;

      if (cartQuantities[key] == 0) {
        cartQuantities.remove(key);
        cartProductDetails.remove(key); // remove details too
      }
      _saveCartToStorage();
    }
  }

  List<Map<String, dynamic>> getSelectedCartItems() {
    final List<Map<String, dynamic>> items = [];

    cartQuantities.forEach((key, quantity) {
      final product = cartProductDetails[key];
      if (product != null) {
        final service = product['service_id'].toString();
        final serviceName = serviceNamesCache[service] ?? 'Loading...';
        items.add({
          'product': product,
          'quantity': quantity,
          'service': service,
          'service_name': serviceName,
        });
      }
    });

    return items;
  }

  Future<void> preloadServiceNames() async {
    try {
      final response = await supabase.from('services').select('id, name').order('sort_order', ascending: true);
      for (final row in response) {
        serviceNamesCache[row['id'].toString()] = row['name'] ?? 'Unknown';
      }
    } catch (e) {
      print('Error preloading service names: $e');
    }
  }

  int getTotalCartItems() => cartQuantities.values.fold(0, (a, b) => a + b);

  Future<void> loadCategoriesFromSupabase() async {
    try {
      final response =
          await supabase.from('categories').select('id, name, image_url');
      categories.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading categories: $e');
      categories.value = [];
    }
  }

  void incrementQuantity(int productId, int serviceId) {
    if (isGuestMode.value) {
      _showLoginPopup();
      return;
    }
    final key = '${serviceId}_$productId';
    if (cartQuantities.containsKey(key)) {
      cartQuantities[key] = (cartQuantities[key] ?? 1) + 1;
      _saveCartToStorage();
    }
  }

  void decrementQuantity(int productId, int serviceId) {
    final key = '${serviceId}_$productId';
    if (cartQuantities.containsKey(key) && cartQuantities[key]! > 1) {
      cartQuantities[key] = cartQuantities[key]! - 1;
      _saveCartToStorage();
    }
  }

  // Cart persistence methods
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save cart quantities
      final quantitiesJson = jsonEncode(cartQuantities);
      await prefs.setString('cart_quantities', quantitiesJson);

      // Save cart product details
      final detailsJson = jsonEncode(cartProductDetails);
      await prefs.setString('cart_product_details', detailsJson);
    } catch (e) {
      print('Error saving cart to storage: $e');
    }
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cart quantities
      final quantitiesJson = prefs.getString('cart_quantities');
      if (quantitiesJson != null) {
        final decoded = jsonDecode(quantitiesJson) as Map<String, dynamic>;
        cartQuantities.value =
            decoded.map((key, value) => MapEntry(key, value as int));
      }

      // Load cart product details
      final detailsJson = prefs.getString('cart_product_details');
      if (detailsJson != null) {
        final decoded = jsonDecode(detailsJson) as Map<String, dynamic>;
        cartProductDetails.value = decoded
            .map((key, value) => MapEntry(key, value as Map<String, dynamic>));
      }
    } catch (e) {
      print('Error loading cart from storage: $e');
    }
  }

  Future<void> clearCart() async {
    cartQuantities.clear();
    cartProductDetails.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_quantities');
    await prefs.remove('cart_product_details');
  }

  void _showLoginPopup() {
    Get.defaultDialog(
      title: "Login Required",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: "You need to log in to add items to your cart. Would you like to log in now?",
      textConfirm: "Login",
      textCancel: "Cancel",
      confirmTextColor: const Color(0xFFFFFFFF),
      buttonColor: const Color(0xFF5768AB),
      onConfirm: () {
        Get.back(); // close dialog
        Get.toNamed('/login');
      },
    );
  }
}

extension ProductListControllerExtensions on ProductListController {
  double calculateItemsTotal() {
    final selectedItems = getSelectedCartItems();
    double total = 0.0;
    for (var item in selectedItems) {
      final quantity = item['quantity'] ?? 1;
      final price = (item['product']['price'] ?? 0).toDouble();
      total += quantity * price;
    }
    return total;
  }
}
