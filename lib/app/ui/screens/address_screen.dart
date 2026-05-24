import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomePageController controller = Get.find<HomePageController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        title: Text(
          'Addresses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (controller.userAddress.isEmpty) {
          return Center(child: Text("No address found"));
        }

        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            ...controller.userAddress.map((addr) {
              String fullAddress =
                  "${addr['address_line'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['landmark_pincode'] ?? ''}";
              return AddressCard(
                label: addr['is_default'] == true ? "Default" : "Address",
                address: fullAddress,
                onEdit: () {
                  _showAddressEditDialog(context, addr, controller);
                },
                onDelete: () {
                  // controller.deleteAddress(addr['id']);
                },
              );
            }).toList(),
            Padding(
              padding: EdgeInsets.only(top: 8.0.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showAddressEditDialog(
                      context,
                      controller.userAddress.first,
                      controller,
                    );
                  },
                  icon: Icon(
                    Icons.add_location_alt_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Update Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: TextStyle(fontSize: 16.sp),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Popup Dialog for Editing Address
  void _showAddressEditDialog(
    BuildContext context,
    Map<String, dynamic> addr,
    HomePageController controller,
  ) {
    final houseController = TextEditingController(
      text: addr['address_line'] ?? '',
    );
    // final buildingController = TextEditingController(
    //     text: addr['address_line']?.split(",").skip(1).join(",").trim() ?? '');
    final cityController = TextEditingController(text: addr['city'] ?? '');
    final stateController = TextEditingController(text: addr['state'] ?? '');
    final landmarkController = TextEditingController(
      text: addr['landmark_pincode']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Update Address"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: houseController,
                decoration: InputDecoration(
                  labelText: "Address Line",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: "City",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: "State",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: landmarkController,
                decoration: InputDecoration(
                  labelText: "Landmark / Pincode",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () async {
              try {
                await Supabase.instance.client.from('addresses').upsert({
                  'id': addr['id'],
                  'address_line': '${houseController.text.trim()}',
                  'city': cityController.text.trim(),
                  'state': stateController.text.trim(),
                  'landmark_pincode': landmarkController.text.trim(),
                }, onConflict: 'id');

                controller.fetchUserAddress();

                Get.back();
                Get.snackbar(
                  "Success",
                  "Address updated successfully",
                  backgroundColor: Colors.green.shade100,
                );
              } catch (e) {
                Get.snackbar(
                  "Error",
                  e.toString(),
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            child: Text("Save"),
          ),
        ],
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
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Color.fromRGBO(148, 152, 155, 1),
                  ),
                ),
              ],
            ),
          ),
          // IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: onEdit,
          //   color: AppTheme.primaryColor,
          // )
        ],
      ),
    );
  }
}
