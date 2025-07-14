import 'package:flutter/material.dart';
class ServiceIcon extends StatelessWidget {
  final String icon;
  final String label;

  const ServiceIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(icon, width: 24, height: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}