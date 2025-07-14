import 'package:flutter/material.dart';
import 'package:laundry_app/app/ui/widgets/service_home.dart';
import 'package:laundry_app/app/ui/widgets/special_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(87, 104, 171, 1),
                    Color.fromRGBO(35, 47, 70, 1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: Colors.white,
                        size: 35,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('540\'A, Gowdavally Village',
                                style: TextStyle(color: Colors.white)),
                            Text('Malkajgiri, Dist-501401',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 30),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage:
                            AssetImage('assets/icons/icon_img.png'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for "shirt"',
                      fillColor: Colors.white,
                      filled: true,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        ServiceIcon(
                            icon: 'assets/icons/dry_wash.png',
                            label: 'Dry Cleaning'),
                        SizedBox(width: 15),
                        ServiceIcon(
                            icon: 'assets/icons/steam_iron.png',
                            label: 'Steam Ironing'),
                        SizedBox(width: 15),
                        ServiceIcon(
                            icon: 'assets/icons/wash.png', label: 'Wash'),
                        SizedBox(width: 15),
                        ServiceIcon(
                            icon: 'assets/icons/home_iron.png', label: 'Iron'),
                        SizedBox(width: 15),
                        ServiceIcon(
                            icon: 'assets/icons/wash_fold.png',
                            label: 'Wash & Fold'),
                        SizedBox(width: 15),
                        ServiceIcon(
                            icon: 'assets/icons/others.png', label: 'Other'),
                        SizedBox(width: 15),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                   padding: const EdgeInsets.only(top: 23, left: 18, right: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("#SpecialForYou",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("See all",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SpecialCarousel(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Orders/Reviews/How to use",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


