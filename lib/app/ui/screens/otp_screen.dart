import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return StatefulBuilder(
          builder: (context, setStateBox) {
            return Container(
              width: 40,
              // height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: _otpControllers[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _otpControllers[index].text.isNotEmpty ? Color.fromRGBO(187, 251, 255, 1) : Colors.white,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // update parent
                  setStateBox(() {}); // update this box
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                  // If all boxes are filled, navigate to home
                  bool allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
                  if (allFilled) {
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (mounted) Get.offAllNamed('/root');
                    });
                  }
                },
              ),
            );
          },
        );
      }),
    );
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
                          horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              Get.back();
                            },
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
                          const Text(
                            'OTP has been sent to +91 7909870317',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildOtpFields(),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '00:${_seconds.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 25),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  "Didn't get it?",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                const SizedBox(height: 18),
                                TextButton(
                                  onPressed: _seconds == 0 ? _startTimer : null,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sms_outlined, color: Color.fromRGBO(89, 168, 146, 1), size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        'Send OTP(SMS)',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
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
                    // const SizedBox(height: 60),
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
