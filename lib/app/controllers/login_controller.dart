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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Check if user address is within service area
  Future<bool> _checkServiceAvailability(int userId) async {
    try {
      print("🔍 Checking service for user ID: $userId");

      final addressResponse = await supabase
          .from('addresses')
          .select('latitude, longitude')
          .eq('id', userId)
          .limit(1);

      print("📍 Address response: $addressResponse");

      if (addressResponse.isEmpty) {
        print("⚠️ No address found, allowing navigation");
        return true; // No address yet, allow navigation
      }

      final address = addressResponse.first;
      final latValue = address['latitude'];
      final lonValue = address['longitude'];

      print("🗺️ Coordinates: lat=$latValue, lon=$lonValue");

      if (latValue == null || lonValue == null) {
        print("⚠️ No coordinates found, allowing navigation");
        return true; // No coordinates, allow navigation
      }

      final lat = (latValue as num).toDouble();
      final lon = (lonValue as num).toDouble();

      // Service center coordinates
      const centerLat = 17.608400;
      const centerLon = 78.466200;
      const serviceRadiusKm = 10.0;

      // Calculate distance
      final distance = _calculateDistance(centerLat, centerLon, lat, lon);

      print(
          "📏 Distance from service center: ${distance.toStringAsFixed(2)} km");

      final isAvailable = distance <= serviceRadiusKm;
      print("✅ Service ${isAvailable ? 'available' : 'NOT available'}");

      return isAvailable;
    } catch (e) {
      print("❌ Service check error: $e");
      return true; // On error, allow navigation
    }
  }

  Future<double?> _getDistanceFromServiceCenter(int userId) async {
    try {
      final addressResponse = await supabase
          .from('addresses')
          .select('latitude, longitude')
          .eq('id', userId)
          .limit(1);

      if (addressResponse.isEmpty) {
        return null;
      }

      final address = addressResponse.first;
      final latValue = address['latitude'];
      final lonValue = address['longitude'];

      if (latValue == null || lonValue == null) {
        return null;
      }

      final lat = (latValue as num).toDouble();
      final lon = (lonValue as num).toDouble();

      const centerLat = 17.608400;
      const centerLon = 78.466200;

      return _calculateDistance(centerLat, centerLon, lat, lon);
    } catch (e) {
      return null;
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
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
        "&sms=${otp} is your OTP to login to vklaundry. DO NOT share with anyone. - ps"
        "&templateid=1407176828454812786",
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

  // Future<void> verifyOtp(
  //   String phone,
  //   String enteredOtp, {
  //   VoidCallback? onWrongOtp,
  // }) async {
  //   isLoading.value = true;
  //   try {
  //     if (lastOtp == null) {
  //       Get.snackbar("Error", "OTP not generated. Please request again.");
  //       return;
  //     }

  //     if (enteredOtp == lastOtp) {
  //       // ✅ Create / fetch Supabase user anonymously
  //       final authResponse = await supabase.auth.signInAnonymously();
  //       final user = authResponse.user;

  //       if (user != null) {
  //         final uuid = user.id;
  //         final phoneNumber = '+91$phone';

  //         // ✅ Check if user exists in custom "users" table
  //         final existingUser = await supabase
  //             .from('users')
  //             .select()
  //             .eq('uuid', uuid)
  //             .maybeSingle();

  //         if (existingUser == null) {
  //           // New user → insert
  //           await supabase.from('users').insert({
  //             'uuid': uuid,
  //             'phone': phoneNumber,
  //           });
  //           Get.offAllNamed(AppRoutes.SETUPSCREEN);
  //         } else {
  //           // Existing user → go to home
  //           Get.offAllNamed(AppRoutes.ROOT);
  //         }

  //         // ✅ Store UUID in SharedPreferences
  //         // final prefs = await SharedPreferences.getInstance();
  //         // await prefs.setString("uuid", uuid);

  //         print("User mapped with uuid: $uuid and stored locally");
  //       } else {
  //         if (onWrongOtp != null) onWrongOtp();
  //         Get.snackbar("Error", "Unable to create Supabase user");
  //       }
  //     } else {
  //       if (onWrongOtp != null) onWrongOtp();
  //       Get.snackbar("Invalid OTP", "The OTP you entered is incorrect.");
  //     }
  //   } catch (e) {
  //     if (onWrongOtp != null) onWrongOtp();
  //     Get.snackbar("Error", "OTP verification failed: $e");
  //     print("Error verifying OTP: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  Future<void> verifyOtp(
    String phone,
    String enteredOtp, {
    VoidCallback? onWrongOtp,
  }) async {
    isLoading.value = true;
    try {
      if (lastOtp == null) {
        Get.snackbar("Error", "OTP not generated. Please request again.");
        return;
      }

      if (enteredOtp == lastOtp) {
        final phoneNumber = '+91$phone';

        // ✅ First check if user already exists with this phone
        final existingUser = await supabase
            .from('users')
            .select()
            .eq('phone', phoneNumber)
            .maybeSingle();

        if (existingUser != null) {
          // 👤 Existing user → just login
          print("👤 Existing user logged in: $existingUser");

          // store in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final userId = existingUser['id'] as int?;

          if (userId == null) {
            Get.snackbar("Error", "User ID not found");
            return;
          }

          await prefs.setInt('user_id', userId);
          await prefs.setBool('isLoggedIn', true);

          // Check service availability before navigation
          final isServiceAvailable = await _checkServiceAvailability(userId);

          if (!isServiceAvailable) {
            final distance = await _getDistanceFromServiceCenter(userId) ?? 0.0;
            Get.off(
              () => ServiceNotAvailableScreen(distance: distance),
            );
            return;
          }

          Get.offAllNamed(AppRoutes.ROOT);
        } else {
          // 🆕 New user → create user without anonymous auth
          // Generate a proper UUID v4 format
          final uuid = _generateUuid();

          final inserted = await supabase
              .from('users')
              .insert({'uuid': uuid, 'phone': phoneNumber})
              .select()
              .single();

          print("🆕 New user created: $inserted");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', inserted['id']);
          await prefs.setBool('isLoggedIn', true);

          Get.offAllNamed(AppRoutes.SETUPSCREEN);
        }
      } else {
        // ❌ Wrong OTP entered
        if (onWrongOtp != null) onWrongOtp();
        Get.snackbar(
          "❌ Invalid OTP",
          "The OTP you entered is incorrect. Please try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }

      //   if (existingUser != null) {
      //     // 👤 User already exists → just login (no new account)
      //     print("👤 Existing user logged in: $existingUser");

      //     storages.write("userId", existingUser['id']);

      //     Get.offAllNamed(AppRoutes.ROOT);
      //   } else {
      //     // 🆕 New user → create Supabase auth user and insert into table
      //     final authResponse = await supabase.auth.signInAnonymously();
      //     final user = authResponse.user;

      //     if (user != null) {
      //       final uuid = user.id;

      //       await supabase.from('users').insert({
      //         'uuid': uuid,
      //         'phone': phoneNumber,
      //       });

      //       print(
      //         "🆕 New user created with uuid: $uuid and phone: $phoneNumber",
      //       );
      //       Get.offAllNamed(AppRoutes.SETUPSCREEN);
      //     } else {
      //       if (onWrongOtp != null) onWrongOtp();
      //       Get.snackbar("Error", "Unable to create Supabase user");
      //     }
      //   }
      // } else {
      //   if (onWrongOtp != null) onWrongOtp();
      //   Get.snackbar("Invalid OTP", "The OTP you entered is incorrect.");
      // }
    } catch (e) {
      if (onWrongOtp != null) onWrongOtp();
      Get.snackbar("Error", "OTP verification failed: $e");
      print("❌ Error verifying OTP: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Generate a simple UUID v4 compatible string
  String _generateUuid() {
    final random = Random();
    String hex() => random.nextInt(16).toRadixString(16);

    return '${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}-'
        '${hex()}${hex()}${hex()}${hex()}-'
        '4${hex()}${hex()}${hex()}-'
        '${(random.nextInt(4) + 8).toRadixString(16)}${hex()}${hex()}${hex()}-'
        '${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}${hex()}';
  }
}
