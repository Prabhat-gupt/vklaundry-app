// // Assuming you have a `users` table where you want to store additional user data
// // and link it with Supabase `auth.users.uuid`
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:laundry_app/app/routes/app_pages.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class LoginController extends GetxController {
//   final SupabaseClient supabase = Supabase.instance.client;

//   var isLoading = false.obs;
//   var isPhoneValid = false.obs;
//   String? lastOtp;

//   String _generateOtp() {
//     final random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }

//   // Send OTP
//   // Future<void> sendOtp(String phone) async {
//   //   isLoading.value = true;
//   //   try {
//   //     // await supabase.auth.signInWithOtp(
//   //     //   phone: '+91$phone',
//   //     //   channel: OtpChannel.sms,
//   //     // );

//   //     https: //sms.par-ken.com/api/smsapi?key=Account key&route=Route&sender=Sender id&number=Number(s)&sms=Message&templateid=DLT_Templateid
//   //     print('OTP sent to +91$phone');
//   //     Get.toNamed('/otp_screen', arguments: {'phone': phone});
//   //   } catch (e) {
//   //     print('Error sending OTP: $e');
//   //     Get.snackbar('Error', 'Failed to send OTP. Please try again.');
//   //   } finally {
//   //     isLoading.value = false;
//   //   }
//   // }

//   Future<void> sendOtp(String phone) async {
//     isLoading.value = true;
//     try {
//       final otp = _generateOtp();
//        lastOtp = otp;

//       // API URL (replace placeholders with your actual values)
//       // https: //sms.par-ken.com/api/smsapi?key=d79a7922c71f0bdf52199be7dad15110&route=1&sender=IMSTRG&number=8982748401&sms=522522&templateId=1407175688617050959
// final apiUrl = Uri.parse(
//   "https://sms.par-ken.com/api/smsapi"
//   "?key=d79a7922c71f0bdf52199be7dad15110"
//   "&route=1"
//   "&sender=IMSTRG"
//   "&number=$phone"
//   "&sms=${otp} is your OTP to login to VK laundry. DO NOT share with anyone. VK laundry never calls to ask for OTP.-PS"
//   "&templateid=1407175688617050959",
// );

//       final response = await http.get(apiUrl);

//       if (response.statusCode == 200) {
//         print("OTP Sent Successfully: $otp");
//         // ✅ Move to OTP screen and pass OTP for debugging (don’t use in production)
//         Get.toNamed('/otp_screen', arguments: {'phone': phone, 'otp': otp});
//       } else {
//         print("Failed with status: ${response.statusCode}");
//         Get.snackbar("Error", "Failed to send OTP. Try again.");
//       }
//     } catch (e) {
//       print("Error sending OTP: $e");
//       Get.snackbar("Error", "Failed to send OTP. Please try again.");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Verify OTP and insert into your own "users" table
// Future<void> verifyOtp(
//   String phone,
//   String otp, {
//   VoidCallback? onWrongOtp, // callback for wrong OTP
// }) async {
//   isLoading.value = true;
//   try {
//     final response = await supabase.auth.verifyOTP(
//       phone: '+91$phone',
//       token: otp,
//       type: OtpType.sms,
//     );

//     final user = response.user;

//     if (user != null) {
//       final uuid = user.id;
//       final phoneNumber = user.phone;

//       // ✅ Check if already exists
//       final existingUser = await supabase
//           .from('users')
//           .select()
//           .eq('uuid', uuid)
//           .maybeSingle();

//       if (existingUser == null) {
//         // New user → insert
//         await supabase.from('users').insert({
//           'uuid': uuid,
//           'phone': phoneNumber,
//         });
//         Get.offAllNamed(AppRoutes.SETUPSCREEN);
//       } else {
//         // Existing user → go to home
//         Get.offAllNamed(AppRoutes.ROOT);
//       }

//       print('User mapped with uuid: $uuid');
//     } else {
//       // ❌ Wrong OTP
//       if (onWrongOtp != null) onWrongOtp();
//       Get.snackbar(
//         "Invalid OTP",
//         "The OTP you entered is incorrect. Please try again.",
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//     }
//   } on AuthException catch (_) {
//     // Supabase specific wrong OTP error
//     if (onWrongOtp != null) onWrongOtp();
//     Get.snackbar(
//       "Invalid OTP",
//       "The OTP you entered is incorrect. Please try again.",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//   } catch (e) {
//     // Other errors
//     Get.snackbar(
//       "Error",
//       e.toString(),
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//     print('Error verifying OTP: $e');
//   } finally {
//     isLoading.value = false;
//   }
// }

// }

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  var isLoading = false.obs;
  String? lastOtp; // store generated OTP
  String? lastMessageId; // store message ID from SMS API
  var isPhoneValid = false.obs;

  /// Generate random 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP via SMS API
  Future<void> sendOtp(String phone) async {
    isLoading.value = true;
    try {
      final otp = _generateOtp();
      lastOtp = otp; // save locally

      final apiUrl = Uri.parse(
        "https://sms.par-ken.com/api/smsapi"
        "?key=d79a7922c71f0bdf52199be7dad15110"
        "&route=1"
        "&sender=IMSTRG"
        "&number=$phone"
        "&sms=${otp} is your OTP to login to VK laundry. DO NOT share with anyone. VK laundry never calls to ask for OTP.-PS"
        "&templateid=1407175688617050959",
      );

      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        // TODO: Parse `messageid` from response (API should return it)
        // Example: {"messageid":"123456"}
        // final data = jsonDecode(response.body);
        // lastMessageId = data["messageid"];

        print("OTP Sent: $otp");
        Get.toNamed('/otp_screen', arguments: {'phone': phone});
      } else {
        Get.snackbar("Error", "Failed to send OTP. Try again.");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to send OTP: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP by checking DLR API + comparing entered OTP
  // Future<void> verifyOtp(String phone, String enteredOtp,
  //     {VoidCallback? onWrongOtp}) async {
  //   isLoading.value = true;
  //   try {
  //     if (lastOtp == null) {
  //       Get.snackbar("Error", "OTP not generated. Please request again.");
  //       return;
  //     }
  //     if (enteredOtp == lastOtp) {
  //       Get.offAllNamed(AppRoutes.ROOT);
  //       print("OTP verified successfully!");
  //     } else {
  //       Get.snackbar("Invalid OTP", "The OTP you entered is incorrect.");
  //     }
  //   } catch (e) {
  //     if (onWrongOtp != null) onWrongOtp();
  //     Get.snackbar("Error", "OTP verification failed: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> verifyOtp(String phone, String enteredOtp,
      {VoidCallback? onWrongOtp}) async {
    isLoading.value = true;
    try {
      if (lastOtp == null) {
        Get.snackbar("Error", "OTP not generated. Please request again.");
        return;
      }

      if (enteredOtp == lastOtp) {
        // ✅ Create / fetch Supabase user anonymously
        final authResponse = await supabase.auth.signInAnonymously();
        final user = authResponse.user;

        if (user != null) {
          final uuid = user.id;
          final phoneNumber = '+91$phone';

          // ✅ Check if user exists in custom "users" table
          final existingUser = await supabase
              .from('users')
              .select()
              .eq('uuid', uuid)
              .maybeSingle();

          if (existingUser == null) {
            // New user → insert
            await supabase.from('users').insert({
              'uuid': uuid,
              'phone': phoneNumber,
            });
            Get.offAllNamed(AppRoutes.SETUPSCREEN);
          } else {
            // Existing user → go to home
            Get.offAllNamed(AppRoutes.ROOT);
          }

          // ✅ Store UUID in SharedPreferences
          // final prefs = await SharedPreferences.getInstance();
          // await prefs.setString("uuid", uuid);

          print("User mapped with uuid: $uuid and stored locally");
        } else {
          if (onWrongOtp != null) onWrongOtp();
          Get.snackbar("Error", "Unable to create Supabase user");
        }
      } else {
        if (onWrongOtp != null) onWrongOtp();
        Get.snackbar("Invalid OTP", "The OTP you entered is incorrect.");
      }
    } catch (e) {
      if (onWrongOtp != null) onWrongOtp();
      Get.snackbar("Error", "OTP verification failed: $e");
      print("Error verifying OTP: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
