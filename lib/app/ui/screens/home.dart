import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';
import 'package:laundry_app/app/ui/widgets/service_home.dart';
import 'package:laundry_app/app/ui/widgets/special_carousel.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomePageController controller = Get.put(HomePageController());
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  gradient: LinearGradient(
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
                        const Icon(
                          Icons.location_pin,
                          color: Colors.white,
                          size: 35,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(controller.userAddress.value,
                              //     style:
                              //         const TextStyle(color: Colors.white)),
                              // Text(controller.userLocationDetails.value,
                              //     style: const TextStyle(
                              //         color: Colors.white, fontSize: 12)),
                              Text('540\'A, Gowdavally Village',
                                  style: TextStyle(color: Colors.white)),
                              Text('Malkajgiri, Dist-501401',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 30),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.PROFILE),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage:
                                AssetImage('assets/icons/icon_img.png'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for "Services"',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          controller.services.length,
                          (index) {
                            final service = controller.services[index];
                            final iconPath =
                                index < controller.serviceIcons.length
                                    ? controller.serviceIcons[index]
                                    : 'assets/icons/others.png';

                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to ProductListScreen with service name
                                    Get.to(
                                      () => const ProductListScreen(),
                                      arguments: {
                                        'serviceName': service['name'],
                                        'service_id': service['id']
                                      },
                                    );
                                  },
                                  child: ServiceIcon(
                                    icon: iconPath,
                                    label: service['name'] ?? 'Service',
                                  ),
                                ),
                                const SizedBox(width: 15),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 23, left: 18, right: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                  const SpecialCarousel(),
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
        );
      }),
    );
  }
}
