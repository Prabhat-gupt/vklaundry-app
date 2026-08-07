import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:laundry_app/app/controllers/login_controller.dart';
import 'package:laundry_app/app/ui/widgets/terms_conditions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final LoginController loginController = Get.put(LoginController());
  final FocusNode phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // validate phone number length
    phoneController.addListener(() {
      loginController.isPhoneValid.value =
          phoneController.text.trim().length == 10;
    });

    // Auto-focus on phone field to open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    phoneFocusNode.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        horizontal: 17.w,
                        vertical: 29.w,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 29.w),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 19.w,
                            backgroundImage: AssetImage(
                              'assets/icons/app_logo.png',
                            ),
                          ),
                          SizedBox(height: 21.w),
                          Text(
                            'Professional\nLaundry Service\nat Your Doorstep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.w,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 21.w),

                          // phone input
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21.w),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.w,
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                  ),
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(color: Colors.black54),
                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    focusNode: phoneFocusNode,
                                    autofocus: true,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(10),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      fillColor: Colors.white,
                                      hintText: 'Enter Phone Number',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15.w),

                          // ✅ Continue button with loader
                          Obx(() {
                            final isEnabled =
                                loginController.isPhoneValid.value;
                            return GestureDetector(
                              onTap:
                                  isEnabled && !loginController.isLoading.value
                                      ? () async {
                                          String phone =
                                              phoneController.text.trim();
                                          await loginController.sendOtp(phone);
                                        }
                                      : null,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isEnabled
                                      ? LinearGradient(
                                          colors: [
                                            Color.fromRGBO(89, 168, 146, 1),
                                            Color.fromRGBO(60, 113, 98, 1),
                                            Color.fromRGBO(35, 66, 57, 1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [Colors.grey, Colors.grey],
                                        ),
                                  borderRadius: BorderRadius.circular(21.w),
                                ),
                                child: Center(
                                  child: loginController.isLoading.value
                                      ? SizedBox(
                                          height: 15.w,
                                          width: 15.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Continue',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.w,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Container(
                      height: 141.w,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/icons/iron.png'),
                          SizedBox(width: 6.w),
                          Image.asset('assets/icons/hanger.png'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Terms & Conditions footer
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.w),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => const TermsAndConditionsPage());
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By continuing, you agree to our \n',
                        style: TextStyle(color: Colors.white, fontSize: 11.w),
                        children: [
                          TextSpan(
                            text: 'Terms of Use',
                            style: TextStyle(
                              color: Color.fromRGBO(89, 168, 146, 1),
                              decoration: TextDecoration.underline,
                              fontSize: 11.w,
                            ),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color.fromRGBO(89, 168, 146, 1),
                              decoration: TextDecoration.underline,
                              fontSize: 11.w,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 15.w,
                child: TextButton(
                  onPressed: () {
                    loginController.continueAsGuest();
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
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
}
