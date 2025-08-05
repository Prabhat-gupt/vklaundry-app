import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductListController extends GetxController {
  final supabase = Supabase.instance.client;

  var products = <Map<String, dynamic>>[].obs;
  var filteredProducts = <Map<String, dynamic>>[].obs;
  var currentService = ''.obs;
  var selectedCategoryId = RxnInt();
  var cartQuantities = <String, int>{}.obs; // key = "service_productId"
  var categories = <Map<String, dynamic>>[].obs;
  var serviceNamesCache = <String, String>{}.obs; // Caching service names

  @override
  void onInit() {
    super.onInit();
    loadCategoriesFromSupabase();
    preloadServiceNames();
  }

  void setService(String service) {
    currentService.value = service;
  }

  Future<void> loadProductsFromSupabase(int serviceId) async {
    try {
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

      final itemsResponse = await supabase
          .from('items')
          .select('*')
          .inFilter('id', itemIds);

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
          'image': item['image_url'] ?? 'assets/icons/shirt.png',
          'price': priceData['price'] ?? 0,
          'oldPrice': priceData['old_price'] ?? 0,
          'discount': priceData['discount'] ?? '',
          'rating': item['rating'] ?? 0.0,
          'reviews': item['reviews'] ?? 0,
          'category_id': item['category_id'],
          'service_id': serviceId,
        };
      }).toList();

      products.addAll(enrichedProducts);
      filteredProducts.value = enrichedProducts;
    } catch (e) {
      print('Error loading products for service $serviceId: $e');
      products.value = [];
      filteredProducts.value = [];
    }
  }

  void filterProductsByCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
    final originalList = List<Map<String, dynamic>>.from(products);
    filteredProducts.value = categoryId == null
        ? originalList
        : originalList.where((product) => product['category_id'] == categoryId).toList();
  }

  void addToCart(Map<String, dynamic> product) {
    final service = product['service_id'].toString();
    final productId = product['id'];
    final key = '${service}_$productId';

    cartQuantities[key] = (cartQuantities[key] ?? 0) + 1;
  }

  void removeFromCart(Map<String, dynamic> product) {
    final service = product['service_id'].toString();
    final productId = product['id'];
    final key = '${service}_$productId';

    if (cartQuantities[key] != null && cartQuantities[key]! > 0) {
      cartQuantities[key] = cartQuantities[key]! - 1;
      if (cartQuantities[key] == 0) {
        cartQuantities.remove(key);
      }
    }
  }

  List<Map<String, dynamic>> getSelectedCartItems() {
    final List<Map<String, dynamic>> items = [];
    cartQuantities.forEach((key, quantity) {
      final parts = key.split('_');
      if (parts.length < 2) return;
      final service = parts[0];
      final productId = int.tryParse(parts[1]);

      final product = products.firstWhereOrNull(
          (item) => item['id'] == productId && item['service_id'].toString() == service);
      if (product != null) {
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
