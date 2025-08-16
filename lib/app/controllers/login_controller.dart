// Assuming you have a `users` table where you want to store additional user data
// and link it with Supabase `auth.users.uuid`

import 'package:get/get.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = false.obs;

  // Send OTP
  Future<void> sendOtp(String phone) async {
    isLoading.value = true;
    try {
      await supabase.auth.signInWithOtp(
        phone: '+91$phone',
        channel: OtpChannel.sms,
      );
      print('OTP sent to +91$phone');
      Get.toNamed('/otp_screen', arguments: {'phone': phone});
    } catch (e) {
      print('Error sending OTP: $e');
      Get.snackbar('Error', 'Failed to send OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP and insert into your own "users" table
  Future<void> verifyOtp(String phone, String otp) async {
    isLoading.value = true;
    try {
      final response = await supabase.auth.verifyOTP(
        phone: '+91$phone',
        token: otp,
        type: OtpType.sms,
      );

      final user = response.user;
      if (user != null) {
        final uuid = user.id;
        final phoneNumber = user.phone;

        // Check if already exists
        final existingUser = await supabase
            .from('users')
            .select()
            .eq('uuid', uuid)
            .maybeSingle();

        if (existingUser == null) {
          // Insert new row with uuid & phone
          await supabase.from('users').insert({
            'uuid': uuid,
            'phone': phoneNumber,
            // add more fields as needed
          });

          Get.offAllNamed(AppRoutes.SETUPSCREEN);
        }else{
          // User already exists, navigate to home or another screen
          Get.offAllNamed(AppRoutes.ROOT);
        }
        print('User mapped with uuid: $uuid');
        
      } else {
        print('OTP verification failed');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }



}
