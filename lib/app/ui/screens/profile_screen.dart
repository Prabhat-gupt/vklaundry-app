import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';

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
      print("hjhjhjhjhjhjhjhjhjhjjhh ${controller.storages.read('userId')}");

      await controller.fetchUserProfile(controller.storages.read('userId'));
      nameController.text = controller.name.value;
      phoneController.text = controller.phone.value;
      emailController.text = controller.email.value;

      // nameController = TextEditingController(text: controller.name.value);
      // phoneController = TextEditingController(text: controller.phone.value);
      // print("my namecontroller is ::::::: ${nameController.text}");
      // emailController = TextEditingController(text: controller.email.value);
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
        shadowColor: const Color.fromARGB(255, 158, 158, 158),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage(
                    "assets/icons/setting_profile.png",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
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
                          backgroundColor: const Color.fromARGB(
                            147,
                            76,
                            175,
                            79,
                          ),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(height: 24),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Delete Account",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Deleting account will remove all your orders",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFE2E8F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
