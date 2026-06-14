import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/routes/app_pages.dart'; // Make sure this import has your root route

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = Get.arguments['order_id'];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 23.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 94.sp),
              SizedBox(height: 23.h),
              Text(
                "Order Placed Successfully!",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                "Thank you for your order. We'll notify you when it is on the way.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.sp, color: Colors.black54),
              ),
              SizedBox(height: 38.h),
              SizedBox(
                width: double.infinity,
                height: 45.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed(AppRoutes.ROOT);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B1C39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    "Continue Shopping",
                    style: TextStyle(fontSize: 15.sp),
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              // TextButton(
              //   onPressed: () {
              //     // Navigate to Order Details/Tracking
              //     Get.offNamed(AppRoutes.TRACKING, arguments: {'order_id': orderId}); // Replace with actual order ID
              //   },
              //   child: Text("Track Order", style: TextStyle(color: Color(0xFF1B1C39))),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
