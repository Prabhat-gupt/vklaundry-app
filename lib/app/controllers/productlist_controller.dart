import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadCategoriesFromSupabase();
    preloadServiceNames();
    fetchActiveOffer();
  }

  void setService(String service) {
    currentService.value = service;
  }

  RxMap<String, dynamic> activeOffer = <String, dynamic>{}.obs;

  Future<void> fetchActiveOffer() async {
    final response = await Supabase.instance.client
        .from('offers')
        .select()
        .eq('active', true)
        .limit(1)
        .single();
    print("Fetched active offer: $response");
    if (response != null) {
      activeOffer.value = response;
    }
  }

  Future<void> loadProductsFromSupabase(int serviceId) async {
    try {
      isLoading.value = true;

      final pricesResponse = await supabase
          .from('prices')
          .select('*, item_id')
          .eq('service_id', serviceId);

      final List<Map<String, dynamic>> prices =
          List<Map<String, dynamic>>.from(pricesResponse);

      if (prices.isEmpty) {
        products.value = [];
        filteredProducts.value = [];
        return;
      }

      final itemIds = prices.map((e) => e['item_id']).toSet().toList();

      final itemsResponse =
          await supabase.from('items').select('*').inFilter('id', itemIds);

      final List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(itemsResponse);

      final enrichedProducts = items.map((item) {
        final itemId = item['id'];
        final priceData = prices.firstWhere(
          (p) => p['item_id'] == itemId,
          orElse: () => {},
        );
        return {
          'id': itemId,
          'name': item['name'],
          'image': item['image_url'] ??
              'https://eu-images.contentstack.com/v3/assets/blte6b9e99033a702bd/blt7e5c15dd5c6fb1a3/67cacb6c91d4b6c9af49e7e3/Top_Shape_1.jpg?width=954&height=637&format=jpg&quality=80',
          'price': priceData['price'] ?? 0,
          'oldPrice': priceData['old_price'] ?? 0,
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

  void filterProductsByCategory(int? categoryId, int? serviceId) {
    selectedCategoryId.value = categoryId;
    final originalList = List<Map<String, dynamic>>.from(products);
    filteredProducts.value = categoryId == null
        ? originalList
        : originalList
            .where((product) =>
                product['category_id'] == categoryId &&
                product['service_id'] == serviceId)
            .toList();
  }

  void addToCart(Map<String, dynamic> product) {
    final service = product['service_id'].toString();
    final productId = product['id'];
    final key = '${service}_$productId';

    cartQuantities[key] = (cartQuantities[key] ?? 0) + 1;

    // ✅ Store full product details so cart works after service switch
    cartProductDetails[key] = product;
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
          'service_name': serviceName
        });
      }
    });

    return items;
  }

  Future<void> preloadServiceNames() async {
    try {
      final response = await supabase.from('services').select('id, name');
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
      final response = await supabase.from('categories').select('id, name');
      categories.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading categories: $e');
      categories.value = [];
    }
  }

  void incrementQuantity(int productId, int serviceId) {
    final key = '${serviceId}_$productId';
    if (cartQuantities.containsKey(key)) {
      cartQuantities[key] = (cartQuantities[key] ?? 1) + 1;
    }
  }

  void decrementQuantity(int productId, int serviceId) {
    final key = '${serviceId}_$productId';
    if (cartQuantities.containsKey(key) && cartQuantities[key]! > 1) {
      cartQuantities[key] = cartQuantities[key]! - 1;
    }
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
