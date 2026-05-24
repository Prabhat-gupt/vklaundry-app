import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            Text(
              "Order #PQILDFA4095",
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
            ),
            Text(
              "3 items",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: Icon(
              Icons.message_outlined,
              color: Colors.white,
              size: 16.sp,
            ),
            label: Text(
              "Get Help",
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Color.fromRGBO(60, 195, 223, 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivered Section
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_box_rounded,
                        color: Color.fromARGB(167, 76, 175, 79),
                        size: 42.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Delivered",
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 52.h,
                        child: VerticalDivider(
                          width: 20.w,
                          thickness: 1,
                          indent: 8,
                          endIndent: 8,
                          color: const Color.fromARGB(170, 158, 158, 158),
                        ),
                      ),

                      // SizedBox(width: 10.w,),
                      Column(
                        children: [
                          Text(
                            "Delivered in",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(60, 195, 233, 0.6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              "5 DAYS",
                              style: TextStyle(
                                color: Color.fromRGBO(0, 112, 136, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "3 Items in order",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          "assets/icons/shirt.png",
                          height: 50.h,
                        ),
                        title: Text(
                          "Shirt full sleeve",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        subtitle: Text(
                          "All shirt eg. denim cotton",
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "₹34",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            Text(
                              "₹34",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Bill Details
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bill details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  _billRow("Items total", "₹34"),
                  _billRow("Dealivery charge", "₹34"),
                  _billRow("Handling charge", "₹34"),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grand Total",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Download Invoice",
                              style: TextStyle(
                                color: Color.fromRGBO(0, 112, 136, 1),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(
                                60,
                                195,
                                233,
                                0.6,
                              ),
                              padding: EdgeInsets.all(8.r),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                width: 1.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "₹214",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Order Details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Order ID\n#PQISNSFF09435",
                    style: TextStyle(height: 1.4),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Receiver Details\nTony Stark, +91-8937298743",
                    style: TextStyle(height: 1.4),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Delivery Address\nA-2, Krishna Nagar, Chandigarh",
                    style: TextStyle(height: 1.4),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Delivered on\n28 Jun 2025, 2:04 PM",
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            // SizedBox(height: 80.h),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        height: 80.h,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.primaryColor, width: 1.w),
          ),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppTheme.primaryColor, width: 2.w),
              ),
              child: Text(
                "Other Items",
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                "Order Again",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(amount)],
      ),
    );
  }
}
