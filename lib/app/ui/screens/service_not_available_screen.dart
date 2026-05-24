import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceNotAvailableScreen extends StatelessWidget {
  final double distance;

  const ServiceNotAvailableScreen({
    super.key,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.0.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 50.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Service Not Available',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // Message
              Text(
                'We currently serve customers within 10 km radius from our service center.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Coming soon message
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '✨ We will come to your location soon!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40.h),

              // Change Address button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showChangeAddressDialog(context),
                  icon:
                      Icon(Icons.edit_location_alt, color: Colors.white),
                  label: Text(
                    'Change Address',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fetch address directly from Supabase (works even when HomePageController
  /// is not yet registered, e.g. when arriving from splash/setup screen).
  Future<Map<String, dynamic>?> _fetchAddressFromSupabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('addresses')
          .select('*')
          .eq('id', userId)
          .limit(1);

      if (response.isEmpty) return null;
      return Map<String, dynamic>.from(response.first);
    } catch (e) {
      print('❌ Error fetching address: $e');
      return null;
    }
  }

  void _showChangeAddressDialog(BuildContext context) {
    // Show a loading indicator while we fetch the address from Supabase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    _fetchAddressFromSupabase().then((userAddress) {
      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);

      if (userAddress == null) {
        Get.snackbar(
          'Error',
          'Could not load your address. Please try logging in again.',
          backgroundColor: Colors.red.shade100,
        );
        return;
      }

      if (context.mounted) _openAddressDialog(context, userAddress);
    });
  }

  void _openAddressDialog(
      BuildContext context, Map<String, dynamic> userAddress) {
    // Try to find the HomePageController (may or may not be registered yet)
    HomePageController? controller;
    try {
      controller = Get.find<HomePageController>();
    } catch (_) {
      controller = null;
    }

    final houseController =
        TextEditingController(text: userAddress['address_line'] ?? '');
    final cityController =
        TextEditingController(text: userAddress['city'] ?? '');
    final stateController =
        TextEditingController(text: userAddress['state'] ?? '');
    final pincodeController = TextEditingController(
        text: userAddress['landmark_pincode']?.toString() ?? '');

    final isSaving = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryColor),
              SizedBox(width: 8.w),
              Text('Change Address'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16.sp, color: Colors.blue),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Enter your pincode so we can check if your area is serviceable.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: houseController,
                  decoration: InputDecoration(
                    labelText: 'Address Line',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Pincode *',
                    hintText: 'Enter your area pincode',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isSaving,
              builder: (_, saving, __) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        isSaving.value = true;
                        await _saveAndCheckAddress(
                          ctx: ctx,
                          controller: controller,
                          userAddress: userAddress,
                          houseText: houseController.text.trim(),
                          cityText: cityController.text.trim(),
                          stateText: stateController.text.trim(),
                          pincodeText: pincodeController.text.trim(),
                        );
                        isSaving.value = false;
                      },
                child: saving
                    ? SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save & Check',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndCheckAddress({
    required BuildContext ctx,
    required HomePageController? controller,
    required Map<String, dynamic> userAddress,
    required String houseText,
    required String cityText,
    required String stateText,
    required String pincodeText,
  }) async {
    try {
      final addressId = userAddress['id'];
      if (addressId == null) {
        Get.snackbar('Error', 'No address record found. Please re-login.',
            backgroundColor: Colors.red.shade100);
        return;
      }

      if (pincodeText.isEmpty) {
        Get.snackbar('Required', 'Please enter your area pincode.',
            backgroundColor: Colors.orange.shade100);
        return;
      }

      // Step 1: Geocode the pincode to get lat/lon
      double? lat;
      double? lon;
      String resolvedCity = cityText;

      try {
        List<Location> locations =
            await locationFromAddress('$pincodeText, India');
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lon = locations.first.longitude;

          // Reverse geocode to get city name
          try {
            List<Placemark> placemarks =
                await placemarkFromCoordinates(lat, lon);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              resolvedCity = p.locality ??
                  p.subAdministrativeArea ??
                  cityText;
            }
          } catch (_) {}
        }
      } catch (e) {
        // Geocoding failed — we'll save text fields only, skip coordinate update
        print('⚠️ Geocoding failed for pincode $pincodeText: $e');
      }

      // Step 2: Build the update payload
      final Map<String, dynamic> payload = {
        'id': addressId,
        'address_line': houseText,
        'city': resolvedCity.isNotEmpty ? resolvedCity : cityText,
        'state': stateText,
        'landmark_pincode': pincodeText,
      };

      // Only update coordinates if geocoding was successful
      if (lat != null && lon != null) {
        payload['latitude'] = lat;
        payload['longitude'] = lon;
        print('📍 Geocoded lat=$lat, lon=$lon for pincode=$pincodeText');
      }

      // Step 3: Save to Supabase
      await Supabase.instance.client
          .from('addresses')
          .upsert(payload, onConflict: 'id');

      // Step 4: Re-fetch address + re-check service availability
      // fetchUserAddress() is void, so we can't await it directly
      if (controller != null) {
        controller.fetchUserAddress();
        // Give the async internals time to finish before we read isServiceAvailable
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      // Close dialog
      Navigator.pop(ctx);

      // Step 5: Check availability (already waited for reactive update above)
      bool isNowAvailable = false;

      if (controller != null) {
        isNowAvailable = controller.isServiceAvailable.value;
      } else if (lat != null && lon != null) {
        // Fallback: manually check distance
        const centerLat = 17.608400;
        const centerLon = 78.466200;
        const serviceRadiusKm = 10.0;
        final d = _haversineDistance(centerLat, centerLon, lat, lon);
        isNowAvailable = d <= serviceRadiusKm;
      }

      if (isNowAvailable) {
        Get.snackbar(
          '🎉 Great news!',
          'Service is now available in your area!',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAllNamed(AppRoutes.ROOT);
      } else {
        if (lat == null) {
          Get.snackbar(
            '📍 Address Updated',
            'Could not find coordinates for this pincode. Please try a different pincode.',
            backgroundColor: Colors.orange.shade100,
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            '😔 Still Outside Service Area',
            'Sorry, we don\'t serve your area yet. We\'re expanding soon!',
            backgroundColor: Colors.orange.shade100,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving address: $e');
      Get.snackbar(
        'Error',
        'Failed to update address. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusKm * 2 * asin(sqrt(a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
