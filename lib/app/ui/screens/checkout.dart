import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Shirt full sleeve',
        'subtitle': 'All shirt eg. denim cotton',
        'image': 'assets/icons/shirt_checkout.png',
        'quantity': 4,
        'price': 34,
      },
      {
        'title': 'Children dress',
        'subtitle': 'All shirt eg. denim cotton',
        'image': 'assets/icons/children_checkout.png',
        'quantity': 1,
        'price': 34,
      },
      {
        'title': 'Double bed sheet',
        'subtitle': 'Including all colors',
        'image': 'assets/icons/double_checkout.png',
        'quantity': 1,
        'price': 34,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Items Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Items",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                item['image'],
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(item['subtitle'],
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromRGBO(87, 104, 171, 1),
                                    Color.fromRGBO(35, 42, 69, 1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: const [
                                  Icon(Icons.remove, size: 16,color: Colors.white,),
                                  SizedBox(width: 8),
                                  Text("1",style: TextStyle(color: Colors.white),), // hardcoded for now
                                  SizedBox(width: 8),
                                  Icon(Icons.add, size: 16,color: Colors.white),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text("₹34"),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Missed something?",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(87, 104, 171, 1),
                              Color.fromRGBO(35, 42, 69, 1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // Handle add more items
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("+ Add More Items"),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bill Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bill details",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _billRow("🧺 Items total", "₹34"),
                  const SizedBox(height: 8),
                  _billRow("🚚 Delivery charge", "₹34"),
                  const SizedBox(height: 8),
                  _billRow("⚙️ Handling charge", "₹34"),
                  const Divider(height: 24),
                  _billRow("Grand Total", "₹214", isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pickup location
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor,size: 40,),
                SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Pick Up from\nSy.No. 540'A, Gowdaval...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: AppTheme.lightTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text("PAY USING"),
                      ],
                    ),
                    const Text("Google Pay UPI",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.SUCCESS);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("₹214",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text("Total",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                      SizedBox(width: 25),
                      Text("Place Order",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
