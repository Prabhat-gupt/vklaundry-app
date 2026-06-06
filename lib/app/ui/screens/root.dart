import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:laundry_app/app/ui/screens/all_orders.dart';
import 'package:laundry_app/app/ui/screens/home.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:laundry_app/app/ui/screens/services.dart';
import 'package:laundry_app/app/ui/screens/setting_screen.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final ProfileController profileController = Get.put(ProfileController());
  final controller = Get.put(ProductListController());
  final HomePageController homeController = Get.put(HomePageController());

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ServiceScreen(),
    AllOrdersPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = homeController.currentNavIndex.value;
      return PopScope(
        canPop: selectedIndex == 0,
        onPopInvoked: (didPop) {
          if (!didPop && selectedIndex != 0) {
            homeController.currentNavIndex.value = 0;
          }
        },
        child: UpgradeAlert(
          showIgnore: false,
          showLater: false,
          showReleaseNotes: true,
          upgrader: Upgrader(
            durationUntilAlertAgain: const Duration(days: 1),
          ),
          child: Scaffold(
            body: IndexedStack(
              index: selectedIndex,
              children: _widgetOptions,
            ),
            bottomNavigationBar: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.home_outlined,
                          color: selectedIndex == 0 ? Colors.white : Colors.grey,
                        ),
                        label: 'Home',
                        activeIcon: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(35, 42, 69, 1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.home, color: Colors.white),
                        ),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.category_outlined,
                          color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        ),
                        label: 'Services',
                        activeIcon: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(35, 42, 69, 1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.category, color: Colors.white),
                        ),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.receipt_long_outlined,
                          color: selectedIndex == 2 ? Colors.white : Colors.grey,
                        ),
                        label: 'Booking',
                        activeIcon: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(35, 42, 69, 1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(Icons.receipt_long, color: Colors.white),
                        ),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: selectedIndex == 3 ? Colors.white : Colors.grey,
                        ),
                        label: 'Setting',
                        activeIcon: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(35, 42, 69, 1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.settings, color: Colors.white),
                        ),
                      ),
                    ],
                    currentIndex: selectedIndex,
                    selectedItemColor: const Color.fromRGBO(35, 42, 69, 1),
                    unselectedItemColor: Colors.grey,
                    showUnselectedLabels: true,
                    onTap: (index) =>
                        homeController.currentNavIndex.value = index,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
