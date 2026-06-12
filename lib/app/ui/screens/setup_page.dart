import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
// Removed get_storage import - using SharedPreferences instead
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // Removed GetStorage - using SharedPreferences instead

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

  Future<Map<String, dynamic>?> _getCoordinatesFromAddress() async {
    final pincode = landmarkController.text.trim();
    
    if (pincode.isEmpty) {
      return null;
    }

    try {
      List<Location> locations = await locationFromAddress('$pincode, India');
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        // Get city name using reverse geocoding
        String cityName = 'Hyderabad'; // default fallback
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            // Try to get city from locality or subAdministrativeArea
            cityName = placemark.locality ?? 
                      placemark.subAdministrativeArea ?? 
                      'Hyderabad';
          }
        } catch (e) {
          // If reverse geocoding fails, use default
        }
        
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'city': cityName,
        };
      }
    } catch (e) {
      // Geocoding failed
    }
    
    return null;
  }

  bool _checkServiceAvailability(double lat, double lon) {
    // Service center coordinates
    const centerLat = 17.608400;
    const centerLon = 78.466200;
    const serviceRadiusKm = 10.0;
    
    // Calculate distance using Haversine formula
    final distance = _calculateDistance(centerLat, centerLon, lat, lon);
    
    return distance <= serviceRadiusKm;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));
    
    double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _saveUserData() async {
    setState(() => isLoading = true);
    try {
      // Get userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) throw Exception('User not logged in');

      // Get coordinates from address
      final locationData = await _getCoordinatesFromAddress();

      await supabase.from('users').update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      }).eq('id', userId);

      // Prepare address data with coordinates and city if available
      final addressData = {
        'id': userId, // foreign key to users table
        'address_line': '${houseController.text.trim()} '
            '${buildingController.text.trim()}',
        'city': locationData?['city'] ?? 'Hyderabad', // Use city from geocoding or default
        'state': 'Telangana',
        'landmark_pincode': landmarkController.text.trim(),
      };

      // Add coordinates if geocoding was successful
      if (locationData != null && 
          locationData['latitude'] != null && 
          locationData['longitude'] != null) {
        addressData['latitude'] = locationData['latitude'] as Object;
        addressData['longitude'] = locationData['longitude'] as Object;
      }

      await supabase.from('addresses').upsert(addressData, onConflict: 'id');

      // Stop loading before navigation
      setState(() => isLoading = false);

      // Check service availability before navigation
      if (locationData != null && 
          locationData['latitude'] != null && 
          locationData['longitude'] != null) {
        final lat = (locationData['latitude'] as num).toDouble();
        final lon = (locationData['longitude'] as num).toDouble();
        
        final isServiceAvailable = _checkServiceAvailability(lat, lon);
        
        if (!isServiceAvailable) {
          // Calculate distance for display
          const centerLat = 17.608400;
          const centerLon = 78.466200;
          final distance = _calculateDistance(centerLat, centerLon, lat, lon);
          
          Get.off(
            () => ServiceNotAvailableScreen(distance: distance),
          );
          return;
        }
      }

      // Navigate to home screen
      Get.offAllNamed('/root');
    } catch (e) {
      setState(() => isLoading = false);
      print("Error saving user data: $e");
      Get.snackbar(
        'Error: ',
        "Please try in sometime",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Profile'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                "Full Name",
                nameController,
                hintText: "Enter your full name",
              ),
              SizedBox(height: 12.h),
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
              SizedBox(height: 15.h),
              Text(
                "Add Address",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.sp),
              ),
              SizedBox(height: 15.h),
              _buildTextField(
                "House No. & Floor*",
                houseController,
                hintText: "A5, 2nd floor",
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                "Building Name & Block No.*",
                buildingController,
                hintText: "Sikhar Tower, 10",
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                "Landmark Pincode*",
                landmarkController,
                hintText: "Enter nearby landmark",
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid ? AppTheme.primaryColor : Colors.grey, // ✅
                  ),
                  onPressed: (!isFormValid || isLoading) ? null : _saveUserData,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save', style: TextStyle(fontSize: 18.sp)),
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
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: Color(0xFFE0E0E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 15.h,
            ),
          ),
        ),
      ],
    );
  }
}