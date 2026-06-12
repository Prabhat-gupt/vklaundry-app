import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF3D52A0),
        elevation: 0,
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.sp),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.r),
        child: Container(
          padding: EdgeInsets.all(23.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PolicySection(
                title: "1. Information We Collect",
                content:
                    "We collect personal information such as your name, phone number, address, and email when you register or place an order for our laundry services. This information is necessary to provide you with pickup and delivery services.",
              ),
              _PolicySection(
                title: "2. How We Use Your Information",
                content:
                    "Your information is strictly used to process your orders, communicate with you regarding your laundry status, and improve our services. We do not sell your personal data to third parties.",
              ),
              _PolicySection(
                title: "3. Data Security",
                content:
                    "We implement industry-standard security measures to protect your personal information from unauthorized access, disclosure, alteration, or destruction.",
              ),
              _PolicySection(
                title: "4. Third-Party Services",
                content:
                    "We may use third-party services (such as payment processors) which have their own privacy policies. We are not responsible for the privacy practices of these third parties.",
              ),
              _PolicySection(
                title: "5. Contact Us",
                content:
                    "If you have any questions about this Privacy Policy, please contact our support team through the Support section in the app.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 23.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D52A0),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              height: 1.w,
            ),
          ),
        ],
      ),
    );
  }
}