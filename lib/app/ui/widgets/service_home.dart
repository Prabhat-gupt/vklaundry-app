import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ServiceIcon extends StatelessWidget {
  final String icon;
  final String label;

  const ServiceIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(icon, width: 23.w, height: 23.h),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}