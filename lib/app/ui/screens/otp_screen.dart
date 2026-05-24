import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();

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

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      Get.snackbar(
        '⚠️ OTP Required',
        'Please enter the OTP sent to your phone.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF57C00),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12,
        icon: Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }
    if (otp.length < 6) {
      _errorController.add(ErrorAnimationType.shake);
      Get.snackbar(
        '⚠️ Incomplete OTP',
        'Please enter all 6 digits of the OTP.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF57C00),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12,
        icon: Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }
    _timer?.cancel();
    loginController.verifyOtp(
      phoneNumber,
      otp,
      onWrongOtp: () {
        if (mounted) {
          _errorController.add(ErrorAnimationType.shake);
          _otpController.clear();
          _startTimer();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    try {
      _otpController.dispose();
    } catch (e) {
      // Controller already disposed
    }
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
              decoration: BoxDecoration(
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 20.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Get.back(),
                                ),
                                SizedBox(height: 40.h),
                                Text(
                                  'OTP\nVerification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'OTP has been sent to +91 $phoneNumber',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 30.h),

                                // ✅ PIN CODE FIELD
                                PinCodeTextField(
                                  appContext: context,
                                  length: 6,
                                  controller: _otpController,
                                  autoFocus: true,
                                  keyboardType: TextInputType.number,
                                  cursorColor: AppTheme.primaryColor,
                                  animationType: AnimationType.fade,
                                  errorAnimationController: _errorController,
                                  errorAnimationDuration: 300,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(8.r),
                                    fieldHeight: 50,
                                    fieldWidth: 45,
                                    activeFillColor: Colors.white,
                                    selectedFillColor: Colors.white,
                                    inactiveFillColor: Colors.white,
                                    activeColor: Colors.blue,
                                    selectedColor: Colors.blue,
                                    inactiveColor: Colors.grey,
                                    errorBorderColor: Colors.red,
                                  ),
                                  enableActiveFill: true,
                                  backgroundColor: Colors.transparent,
                                  onChanged: (value) {},
                                  onCompleted: (value) => _verifyOtp(),
                                ),

                                SizedBox(height: 20.h),
                                Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '00:${_seconds.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25.sp,
                                        ),
                                      ),
                                      SizedBox(height: 14.h),
                                      Text(
                                        "Didn't get it?",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                      SizedBox(height: 18.h),
                                      TextButton(
                                        onPressed: _seconds == 0
                                            ? () {
                                                loginController.sendOtp(
                                                  phoneNumber,
                                                );
                                                _startTimer();
                                              }
                                            : null,
                                        child: Row(
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
                                              size: 20.sp,
                                            ),
                                            SizedBox(width: 6.w),
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
                        padding: EdgeInsets.only(bottom: 16.0.h),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => const TermsAndConditionsPage());
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'By continuing, you agree to our \n',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: TextStyle(
                                    color: Color.fromRGBO(89, 168, 146, 1),
                                    decoration: TextDecoration.underline,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color.fromRGBO(89, 168, 146, 1),
                                    decoration: TextDecoration.underline,
                                    fontSize: 14.sp,
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
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }
}
