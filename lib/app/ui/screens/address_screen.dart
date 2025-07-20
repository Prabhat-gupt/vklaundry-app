import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> addresses = [
      {
        'label': 'Home',
        'address': 'A5, Krishna Nagar, RICCO Rakkar, Sector-2, Han...',
      },
      {
        'label': 'Work',
        'address': 'A5, Krishna Nagar, RICCO Rakkar, Sector-2, Han...',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        title: Text('Addresses', style: TextStyle(fontWeight: FontWeight.bold,color: AppTheme.primaryColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 16.0,right: 16.0,top: 16.0),
        child: ListView.builder(
          itemCount: addresses.length + 1,
          itemBuilder: (context, index) {
            if (index < addresses.length) {
              return AddressCard(
                label: addresses[index]['label']!,
                address: addresses[index]['address']!,
                onEdit: () {},
                onDelete: () {},
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.toNamed(AppRoutes.ADDADDRESS);
                    },
                    icon: const Icon(Icons.add_location_alt_outlined,color: Colors.white,),
                    label: const Text('Add new address', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: AppTheme.primaryColor
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.label,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                Text(address, maxLines: 2, overflow: TextOverflow.ellipsis,style: TextStyle(fontSize: 14,color: Color.fromRGBO(148, 152, 155, 1)),),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
