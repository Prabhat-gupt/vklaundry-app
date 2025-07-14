import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();

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
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Skip >',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 28,
                              backgroundImage:
                                  AssetImage('assets/icons/app_logo.png'),
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
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      '+91',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
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
                                        hintText: 'Enter Phone Number',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                // Handle continue button
                                Get.toNamed(AppRoutes.OTPSCREEN);
                              },
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromRGBO(89, 168, 146, 1),
                                      Color.fromRGBO(60, 113, 98, 1),
                                      Color.fromRGBO(35, 66, 57, 1)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 200,
                      width: double.infinity,
                      // decoration: BoxDecoration(
                      //   border: Border.all(
                      //     color: Colors.blue,
                      //     width: 2.0,
                      //   ),
                      // ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/iron.png',
                            // width: 24,
                            // height: 24,
                          ),
                          SizedBox(width: 8),
                          Image.asset(
                            'assets/icons/hanger.png',
                            // width: 154,
                            // height: 224,
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 80), // Add space so content doesn't hide behind disclaimer
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
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
                              fontSize: 14),
                        ),
                        TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                              color: Color.fromRGBO(89, 168, 146, 1),
                              decoration: TextDecoration.underline,
                              fontSize: 14),
                        ),
                      ],
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
