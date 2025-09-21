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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final HomePageController controller = Get.put(HomePageController());
  final TrackOrderController orderTrackController = Get.put(
    TrackOrderController(),
  );
  final productListController = Get.find<ProductListController>();
  final testimonialsController = Get.put(TestimonialsController());

  // Animation controllers
  late final AnimationController _headerController;
  late final Animation<Offset> _headerSlideAnimation;

  late final AnimationController _servicesController;
  late final Animation<Offset> _servicesSlideAnimation;

  late final AnimationController _bodyController;
  late final Animation<double> _bodyOpacityAnimation;

  late final AnimationController _fabController;
  late final Animation<double> _fabPulseAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _servicesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _servicesSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _servicesController,
      curve: Curves.bounceOut,
    ));

    _bodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _bodyOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bodyController,
        curve: Curves.easeIn,
      ),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..repeat(reverse: true);
    _fabPulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _headerController.forward();
      _servicesController.forward();
      _bodyController.forward();

      dynamic userId = await controller.fetchUserDetails();
      await orderTrackController.fetchOrderDetails(userId);
      if (orderTrackController.order.value['orders'] != null &&
          orderTrackController.order.value['orders'].isNotEmpty) {
        for (var order in orderTrackController.order.value['orders']) {
          final orderId = order['id'] as int;
          orderTrackController.subscribeToOrderChanges(orderId);
        }
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _servicesController.dispose();
    _bodyController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  String _formatServiceName(String name, {int maxLength = 12}) {
    if (name.length <= maxLength) return name;
    return name.substring(0, maxLength) + " . . .";
  }

  @override
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
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5768AB), Color(0xFF232F46)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header content with slide-down animation
                      SlideTransition(
                        position: _headerSlideAnimation,
                        child: FadeTransition(
                          opacity: _headerController,
                          // Use the controller itself, it works for this!
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_pin,
                                  color: Colors.white,
                                  size: 30,
                                ),
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                          '${address['city'] ??
                                              ''}, ${address['landmark_pincode'] ??
                                              ''}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => Get.toNamed(AppRoutes.PROFILE),
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    backgroundImage: AssetImage(
                                      'assets/icons/setting_profile.png',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // "Our Services" text with fade-in animation
                      FadeTransition(
                        opacity: _servicesController,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Our Services',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Service Icons with slide-up and bounce animation
                      SlideTransition(
                        position: _servicesSlideAnimation,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: List.generate(
                                controller.services.length,
                                    (index) {
                                  final service = controller.services[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.to(
                                              () => const ProductListScreen(),
                                          arguments: {
                                            'serviceName': service['name'],
                                            'service_id': service['id'],
                                          },
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                service['image_url'],
                                                fit: BoxFit.cover,
                                                height: 60,
                                                width: 60,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatServiceName(
                                              service['name'] ?? 'Service',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main body content with staggered animations
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _bodyController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _bodyOpacityAnimation.value,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _bodyController,
                          curve: const Interval(
                              0.0, 0.8, curve: Curves.easeOut),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18.0),
                              child: Text(
                                '#SpecialForYou',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SpecialCarousel(),
                            const SizedBox(height: 24),
                            // Staggered animation for recent bookings
                            AnimatedBuilder(
                              animation: _bodyController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: _bodyController,
                                    curve: const Interval(0.3, 1.0,
                                        curve: Curves.easeIn),
                                  ))
                                      .value,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _bodyController,
                                      curve: const Interval(0.3, 1.0,
                                          curve: Curves.easeOut),
                                    )),
                                    child: _buildActiveOrdersSection(
                                        context, orderTrackController),
                                  ),
                                );
                              },
                            ),
                            // Staggered animation for testimonials
                            AnimatedBuilder(
                              animation: _bodyController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: _bodyController,
                                    curve: const Interval(0.5, 1.0,
                                        curve: Curves.easeIn),
                                  ))
                                      .value,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _bodyController,
                                      curve: const Interval(0.5, 1.0,
                                          curve: Curves.easeOut),
                                    )),
                                    child: _buildTestimonialsSection(
                                        testimonialsController),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(
            () =>
        productListController.getTotalCartItems() > 0
            ? Container(
              margin: const EdgeInsets.all(16),
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  )
                ],
              ),
              child: InkWell(
                onTap: () {
                  final selectedItems =
                  productListController.getSelectedCartItems();
                  Navigator.pushNamed(
                    context,
                    '/checkout_page',
                    arguments: {'selectedItems': selectedItems},
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        "View Cart",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          productListController
                              .getTotalCartItems()
                              .toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            : const SizedBox.shrink(),
      ),
    );
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
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: testimonialsController.testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonialsController.testimonials[index];
                return Container(
                  width: 260,
                  margin: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial['customer_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildActiveOrdersSection(BuildContext context,
      TrackOrderController orderTrackController,) {
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
                  Text(
                    'Recent Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Obx(() {
            final ordersData = List<Map<String, dynamic>>.from(
              orderTrackController.order['orders'] ?? [],
            );

            if (ordersData.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Image.network(
                      "https://cdn-icons-png.flaticon.com/512/4076/4076503.png",
                      height: 120,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No recent bookings found",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }

            ordersData.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
              final dateB =
                  DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });

            final recentOrders = ordersData.take(2).toList();
            print("my orders data is ::::: ${ordersData}");
            return OrderCard(
              orders: recentOrders,
              numbersOrders: recentOrders.length,
            );
          }),
        ),
      ],
    );
  }
}