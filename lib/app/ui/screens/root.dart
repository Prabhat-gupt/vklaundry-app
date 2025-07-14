import 'package:flutter/material.dart';
import 'package:laundry_app/app/ui/screens/category.dart';
import 'package:laundry_app/app/ui/screens/home.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    // Text('Index 0: Home', style: optionStyle),
    // Text('Index 1: Business', style: optionStyle),
    // Text('Index 2: School', style: optionStyle),
    HomeScreen(),
    CategoryScreen(),
    HomeScreen(),
    HomeScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color.fromRGBO(35, 42, 69, 1),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home',backgroundColor: Colors.white),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Category',backgroundColor: Colors.white),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School',backgroundColor: Colors.white),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Person',backgroundColor: Colors.white),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromRGBO(35, 42, 69, 1),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}