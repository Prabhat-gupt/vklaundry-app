import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/controllers/login_controller.dart' as laundry_app_login_controller;

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(187, 251, 255, 1),
                  Color.fromRGBO(120, 161, 163, 1),
                  Color.fromRGBO(112, 151, 153, 1),
                ],
              ),
            ),
          ),
          SizedBox.expand(
            child: Image.asset(
              'assets/icons/get_started_image.png',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.all(17.w),
              padding: EdgeInsets.all(17.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(17.w),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Professional Laundry Service at Your Doorstep',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.w,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    'Experience premium garment care with effortless pickup and delivery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.w, color: Colors.black87),
                  ),
                  SizedBox(height: 15.w),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Get.offAllNamed(AppRoutes.LOGIN);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 11.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(87, 104, 171, 1),
                              Color.fromRGBO(35, 42, 69, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(36.w),
                        ),
                        child: Center(
                          child: Text(
                            "Let's Start",
                            style: TextStyle(
                              fontSize: 14.w,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.w),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        final loginController = Get.put(laundry_app_login_controller.LoginController());
                        loginController.continueAsGuest();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 11.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromRGBO(35, 42, 69, 1),
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(36.w),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            "Continue as Guest",
                            style: TextStyle(
                              fontSize: 12.w,
                              color: Color.fromRGBO(35, 42, 69, 1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
