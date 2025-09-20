import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();

    // validate phone number length
    phoneController.addListener(() {
      loginController.isPhoneValid.value =
          phoneController.text.trim().length == 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        vertical: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            backgroundImage: AssetImage(
                              'assets/icons/app_logo.png',
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Professional\nLaundry Service\nat Your Doorstep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // phone input
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(color: Colors.black54),
                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(10),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      fillColor:Colors.white,
                                      hintText: 'Enter Phone Number',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isEnabled
                                      ? const LinearGradient(
                                          colors: [
                                            Color.fromRGBO(89, 168, 146, 1),
                                            Color.fromRGBO(60, 113, 98, 1),
                                            Color.fromRGBO(35, 66, 57, 1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Colors.grey, Colors.grey],
                                        ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: loginController.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
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
                      height: 200,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/icons/iron.png'),
                          const SizedBox(width: 8),
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
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => const TermsAndConditionsPage());
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'By continuing, you agree to our \n',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
    );
  }
}
