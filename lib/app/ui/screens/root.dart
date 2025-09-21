import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:laundry_app/app/ui/screens/all_orders.dart';
import 'package:laundry_app/app/ui/screens/home.dart';
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
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ServiceScreen(),
    AllOrdersPage(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: Colors.white,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.home_outlined,
                      color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                    ),
                    label: 'Home',
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(35, 42, 69, 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home, color: Colors.white),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.category_outlined,
                      color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                    ),
                    label: 'Services',
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(35, 42, 69, 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category, color: Colors.white),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                    ),
                    label: 'Booking',
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(35, 42, 69, 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: _selectedIndex == 3 ? Colors.white : Colors.grey,
                    ),
                    label: 'Setting',
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(35, 42, 69, 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: const Color.fromRGBO(35, 42, 69, 1),
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                onTap: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}