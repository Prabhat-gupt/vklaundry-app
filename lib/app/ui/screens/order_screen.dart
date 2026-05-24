import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/ui/screens/order_details.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {
        "status": "Waiting for confirmation",
        "date": "Ordered on 31 Dec",
        "amount": "₹214",
        "action": "Get Help",
        "images": [
          "assets/icons/shirt_checkout.png",
          "assets/icons/children_checkout.png",
          "assets/icons/double_checkout.png",
        ],
        "bg": Colors.yellow.shade100,
      },
      {
        "status": "Processing",
        "date": "Ordered on 31 Dec",
        "amount": "₹176",
        "action": "Get Help",
        "images": [
          "assets/icons/shirt_checkout.png",
          "assets/icons/children_checkout.png",
          "assets/icons/double_checkout.png",
        ],
        "bg": Colors.white,
      },
      {
        "status": "Order Confirmed",
        "date": "Ordered on 31 Dec",
        "amount": "₹598",
        "action": "Order Again",
        "images": [
          "assets/icons/shirt_checkout.png",
          "assets/icons/children_checkout.png",
          "assets/icons/double_checkout.png",
        ],
        "bg": Colors.white,
      },
      {
        "status": "Delivered",
        "date": "Delivered on 31 Dec",
        "amount": "₹104",
        "action": "Order Again",
        "images": [
          "assets/icons/shirt_checkout.png",
          "assets/icons/children_checkout.png",
          "assets/icons/double_checkout.png",
        ],
        "bg": Colors.white,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.white,
        shadowColor: Color.fromARGB(255, 158, 158, 158),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image row
                SizedBox(
                  height: 50.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (order["images"] as List).length,
                    itemBuilder: (context, imgIndex) {
                      return Container(
                        margin: EdgeInsets.only(right: 8.w),
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          image: DecorationImage(
                            image: AssetImage(
                              (order["images"] as List<String>)[imgIndex],
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),

                // Status + Amount Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status + Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order["status"]! as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          order["date"]! as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // Amount & arrow
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          Get.context!,
                          // MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          MaterialPageRoute(
                            builder: (context) => const OrderDetailsPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            order["amount"]! as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(color: Colors.grey.shade300),
                Center(
                  child: InkWell(
                    onTap: () {},
                    child: Text(
                      (order["action"] as String?) ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            ((order["action"] as String?) ?? "") == "Get Help"
                                ? Colors.indigo
                                : Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
