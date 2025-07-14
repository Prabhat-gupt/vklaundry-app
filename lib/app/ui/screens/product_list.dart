import 'package:flutter/material.dart';
import 'package:laundry_app/app/constants/app_theme.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = [
      {
        'name': 'Shirt',
        'price': 17,
        'oldPrice': 20,
        'discount': '15% off',
        'rating': 4.6,
        'reviews': 23,
        'image': 'assets/icons/shirt.png',
      },
      {
        'name': 'Jeans',
        'price': 21,
        'oldPrice': 25,
        'discount': '16% off',
        'rating': 3.8,
        'reviews': 134,
        'image': 'assets/icons/jeans.png',
        'quantity': 3,
      },
      {
        'name': 'Hoodie',
        'price': 26,
        'oldPrice': 30,
        'discount': '18% off',
        'rating': 4.6,
        'reviews': 23,
        'image': 'assets/icons/hoodie.png',
      },
      {
        'name': 'Leather Jacket',
        'price': 32,
        'oldPrice': 40,
        'discount': '21% off',
        'rating': 4.6,
        'reviews': 123,
        'image': 'assets/icons/leather_jacket.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.grey,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          'Men',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.46,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = products[index];
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 200,
                  padding: const EdgeInsets.all(8),
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
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("All shirts (eg. cotton, denim)",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text("\$${item['oldPrice']}",
                              style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12)),
                          const SizedBox(width: 6),
                          Text("\$${item['price']}",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(item['discount'],
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.green, size: 16),
                          Text("${item['rating']}",
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(" (${item['reviews']})",
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      item['quantity'] != null
                          ? Container(
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.remove, size: 16),
                                  const SizedBox(width: 8),
                                  Text(item['quantity'].toString()),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.add, size: 16),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {},
                              child: const Text('Add'),
                            ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shopping_cart, color: Colors.white),
              SizedBox(width: 8),
              Text("View Cart", style: TextStyle(color: Colors.white)),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Text("4", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
