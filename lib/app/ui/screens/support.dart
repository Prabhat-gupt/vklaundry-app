import 'dart:io';

import 'package:flutter/material.dart';
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

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open dialer');
    }
  }

  Future<void> _launchWhatsApp(
      {required String phoneNumber, String message = ''}) async {
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
              "https://api.whatsapp.com/send/?phone=$phoneNumber&text=${Uri.encodeComponent(message)}"),
          mode: LaunchMode.externalApplication);
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
      appBar: AppBar(
        centerTitle: true,
        title: Text('Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            )),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.white,
        shadowColor: Color.fromARGB(255, 158, 158, 158),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final support = controller.supportDetails;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactTile(
                icon: Icons.person,
                label: 'Name',
                value: support['name']!,
              ),
              _buildContactTile(
                icon: Icons.phone,
                label: 'Phone',
                value: support['phone']!,
                // onTap: () => _launchPhone(support['phone']!),
              ),
              _buildContactTile(
                icon: Icons.email,
                label: 'Email',
                value: support['email']!,
                onTap: () => _launchUrl("mailto:${support['email']}"),
              ),
              _buildContactTile(
                icon: Icons.chat,
                label: 'WhatsApp',
                value: support['whatsapp']!,
                onTap: () => _launchWhatsApp(phoneNumber: support['whatsapp']!),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: () async {
        // Copy to clipboard
        if(label == 'Phone') {
          await Clipboard.setData(ClipboardData(text: value));
          Get.snackbar(
          'Copied',
          '$label copied to clipboard',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor,
          colorText: Colors.white,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 1),
        );
        }

        // Optional: Launch call if onTap provided
        if (onTap != null) {
          onTap();
        }

        // Show snackbar confirmation
        
        }
      ),
    );
  }
}
