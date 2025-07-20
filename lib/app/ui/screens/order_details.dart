import 'package:flutter/material.dart';
import 'package:laundry_app/app/constants/app_theme.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order #PQILDFA4095",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14)),
            Text("3 items",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined,
                color: Colors.white, size: 16),
            label:
                const Text("Get Help", style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: Color.fromRGBO(60, 195, 223, 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivered Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_box_rounded,
                          color: Color.fromARGB(167, 76, 175, 79), size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Delivered",
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 52, 
                        child: VerticalDivider(
                          width: 20,
                          thickness: 1,
                          indent: 8,
                          endIndent: 8,
                          color: const Color.fromARGB(170, 158, 158, 158),
                        ),
                      ),

                      // SizedBox(width: 10,),
                      
                      Column(
                        children: [
                          Text("Delivered in",
                              style: TextStyle(color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(60, 195, 233, 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("5 DAYS",
                                style: TextStyle(
                                    color: Color.fromRGBO(0, 112, 136, 1),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("3 Items in order",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Image.asset("assets/icons/shirt.png", height: 50),
                        title: const Text("Shirt full sleeve",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: const Text(
                          "All shirt eg. denim cotton",
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("₹34",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("₹34",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bill Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bill details",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _billRow("Items total", "₹34"),
                  _billRow("Dealivery charge", "₹34"),
                  _billRow("Handling charge", "₹34"),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text("Download Invoice",
                                style: TextStyle(
                                    color: Color.fromRGBO(0, 112, 136, 1))),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Color.fromRGBO(60, 195, 233, 0.6),
                              padding: EdgeInsets.all(8),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(
                                  color: Colors.lightBlue, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("₹214",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order details",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text("Order ID\n#PQISNSFF09435",
                      style: TextStyle(height: 1.4)),
                  SizedBox(height: 12),
                  Text("Receiver Details\nTony Stark, +91-8937298743",
                      style: TextStyle(height: 1.4)),
                  SizedBox(height: 12),
                  Text("Delivery Address\nA-2, Krishna Nagar, Chandigarh",
                      style: TextStyle(height: 1.4)),
                  SizedBox(height: 12),
                  Text("Delivered on\n28 Jun 2025, 2:04 PM",
                      style: TextStyle(height: 1.4)),
                ],
              ),
            ),
            // const SizedBox(height: 80),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: AppTheme.primaryColor, width: 1)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              child: Text("Other Items",
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text("Order Again",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount),
        ],
      ),
    );
  }
}
