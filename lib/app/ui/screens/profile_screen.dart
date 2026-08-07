import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = Get.find<ProfileController>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Use SharedPreferences instead of GetStorage
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      print("hjhjhjhjhjhjhjhjhjhjjhh $userId");

      if (userId != null) {
        await controller.fetchUserProfile(userId);
        nameController.text = controller.name.value;
        phoneController.text = controller.phone.value;
        emailController.text = controller.email.value;
      }
    });

    // nameController = TextEditingController(text: controller.name.value);
    // phoneController = TextEditingController(text: controller.phone.value);
    // emailController = TextEditingController(text: controller.email.value);

    nameController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    // Check if any value has changed
    final isChanged = nameController.text.trim() != controller.name.value ||
        phone != controller.phone.value ||
        email != controller.email.value;

    // Validation
    final isPhoneValid = RegExp(r'^\d{12}$').hasMatch(phone);
    final isEmailValid = email.contains(".com");

    setState(() {
      isButtonEnabled = isChanged && isPhoneValid && isEmailValid;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.white,
        shadowColor: Color.fromARGB(255, 158, 158, 158),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.r),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 32.w,
                  backgroundImage: AssetImage(
                    "assets/icons/setting_profile.png",
                  ),
                ),
              ],
            ),
            SizedBox(height: 23.h),
            _buildTextField("Name*", nameController),
            _buildTextField(
              "Mobile Number*",
              phoneController,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              "Email Address*",
              emailController,
              hint: "Enter your email",
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 23.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: isButtonEnabled
                    ? () async {
                        final phoneNumber = int.tryParse(
                          phoneController.text.trim(),
                        );
                        if (phoneNumber == null) {
                          Get.snackbar(
                            'Invalid number',
                            'Please enter a valid numeric phone number.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        FocusScope.of(context).unfocus();

                        await controller.updateProfile(
                          nameController.text.trim(),
                          emailController.text.trim(),
                          phoneNumber,
                        );

                        // Show success message
                        Get.snackbar(
                          'Success',
                          'Profile Updated',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Color.fromARGB(
                            147,
                            76,
                            175,
                            79,
                          ),
                          colorText: Colors.white,
                          duration: Duration(seconds: 2),
                        );

                        // Disable button again
                        setState(() {
                          isButtonEnabled = false;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  "Submit",
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 38.h),
            Divider(height: 23.h),
            GestureDetector(
              onTap: () {
                Get.snackbar(
                  "Delete Account",
                  "Please contact support to delete your account.",
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Delete Account",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Deleting account will remove all your orders",
                      style: TextStyle(color: Colors.black54, fontSize: 15.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ),
            filled: true,
            fillColor: Color(0xFFE2E8F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }
}
