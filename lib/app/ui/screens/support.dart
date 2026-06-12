import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/support_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  final controller = Get.put(SupportController());

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open link');
    }
  }

  // Future<void> _launchPhone(String phoneNumber) async {
  //   final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  //   if (await canLaunchUrl(phoneUri)) {
  //     await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  //   } else {
  //     Get.snackbar('Error', 'Could not open dialer');
  //   }
  // }
  Future<void> _launchPhone(String phoneNumber) async {
    // Remove spaces and ensure correct format
    final cleanNumber = phoneNumber.replaceAll(' ', '');

    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open dialer');
    }
  }

  Future<void> _launchWhatsApp({
    required String phoneNumber,
    String message = '',
  }) async {
    String whatsappUrl;

    if (Platform.isIOS) {
      // Use wa.me link for iOS
      whatsappUrl =
          "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
    } else {
      // Use whatsapp://send for Android
      whatsappUrl =
          "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}";
    }

    Uri uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle cases where WhatsApp is not installed or the URL cannot be launched
      print('Could not launch WhatsApp. Make sure WhatsApp is installed.');
      // Optionally, launch WhatsApp Web or show an error message
      await launchUrl(
        Uri.parse(
          "https://api.whatsapp.com/send/?phone=$phoneNumber&text=${Uri.encodeComponent(message)}",
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // Future<void> _launchWhatsApp(String phoneNumber) async {
  //   // Format to remove + and spaces
  //   final String formattedNumber =
  //       phoneNumber.replaceAll('+', '').replaceAll(' ', '');
  //   final Uri whatsappUri = Uri.parse("https://wa.me/$formattedNumber");
  //   if (await canLaunchUrl(whatsappUri)) {
  //     await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  //   } else {
  //     Get.snackbar('Error', 'Could not open WhatsApp');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Support',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryColor,
              size: 17.sp,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(23.r),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 75.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 23.h),
              Text(
                "How can we help you?",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                "Reach out to our support team for any queries or assistance.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 30.h),
              Obx(() {
                final support = controller.supportDetails;
                return Column(
                  children: [
                    _buildContactTile(
                      icon: Icons.person_rounded,
                      label: 'Name',
                      value: support['name']!,
                      iconColor: Colors.blue,
                    ),
                    _buildContactTile(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: support['phone']!,
                      iconColor: Colors.orange,
                    ),
                    _buildContactTile(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: support['email']!,
                      onTap: () => _launchUrl("mailto:${support['email']}"),
                      iconColor: Colors.red,
                    ),
                    _buildContactTile(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      value: support['whatsapp']!,
                      onTap: () => _launchWhatsApp(phoneNumber: support['whatsapp']!),
                      iconColor: Colors.green,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primaryColor;
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (label == 'Phone') {
              await Clipboard.setData(ClipboardData(text: value));
              Get.snackbar(
                'Copied',
                '$label copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppTheme.primaryColor,
                colorText: Colors.white,
                margin: EdgeInsets.all(15.r),
                borderRadius: 15.r,
                duration: Duration(seconds: 2),
              );
            }
            if (onTap != null) {
              onTap();
            }
          },
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(15.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(icon, color: color, size: 23.sp),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
