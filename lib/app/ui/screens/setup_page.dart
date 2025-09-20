import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final houseController = TextEditingController();
  final buildingController = TextEditingController();
  final landmarkController = TextEditingController();
  var storage = GetStorage();

  bool isLoading = false;
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Listen to changes in all required fields
    nameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
    houseController.addListener(_validateForm);
    buildingController.addListener(_validateForm);
    landmarkController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      final email = emailController.text.trim();
      final isEmailValid =
          email.isNotEmpty && email.contains("@") && email.contains(".com");

      isFormValid = nameController.text.trim().isNotEmpty &&
          isEmailValid &&
          houseController.text.trim().isNotEmpty &&
          buildingController.text.trim().isNotEmpty &&
          landmarkController.text.trim().isNotEmpty;
    });
  }

  Future<void> _saveUserData() async {
    setState(() => isLoading = true);
    try {
      // final user = supabase.auth.currentUser;
      if (storage.read('userId') == null) throw Exception('User not logged in');

      await supabase.from('users').update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      }).eq('id', storage.read('userId'));

      int id = await supabase
          .from('users')
          .select('id')
          .eq('id', storage.read('userId'))
          .single()
          .then((data) => data['id']);

      await supabase.from('addresses').upsert({
        'id': id, // foreign key to users table
        'address_line': '${houseController.text.trim()}'
            '${buildingController.text.trim()}',
        'city': 'Hyderabad',
        'state': 'Telangana',
        'landmark_pincode': landmarkController.text.trim(),
      }, onConflict: 'id');

      Get.offAllNamed('/root');
    } catch (e) {
      print("Error saving user data: $e");
      Get.snackbar(
        'Error: ',
        "Please try in sometime",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                "Full Name",
                nameController,
                hintText: "Enter your full name",
              ),
              const SizedBox(height: 12),
              _buildTextField(
                "Email",
                emailController,
                hintText: "Enter your email",
                keyboardType: TextInputType.emailAddress,
                errorText: emailController.text.isNotEmpty &&
                        (!emailController.text.contains("@") ||
                            !emailController.text.contains(".com"))
                    ? "Enter a valid email address"
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Add Address",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "House No. & Floor*",
                houseController,
                hintText: "A5, 2nd floor",
              ),
              const SizedBox(height: 12),
              _buildTextField(
                "Building Name & Block No.*",
                buildingController,
                hintText: "Sikhar Tower, 10",
              ),
              const SizedBox(height: 12),
              _buildTextField(
                "Landmark Pincode*",
                landmarkController,
                hintText: "Enter nearby landmark",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid ? AppTheme.primaryColor : Colors.grey, // ✅
                  ),
                  onPressed: (!isFormValid || isLoading) ? null : _saveUserData,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
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
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: const Color(0xFFE0E0E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
