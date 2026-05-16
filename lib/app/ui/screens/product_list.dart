import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  final controller = Get.find<ProductListController>();

  late int serviceId;
  late String serviceName;

  late final AnimationController _pageLoadController;
  late final AnimationController _categoryController;
  late final AnimationController _gridController;
  late final AnimationController _cartController;

  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _categoryScaleAnimation;
  late final Animation<Offset> _cartSlideAnimation;

  bool _isAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    serviceId = args['service_id'];
    serviceName = args['serviceName'];
    controller.selectedCategoryId.value = null;
    controller.setService(serviceName);

    _initializeAnimations();
    Future.microtask(() => controller.loadProductsFromSupabase(serviceId));
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _categoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      parent: _pageLoadController,
      curve: Curves.easeOutBack,
    ));

    _categoryScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _categoryController,
        curve: Curves.easeOutBack,
      ),
    );

    _cartSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cartController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimationSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isAnimationStarted) return;
      _isAnimationStarted = true;

      try {
        _pageLoadController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _categoryController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _gridController.forward();

        // Listen for cart changes to animate cart button
        ever(controller.cartQuantities, (_) {
          if (mounted) {
            if (controller.getTotalCartItems() > 0) {
              _cartController.forward();
            } else {
              _cartController.reverse();
            }
          }
        });
      } catch (e) {
        if (mounted) {
          _pageLoadController.forward();
          _categoryController.forward();
          _gridController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _categoryController.dispose();
    _gridController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _buildAnimatedCategories(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildAnimatedProductGrid(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAnimatedCartButton(),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          bottom: 22,
          left: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
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
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Choose your items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            // Cart count badge in header
            Obx(() {
              final count = controller.getTotalCartItems();
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCategories() {
    return ScaleTransition(
      scale: _categoryScaleAnimation,
      child: SizedBox(
        height: 44,
        child: Obx(
          () => Skeletonizer(
            enabled: controller.isLoading.value,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: controller.categories.isEmpty
                  ? List.generate(4, (index) => _buildCategorySkeleton())
                  : controller.categories.map((category) {
                      final categoryId = category['id'];
                      final isSelected =
                          controller.selectedCategoryId.value == categoryId;
                      return _EnhancedCategoryChip(
                        label: category['name'].toString(),
                        iconUrl: category['image_url'],
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelected) {
                            controller.filterProductsByCategory(null, null);
                          } else {
                            controller.filterProductsByCategory(
                                categoryId, serviceId);
                          }
                        },
                      );
                    }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProductGrid() {
    return Obx(() {
      if (!controller.isLoading.value && controller.filteredProducts.isEmpty) {
        return _buildEmptyState();
      }

      return AnimatedBuilder(
        animation: _gridController,
        builder: (context, child) {
          return Skeletonizer(
            enabled: controller.isLoading.value,
            child: GridView.builder(
              itemCount: controller.isLoading.value
                  ? 6
                  : controller.filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.66,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (controller.isLoading.value) {
                  return _buildProductSkeleton();
                }

                final item = controller.filteredProducts[index];
                final key =
                    '${item['service_id'] ?? controller.currentService.value}_${item['id']}';

                return _EnhancedProductCard(
                  item: item,
                  key: ValueKey(key),
                  cartKey: key,
                  index: index,
                  controller: controller,
                  gridAnimation: _gridController,
                );
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _pageOpacityAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.network(
                "https://cdn-icons-png.flaticon.com/512/4076/4076503.png",
                height: 80,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No items available",
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please try selecting a different category",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCartButton() {
    return Obx(() => controller.getTotalCartItems() > 0
        ? SlideTransition(
            position: _cartSlideAnimation,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4B5EAA), Color(0xFF1A2340)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3D52A0).withOpacity(0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final selectedItems = controller.getSelectedCartItems();
                    Navigator.pushNamed(
                      context,
                      '/checkout_page',
                      arguments: {
                        'selectedItems': selectedItems,
                        'serviceName': serviceName,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Proceed to Checkout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.getTotalCartItems().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildCategorySkeleton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }

  Widget _buildProductSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

// Enhanced Category Chip with animations
class _EnhancedCategoryChip extends StatefulWidget {
  final String label;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnhancedCategoryChip({
    required this.label,
    this.iconUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _EnhancedCategoryChipState createState() => _EnhancedCategoryChipState();
}

class _EnhancedCategoryChipState extends State<_EnhancedCategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
                        )
                      : null,
                  color: !widget.isSelected ? Colors.white : null,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFF3D52A0)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          const BoxShadow(
                            color: Color(0x443D52A0),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          widget.iconUrl!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty)
                      const SizedBox(width: 7),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Enhanced Product Card with animations
class _EnhancedProductCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String cartKey;
  final int index;
  final dynamic controller;
  final AnimationController gridAnimation;

  const _EnhancedProductCard({
    super.key,
    required this.item,
    required this.cartKey,
    required this.index,
    required this.controller,
    required this.gridAnimation,
  });

  @override
  _EnhancedProductCardState createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<_EnhancedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _scaleAnimation;

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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.gridAnimation,
        curve: Interval(
          (widget.index * 0.1).clamp(0.0, 1.0),
          ((widget.index * 0.1) + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: widget.gridAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animationValue,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(animationValue),
            child: GestureDetector(
              onTapDown: (_) => _hoverController.forward(),
              onTapUp: (_) => _hoverController.reverse(),
              onTapCancel: () => _hoverController.reverse(),
              child: AnimatedBuilder(
                animation: _hoverController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.07 + (_hoverAnimation.value * 0.04)),
                            blurRadius: 8 + (_hoverAnimation.value * 8),
                            offset: Offset(0, 3 + (_hoverAnimation.value * 4)),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductImage(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProductInfo(),
                                const SizedBox(height: 6),
                                _buildRatingRow(),
                                const SizedBox(height: 8),
                                _buildActionButton(),
                              ],
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
        );
      },
    );
  }

  Widget _buildProductImage() {
    final discount = widget.item['discount']?.toString() ?? '';
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: SizedBox(
            height: 115,
            width: double.infinity,
            child: Image.network(
              widget.item['image'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFEEF0F8),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 44,
                  color: Color(0xFF3D52A0),
                ),
              ),
            ),
          ),
        ),
        // Discount badge
        if (discount.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                discount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A2340),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\u20B9${widget.item['price']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D52A0),
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 5),
            if ((widget.item['oldPrice']?.toString() ?? '').isNotEmpty)
              Text(
                "\u20B9${widget.item['oldPrice']}",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.green, size: 14),
              const SizedBox(width: 2),
              Text(
                "${widget.item['rating']}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "(${widget.item['reviews']})",
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Obx(() {
      final quantity = widget.controller.cartQuantities[widget.cartKey] ?? 0;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: quantity > 0
            ? _buildQuantitySelector(quantity)
            : _buildAddButton(),
      );
    });
  }

  Widget _buildQuantitySelector(int quantity) {
    return Container(
      key: const ValueKey('quantity_selector'),
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.controller.removeFromCart(widget.item),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  height: 40,
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          Expanded(
            child: Center(
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.controller.addToCart(widget.item),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  height: 40,
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      key: const ValueKey('add_button'),
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.controller.addToCart(widget.item),
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}