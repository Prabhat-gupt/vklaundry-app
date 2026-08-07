import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      duration: Duration(milliseconds: 700),
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
      duration: Duration(milliseconds: 900),
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
      duration: Duration(milliseconds: 1000),
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
      backgroundColor: Color(0xFFF0F2F8),
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
                SizedBox(height: 19.w),
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
                              return SizedBox.shrink();
                            }),

                            // ─── SUBSCRIPTIONS SECTION ─────────────────
                            _buildSectionHeader(
                              icon: Icons.star_rounded,
                              iconColor: Color(0xFFFFB800),
                              title: 'Subscription',
                              subtitle: 'Exclusive subscription plans for you',
                            ),
                            SizedBox(height: 10.w),
                            const SpecialCarousel(),
                            SizedBox(height: 21.w),

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
                            SizedBox(height: 133.w),
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
                  margin: EdgeInsets.all(14.w),
                  height: 48.w,
                  width: 221.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5768AB), Color(0xFF232F46)],
                    ),
                    borderRadius: BorderRadius.circular(28.w),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5768AB).withOpacity(0.5),
                        blurRadius: 16.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.w),
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
                          Icon(Icons.shopping_cart_rounded,
                              color: Colors.white, size: 19.w),
                          SizedBox(width: 9.w),
                          Text(
                            "View Cart",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.w,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 9.w),
                          Container(
                            padding: EdgeInsets.all(7.w),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              productListController
                                  .getTotalCartItems()
                                  .toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.w,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 47.w, bottom: 23.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.w),
          bottomRight: Radius.circular(28.w),
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
                padding: EdgeInsets.symmetric(horizontal: 19.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Location pill
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 9.w, vertical: 7.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(19.w),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: Color(0xFF7ECBFF), size: 14.w),
                          SizedBox(width: 7.w),
                          Obx(() {
                            if (controller.userAddress.isEmpty) {
                              return Text(
                                'No address',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10.w),
                              );
                            }
                            final address = controller.userAddress[0];
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                '${address['address_line'] ?? ''}, ${address['city'] ?? ''}',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10.w),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Spacer(),
                    // Profile avatar
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.PROFILE),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 2.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 19.w,
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

          SizedBox(height: 19.w),

          // ─── GREETING ─────────────────────────────────────────────────
          SlideTransition(
            position: _headerSlideAnimation,
            child: FadeTransition(
              opacity: _headerController,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 19.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} 👋',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13.w,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3.w),
                    Text(
                      'Fresh & Clean,\nJust a tap away!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21.w,
                        fontWeight: FontWeight.bold,
                        height: 1.w,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 21.w),

          // ─── SERVICE ICONS ────────────────────────────────────────────
          FadeTransition(
            opacity: _servicesController,
            child: Padding(
              padding: EdgeInsets.only(left: 19.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 12.w,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 13.w),
                  SlideTransition(
                    position: _servicesSlideAnimation,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          controller.services.length,
                          (index) {
                            final service = controller.services[index];
                            return Padding(
                              padding: EdgeInsets.only(right: 14.w),
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
                                      height: 65.w,
                                      width: 65.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.w,
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
                                          height: 65.w,
                                          width: 65.w,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.local_laundry_service, color: Colors.white, size: 28.w),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.w),
                                    SizedBox(
                                      width: 75.w,
                                      child: Text(
                                        service['name'] ?? 'Service',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.w,
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade600,
              Colors.deepOrange.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(14.w),
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
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(9.w),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 21.w,
              ),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Not Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.w,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'We currently don\'t serve your area. Available within 10km of our center.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10.w,
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
      padding: EdgeInsets.symmetric(horizontal: 17.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9.w),
            ),
            child: Icon(icon, color: iconColor, size: 19.w),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.w,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.w,
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
          iconColor: Color(0xFF9C6FFF),
          title: 'Customer Reviews',
          subtitle: 'What our customers say',
        ),
        SizedBox(height: 13.w),
        SizedBox(
          height: 149.w,
          child: Obx(() {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 17.w),
              itemCount: testimonialsController.testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonialsController.testimonials[index];
                final name = (testimonial['customer_name'] ?? 'A') as String;
                final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

                // Varied card accent colors
                final accentColors = [
                  Color(0xFF5768AB),
                  Color(0xFF9C6FFF),
                  Color(0xFF2DC9B7),
                  Color(0xFFFF6B6B),
                ];
                final accent = accentColors[index % accentColors.length];

                return Container(
                  width: 204.w,
                  margin: EdgeInsets.only(right: 13.w, bottom: 14.w),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border(
                      left: BorderSide(color: accent, width: 3.w),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17.w,
                            backgroundColor: accent.withOpacity(0.15),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.w,
                              ),
                            ),
                          ),
                          SizedBox(width: 9.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.w,
                                    color: Color(0xFF1A2340),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Star rating
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star_rounded,
                                        color: Color(0xFFFFB800), size: 10.w),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 9.w),
                      Icon(Icons.format_quote,
                          color: Color(0xFFCCCCCC), size: 14.w),
                      SizedBox(height: 3.w),
                      Expanded(
                        child: Text(
                          testimonial['customer_feedback'] ?? '',
                          style: TextStyle(
                            fontSize: 10.w,
                            color: Colors.black54,
                            height: 1.w,
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
        SizedBox(height: 9.w),
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
          iconColor: Color(0xFF2DC9B7),
          title: 'Recent Bookings',
          subtitle: 'Your latest laundry orders',
        ),
        SizedBox(height: 13.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 17.w),
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
                padding: EdgeInsets.symmetric(vertical: 28.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17.w),
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
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Color(0xFF2DC9B7).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inbox_rounded,
                        size: 35.w,
                        color: Color(0xFF2DC9B7),
                      ),
                    ),
                    SizedBox(height: 13.w),
                    Text(
                      "No recent bookings",
                      style: TextStyle(
                        fontSize: 13.w,
                        color: Color(0xFF1A2340),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 7.w),
                    Text(
                      "Place your first order and\nwe'll handle the rest!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.w,
                        color: Colors.grey,
                        height: 1.w,
                      ),
                    ),
                    SizedBox(height: 14.w),
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
        SizedBox(height: 21.w),
      ],
    );
  }

  Widget _buildGuestLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.w, horizontal: 19.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.w),
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
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Color(0xFF5768AB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              size: 35.w,
              color: Color(0xFF5768AB),
            ),
          ),
          SizedBox(height: 13.w),
          Text(
            "Track Your Orders",
            style: TextStyle(
              fontSize: 13.w,
              color: Color(0xFF1A2340),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 7.w),
          Text(
            "Sign in to view your recent\nlaundry bookings.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.w,
              color: Colors.grey,
              height: 1.w,
            ),
          ),
          SizedBox(height: 14.w),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5768AB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.w),
              ),
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.w),
            ),
            child: Text(
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
