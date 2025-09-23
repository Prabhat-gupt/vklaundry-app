import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/ui/widgets/order_card.dart';

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
  }

  void _initializeAnimations() {
    _pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _headerController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
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
    _pageLoadController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      appBar: _buildAnimatedAppBar(),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: Column(
          children: [
            // _buildAnimatedHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildAnimatedContent()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: ScaleTransition(
          scale: _headerScaleAnimation,
          child: Text(
            "All Orders",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 24,
            ),
          ),
        ),
      ),
      centerTitle: true,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          onPressed: () => Get.back(),
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
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final ordersData = orderTrackController.order['orders'] ?? [];
                      return Text(
                        ordersData.isEmpty
                            ? 'No orders found'
                            : '${ordersData.length} ${ordersData.length == 1 ? 'order' : 'orders'} found',
                        style: const TextStyle(
                          fontSize: 14,
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18.0),
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.network(
                    "https://cdn-icons-png.flaticon.com/512/4076/4076503.png",
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shopping_bag_outlined,
                      size: 100,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      Text(
                        "No Orders Found",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "You haven't placed any orders yet.\nStart by exploring our services!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
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
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Explore Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: OrderCard(
                  orders: List<Map<String, dynamic>>.from(ordersData),
                  numbersOrders: ordersData.length,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}