import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/ui/widgets/order_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage>
    with TickerProviderStateMixin {
  final orderTrackController = Get.find<TrackOrderController>();

  late final AnimationController _pageLoadController;
  late final AnimationController _headerController;
  late final AnimationController _contentController;

  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _headerScaleAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  late final Animation<double> _contentFadeAnimation;

  bool _isAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _setupRealtimeUpdates();
  }

  Future<void> _setupRealtimeUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        orderTrackController.subscribeToAllUserOrders(userId);
      }
    } catch (e) {
      print("Error setting up real-time updates: $e");
    }
  }

  void _initializeAnimations() {
    _pageLoadController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _pageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageLoadController,
        curve: Curves.easeInOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutBack,
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isAnimationStarted) return;
      _isAnimationStarted = true;

      try {
        _pageLoadController.forward();
        await Future.delayed(Duration(milliseconds: 200));
        if (mounted) _headerController.forward();
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) _contentController.forward();
      } catch (e) {
        if (mounted) {
          _pageLoadController.forward();
          _headerController.forward();
          _contentController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    orderTrackController.unsubscribeFromOrderChanges();
    _pageLoadController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F8),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: Column(
          children: [
            _buildGradientHeader(context),
            SizedBox(height: 13.h),
            Expanded(child: _buildAnimatedContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 14.w,
          left: 13.w,
          right: 13.w,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(23.r),
            bottomRight: Radius.circular(23.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x553D52A0),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: title + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Obx(() {
                    final count =
                        (orderTrackController.order['orders'] ?? []).length;
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1.w),
                      ),
                      child: Text(
                        count == 0
                            ? 'No orders yet'
                            : '$count ${count == 1 ? 'order' : 'orders'} found',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Right: icon
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.w),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 21.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: ScaleTransition(
        scale: _headerScaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w),
          padding: EdgeInsets.all(19.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(13.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 24.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Obx(() {
                      final ordersData =
                          orderTrackController.order['orders'] ?? [];
                      return Text(
                        ordersData.isEmpty
                            ? 'No orders found'
                            : '${ordersData.length} ${ordersData.length == 1 ? 'order' : 'orders'} found',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return SlideTransition(
      position: _contentSlideAnimation,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.w),
          child: Obx(() {
            final ordersData = orderTrackController.order['orders'] ?? [];

            if (ordersData.isEmpty) {
              return _buildAnimatedEmptyState();
            }

            return _buildAnimatedOrdersList(ordersData);
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 900),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.7 + (0.3 * value),
                  child: Container(
                    padding: EdgeInsets.all(21.r),
                    decoration: BoxDecoration(
                      color: Color(0xFF3D52A0).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox_rounded,
                      size: 55.sp,
                      color: Color(0xFF3D52A0),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 21.h),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      Text(
                        "No Orders Yet",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "You haven't placed any orders yet.\nStart by exploring our services!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                          height: 1.w,
                        ),
                      ),
                      SizedBox(height: 21.h),
                      _buildExploreServicesButton(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExploreServicesButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3D52A0).withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final homeController = Get.find<HomePageController>();
            homeController.currentNavIndex.value = 1;
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_rounded, color: Colors.white, size: 14.sp),
                SizedBox(width: 8.w),
                Text(
                  'Explore Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOrdersList(List ordersData) {
    final sorted = List.from(ordersData);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: OrderCard(
            orders: List<Map<String, dynamic>>.from(sorted),
            numbersOrders: sorted.length,
          ),
        );
      },
    );
  }
}
