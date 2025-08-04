import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final controller = Get.find<ProductListController>();

  late int serviceId;
  late String serviceName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    serviceId = args['service_id'];
    serviceName = args['serviceName'];
    controller.setService(serviceName);
    Future.microtask(() => controller.loadProductsFromSupabase(serviceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.grey,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          serviceName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: controller.categories.map((category) {
                          final categoryId = category['id'];
                          final isSelected =
                              controller.selectedCategoryId.value == categoryId;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                if (isSelected) {
                                  controller.filterProductsByCategory(null);
                                } else {
                                  controller.filterProductsByCategory(categoryId);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  category['name'].toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => GridView.builder(
                    itemCount: controller.filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.46,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final item = controller.filteredProducts[index];
                      final service = controller.currentService.value;
                      final productId = item['id'];
                      final key = '${service}_$productId';
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 200,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          item['image'],
                                          height: 120,
                                          fit: BoxFit.fill,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            height: constraints.maxHeight * 0.3,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image_not_supported,
                                                size: 40, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.bookmark_border),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(item['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text("All shirts (eg. cotton, denim)",
                                    style:
                                        TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text("\u20B9${item['oldPrice']}",
                                        style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text("\u20B9${item['price']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(item['discount'],
                                    style: const TextStyle(
                                        color: Colors.green, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.green, size: 16),
                                    Text("${item['rating']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text(" (${item['reviews']})",
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Obx(() {
                                  final quantity =
                                      controller.cartQuantities[key] ?? 0;
                                  return quantity > 0
                                      ? Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () =>
                                                    controller.removeFromCart(index),
                                                child: const Icon(Icons.remove,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 18),
                                              Text(quantity.toString()),
                                              const SizedBox(width: 18),
                                              InkWell(
                                                onTap: () =>
                                                    controller.addToCart(index),
                                                child: const Icon(Icons.add,
                                                    size: 16),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () =>
                                              controller.addToCart(index),
                                          child: const Text('Add'),
                                        );
                                })
                              ],
                            ),
                          );
                        },
                      );
                    },
                  )),
            )
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => controller.getTotalCartItems() > 0
          ? Container(
              margin: const EdgeInsets.all(16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(32),
              ),
              child: InkWell(
                onTap: () {
                  final selectedItems = controller.getSelectedCartItems();
                  Navigator.pushNamed(
                    context,
                    '/checkout_page',
                    arguments: {
                      'selectedItems': selectedItems,
                      'serviceName': serviceName,
                    },
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text("View Cart",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          controller.getTotalCartItems().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink()),
    );
  }
}