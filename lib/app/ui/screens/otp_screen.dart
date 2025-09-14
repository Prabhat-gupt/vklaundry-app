import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/login_controller.dart';
import 'package:laundry_app/app/ui/widgets/terms_conditions.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int _seconds = 60;
  Timer? _timer;
  late String phoneNumber;
  final LoginController loginController = Get.put(LoginController());
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    phoneNumber = Get.arguments['phone'] ?? '';
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _seconds--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(87, 104, 171, 1),
                    Color.fromRGBO(35, 47, 70, 1),
                    Color.fromRGBO(35, 42, 69, 1),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Get.back(),
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'OTP\nVerification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'OTP has been sent to +91 $phoneNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // ✅ PIN CODE FIELD
                                PinCodeTextField(
                                  appContext: context,
                                  length: 6,
                                  controller: _otpController,
                                  autoFocus: true,
                                  keyboardType: TextInputType.number,
                                  cursorColor: AppTheme.primaryColor,
                                  animationType: AnimationType.fade,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(8),
                                    fieldHeight: 50,
                                    fieldWidth: 45,
                                    activeFillColor: Colors.white,
                                    selectedFillColor: Colors.white,
                                    inactiveFillColor: Colors.white,
                                    activeColor: Colors.blue,
                                    selectedColor: Colors.blue,
                                    inactiveColor: Colors.grey,
                                  ),
                                  enableActiveFill: true,
                                  backgroundColor: Colors.transparent,
                                  onChanged: (value) {
                                    if (value.length == 6) {
                                      loginController.verifyOtp(
                                        phoneNumber,
                                        value,
                                        onWrongOtp: () {
                                          if (mounted) {
                                            _otpController.clear();
                                          }
                                        },
                                      );
                                    }
                                  },
                                ),

                                const SizedBox(height: 20),
                                Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '00:${_seconds.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        "Didn't get it?",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      TextButton(
                                        onPressed: _seconds == 0
                                            ? () {
                                                loginController.sendOtp(
                                                  phoneNumber,
                                                );
                                                _startTimer();
                                              }
                                            : null,
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.sms_outlined,
                                              color: Color.fromRGBO(
                                                89,
                                                168,
                                                146,
                                                1,
                                              ),
                                              size: 20,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Send OTP(SMS)',
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image.asset('assets/icons/iron.png'),
                              Image.asset('assets/icons/hanger.png'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => const TermsAndConditionsPage());
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              text: 'By continuing, you agree to our \n',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: TextStyle(
                                    color: Color.fromRGBO(89, 168, 146, 1),
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color.fromRGBO(89, 168, 146, 1),
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ LOADING OVERLAY
          if (loginController.isLoading.value)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }
}
