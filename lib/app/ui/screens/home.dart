import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/testimonials_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';
import 'package:laundry_app/app/ui/widgets/order_card.dart';
import 'package:laundry_app/app/ui/widgets/special_carousel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomePageController controller = Get.put(HomePageController());
  final TrackOrderController orderTrackController =
      Get.put(TrackOrderController());
  final productListController = Get.find<ProductListController>();
  final testimonialsController = Get.put(TestimonialsController());

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      int userId = await controller.fetchUserDetails();
      await orderTrackController.fetchOrderDetails(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Obx(() {
        bool isLoading =
            controller.isLoading.value || orderTrackController.isLoading.value;
        return Skeletonizer(
          enabled: isLoading,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 54),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5768AB),
                        Color(0xFF232F46),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(44),
                      bottomRight: Radius.circular(44),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_pin,
                                color: Colors.white, size: 30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Obx(() {
                                if (controller.userAddress.isEmpty) {
                                  return const Text(
                                    'No address found',
                                    style: TextStyle(color: Colors.white),
                                  );
                                }
                                final address = controller.userAddress[0];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      address['address_line'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      '${address['city'] ?? ''}, ${address['landmark_pincode'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                );
                              }),
                            ),

                            // GestureDetector(
                            //   onTap: () => Get.toNamed(AppRoutes.NOTIFICATION),
                            //   child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28)),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.PROFILE),
                              child: const CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage: AssetImage(
                                    'assets/icons/setting_profile.png'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Our Services',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
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

                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => const ProductListScreen(),
                                      arguments: {
                                        'serviceName': service['name'],
                                        'service_id': service['id']
                                      },
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Image.asset(iconPath,
                                              height: 30, width: 30),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(service['name'] ?? 'Service',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('#SpecialForYou',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      // Row(
                      //   children: [
                      //     Text('See all',
                      //         style: TextStyle(
                      //             fontSize: 14,
                      //             fontWeight: FontWeight.w500,
                      //             color: Colors.blue)),
                      //     Icon(Icons.chevron_right,
                      //         color: Colors.blue, size: 22),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const SpecialCarousel(),
                const SizedBox(height: 24),
                _buildActiveOrdersSection(context, orderTrackController),
                _buildTestimonialsSection(testimonialsController),
                const SizedBox(height: 64),
              ],
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          Obx(() => productListController.getTotalCartItems() > 0
              ? Container(
                  margin: const EdgeInsets.all(16),
                  height: 50,
                  width: 250,
                  decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(32)),
                  child: InkWell(
                    onTap: () {
                      final selectedItems =
                          productListController.getSelectedCartItems();
                      Navigator.pushNamed(context, '/checkout_page',
                          arguments: {
                            'selectedItems': selectedItems,
                          });
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text("View Cart",
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white,
                            child: Text(
                                productListController
                                    .getTotalCartItems()
                                    .toString(),
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
    );
  }
}

Widget _buildTestimonialsSection(testimonialsController) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.0),
        child: Text(
          'What Our Customers Say',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 160,
        child: Obx(() {
          // if (testimonialsController.testimonials.isEmpty) {
          //   return const Center(child: CircularProgressIndicator());
          // }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: testimonialsController.testimonials.length,
            itemBuilder: (context, index) {
              final testimonial = testimonialsController.testimonials[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(testimonial['customer_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(testimonial['customer_feedback']),
                  ],
                ),
              );
            },
          );
        }),
      ),
    ],
  );
}

Widget _buildActiveOrdersSection(
    BuildContext context, TrackOrderController orderTrackController) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 18, color: Colors.blueGrey),
                SizedBox(width: 6),
                Text('Recent Bookings',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            // GestureDetector(
            //   onTap: () {
            //     Get.toNamed(AppRoutes.ALLORDERS);
            //   },
            //   child: const Row(
            //     children: [
            //       Text('View All', style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500, decorationColor: Colors.blue)),
            //       Icon(Icons.chevron_right, color: Colors.blue, size: 22),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Obx(() {
          final ordersData = orderTrackController.order['orders'] ?? [];
          if (ordersData.isEmpty) {
            return const Text("No orders found");
          }
          return OrderCard(
              orders: List<Map<String, dynamic>>.from(
                  orderTrackController.order['orders'] ?? []),
              numbersOrders: 2);
        }),
      )
    ],
  );
}
