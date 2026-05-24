import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/testimonials_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';
import 'package:laundry_app/app/ui/screens/service_not_available_screen.dart';
import 'package:laundry_app/app/ui/widgets/order_card.dart';
import 'package:laundry_app/app/ui/widgets/special_carousel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final HomePageController controller = Get.put(HomePageController());
  final TrackOrderController orderTrackController = Get.put(
    TrackOrderController(),
  );
  final productListController = Get.find<ProductListController>();
  final testimonialsController = Get.put(TestimonialsController());

  @override
  bool get wantKeepAlive => true;

  // Animation controllers
  late final AnimationController _headerController;
  late final Animation<Offset> _headerSlideAnimation;

  late final AnimationController _servicesController;
  late final Animation<Offset> _servicesSlideAnimation;

  late final AnimationController _bodyController;
  late final Animation<double> _bodyOpacityAnimation;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _headerController.forward();
      _servicesController.forward();
      _bodyController.forward();

      // Wait for user details to be fetched, then get orders
      dynamic userId = await controller.fetchUserDetailsNullable();
      if (userId != null) {
        await orderTrackController.fetchOrderDetails(userId);
        // Setup real-time updates for all orders
        orderTrackController.subscribeToAllUserOrders(userId);
      } else {
        // If guest, stop loading on order track controller
        orderTrackController.isLoading.value = false;
      }
    });
  }

  @override
  void dispose() {
    orderTrackController.unsubscribeFromOrderChanges();
    _headerController.dispose();
    _servicesController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _formatServiceName(String name, {int maxLength = 12}) {
    if (name.length <= maxLength) return name;
    return name.substring(0, maxLength) + " . . .";
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Obx(() {
        bool isLoading =
            controller.isLoading.value || orderTrackController.isLoading.value;
        return Skeletonizer(
          enabled: isLoading,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HEADER ───────────────────────────────────────────────
                _buildHeader(),
                // ─── BODY ─────────────────────────────────────────────────
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _bodyController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _bodyOpacityAnimation.value,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _bodyController,
                          curve:
                              const Interval(0.0, 0.8, curve: Curves.easeOut),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service availability warning
                            Obx(() {
                              if (!controller.isServiceAvailable.value) {
                                return _buildServiceWarning();
                              }
                              return const SizedBox.shrink();
                            }),

                            // ─── SUBSCRIPTIONS SECTION ─────────────────
                            _buildSectionHeader(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFB800),
                              title: 'Subscription',
                              subtitle: 'Exclusive subscription plans for you',
                            ),
                            const SizedBox(height: 12),
                            const SpecialCarousel(),
                            const SizedBox(height: 24),

                            // ─── RECENT BOOKINGS ───────────────────────
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
                                      begin: const Offset(0, 0.15),
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

                            // ─── TESTIMONIALS ──────────────────────────
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
                                      begin: const Offset(0, 0.15),
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
                            const SizedBox(height: 100),
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
        () => productListController.getTotalCartItems() > 0
            ? Container(
                  margin: const EdgeInsets.all(16),
                  height: 56,
                  width: 260,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5768AB), Color(0xFF232F46)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5768AB).withOpacity(0.5),
                        blurRadius: 16.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
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
                          const Icon(Icons.shopping_cart_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            "View Cart",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              productListController
                                  .getTotalCartItems()
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 55, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x553D52A0),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TOP ROW: greeting + avatar ───────────────────────────────
          SlideTransition(
            position: _headerSlideAnimation,
            child: FadeTransition(
              opacity: _headerController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Location pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Color(0xFF7ECBFF), size: 16),
                          const SizedBox(width: 5),
                          Obx(() {
                            if (controller.userAddress.isEmpty) {
                              return const Text(
                                'No address',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              );
                            }
                            final address = controller.userAddress[0];
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                '${address['address_line'] ?? ''}, ${address['city'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Profile avatar
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.PROFILE),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(
                            'assets/icons/setting_profile.png',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── GREETING ─────────────────────────────────────────────────
          SlideTransition(
            position: _headerSlideAnimation,
            child: FadeTransition(
              opacity: _headerController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} 👋',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fresh & Clean,\nJust a tap away!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── SERVICE ICONS ────────────────────────────────────────────
          FadeTransition(
            opacity: _servicesController,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SlideTransition(
                    position: _servicesSlideAnimation,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          controller.services.length,
                          (index) {
                            final service = controller.services[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
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
                                    // Glassmorphism circle
                                    Container(
                                      height: 68,
                                      width: 68,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          service['image_url'],
                                          fit: BoxFit.cover,
                                          height: 68,
                                          width: 68,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.local_laundry_service, color: Colors.white, size: 32),
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
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceWarning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade600,
              Colors.deepOrange.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Not Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'We currently don\'t serve your area. Available within 10km of our center.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(testimonialsController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.format_quote_rounded,
          iconColor: const Color(0xFF9C6FFF),
          title: 'Customer Reviews',
          subtitle: 'What our customers say',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 175,
          child: Obx(() {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 18),
              itemCount: testimonialsController.testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonialsController.testimonials[index];
                final name = (testimonial['customer_name'] ?? 'A') as String;
                final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

                // Varied card accent colors
                final accentColors = [
                  const Color(0xFF5768AB),
                  const Color(0xFF9C6FFF),
                  const Color(0xFF2DC9B7),
                  const Color(0xFFFF6B6B),
                ];
                final accent = accentColors[index % accentColors.length];

                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 14, bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border(
                      left: BorderSide(color: accent, width: 3.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: accent.withOpacity(0.15),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1A2340),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Star rating
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFB800), size: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Icon(Icons.format_quote,
                          color: Color(0xFFCCCCCC), size: 16),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          testimonial['customer_feedback'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildActiveOrdersSection(
    BuildContext context,
    TrackOrderController orderTrackController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF2DC9B7),
          title: 'Recent Bookings',
          subtitle: 'Your latest laundry orders',
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Obx(() {
            if (controller.isGuestMode.value) {
              return _buildGuestLoginPrompt();
            }

            final ordersData = List<Map<String, dynamic>>.from(
              orderTrackController.order['orders'] ?? [],
            );

            if (ordersData.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DC9B7).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inbox_rounded,
                        size: 40,
                        color: Color(0xFF2DC9B7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "No recent bookings",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A2340),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Place your first order and\nwe'll handle the rest!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGuestLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5768AB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              size: 40,
              color: Color(0xFF5768AB),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Track Your Orders",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF1A2340),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Sign in to view your recent\nlaundry bookings.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5768AB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              "Login / Sign Up",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
