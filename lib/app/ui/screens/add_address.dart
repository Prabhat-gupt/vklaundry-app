import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final houseController = TextEditingController(text: 'A5, 2nd floor');
  final buildingController = TextEditingController(text: 'Sikhar Tower');
  final landmarkController = TextEditingController();
  final receiverNameController = TextEditingController(text: 'Willian Haris');
  final receiverPhoneController = TextEditingController(text: '9893403043');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Address Details", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
            SizedBox(height: 12.h),
            _buildTextField("House No. & Floor*", houseController),
            SizedBox(height: 12.h),
            _buildTextField("Building & Block No. (optional)", buildingController),
            SizedBox(height: 12.h),
            _buildTextField("Landmark*", landmarkController, hintText: "Enter nearby landmark"),
            SizedBox(height: 24.h),
            Text("Receiver’s Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
            SizedBox(height: 12.h),
            _buildTextField("Receiver's Name *", receiverNameController),
            SizedBox(height: 12.h),
            _buildTextField("Receiver's Phone Number *", receiverPhoneController, keyboardType: TextInputType.phone),
            SizedBox(height: 32.h),
            
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1C39),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () {
                  Get.back();
                },
                child: Text("Save Address", style: TextStyle(fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hintText, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFE0E0E0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
          ),
        ),
      ],
    );
  }
}
