import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/ui/screens/product_list.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen>
    with TickerProviderStateMixin {
  final controller = Get.put(HomePageController());

  late final AnimationController _pageLoadController;
  late final AnimationController _headerController;
  late final AnimationController _listController;

  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _headerScaleAnimation;

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

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
  }

  void _startAnimationSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isAnimationStarted) return;
      _isAnimationStarted = true;

      try {
        _pageLoadController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _headerController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _listController.forward();
      } catch (e) {
        if (mounted) {
          _pageLoadController.forward();
          _headerController.forward();
          _listController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: Column(
          children: [
            // _buildAnimatedHeader(),
            // const SizedBox(height: 20),
            Expanded(child: _buildServicesList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF1F2F5),
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: ScaleTransition(
          scale: _headerScaleAnimation,
          child: Text(
            'Our Services',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      centerTitle: true,
    );
  }
  Widget _buildServicesList() {
    return Obx(() {
      final services = controller.services;

      if (services.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading services...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _EnhancedServiceCard(
            service: service,
            index: index,
            listController: _listController,
            onTap: () => _navigateToProductList(service),
          );
        },
      );
    });
  }

  void _navigateToProductList(Map<String, dynamic> service) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: const ProductListScreen(),
            ),
          );
        },
        settings: RouteSettings(
          arguments: {
            'serviceName': service['name'],
            'service_id': service['id'],
          },
        ),
      ),
    );
  }
}

// Enhanced Service Card with advanced animations
class _EnhancedServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final int index;
  final AnimationController listController;
  final VoidCallback onTap;

  const _EnhancedServiceCard({
    required this.service,
    required this.index,
    required this.listController,
    required this.onTap,
  });

  @override
  _EnhancedServiceCardState createState() => _EnhancedServiceCardState();
}

class _EnhancedServiceCardState extends State<_EnhancedServiceCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHoverStart() {
    if (mounted && !_isHovering) {
      setState(() => _isHovering = true);
      _hoverController.forward();
    }
  }

  void _handleHoverEnd() {
    if (mounted && _isHovering) {
      setState(() => _isHovering = false);
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.listController,
        curve: Interval(
          (widget.index * 0.1).clamp(0.0, 1.0),
          ((widget.index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: widget.listController,
      builder: (context, child) {
        return FadeTransition(
          opacity: animationValue,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(animationValue),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: MouseRegion(
                onEnter: (_) => _handleHoverStart(),
                onExit: (_) => _handleHoverEnd(),
                child: AnimatedBuilder(
                  animation: _hoverController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: _elevationAnimation.value,
                              offset: Offset(0, _elevationAnimation.value / 2),
                            ),
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(_hoverAnimation.value * 0.1),
                              blurRadius: 25,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onTap,
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppTheme.primaryColor.withOpacity(0.1),
                            highlightColor: AppTheme.primaryColor.withOpacity(0.05),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _buildServiceImage(),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildServiceInfo()),
                                  _buildTrailingIcon(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceImage() {
    return Hero(
      tag: 'service_image_${widget.service['id']}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                Image.network(
                  widget.service['image_url'] ??
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZGOWHxy5gcPkGjr4AxlsSgRIVVTCaQ0sJDw&s',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.cleaning_services,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                // Subtle overlay
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.service['name'] ?? '-',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.service['description'] ?? 'Professional laundry service',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Available Now',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIcon() {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1 + (_hoverAnimation.value * 0.05)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovering
                ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Transform.translate(
            offset: Offset(_hoverAnimation.value * 3, 0),
            child: Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}