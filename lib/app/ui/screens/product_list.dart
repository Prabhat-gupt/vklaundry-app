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
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedCategories(),
              const SizedBox(height: 16),
              _buildAnimatedProductGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAnimatedCartButton(),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      elevation: 1,
      shadowColor: Colors.grey,
      backgroundColor: Colors.white,
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
              Icons.arrow_back,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: Column(
          children: [
            Text(
              serviceName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 18,
              ),
            ),
            Text(
              'Choose your items',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAnimatedCategories() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: ScaleTransition(
        scale: _categoryScaleAnimation,
        child: Container(
          height: 50,
          child: Obx(
                () => Skeletonizer(
              enabled: controller.isLoading.value,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
        ),
      ),
    );
  }

  Widget _buildAnimatedProductGrid() {
    return Expanded(
      child: Obx(() {
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
                  childAspectRatio: 0.46,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  if (controller.isLoading.value) {
                    return _buildProductSkeleton();
                  }

                  final item = controller.filteredProducts[index];
                  final serviceId =
                      item['service_id'] ?? controller.currentService.value;
                  final productId = item['id'];
                  final key = '${serviceId}_$productId';

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
      }),
    );
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
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade600, Colors.indigo.shade700],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.4),
              blurRadius: 15,
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
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "View Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.getTotalCartItems().toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
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
  bool _isHovering = false;
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
      padding: const EdgeInsets.only(right: 10.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: widget.isSelected
                        ? LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                    )
                        : null,
                    color: !widget.isSelected ? Colors.white : null,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: widget.isSelected || _isHovering
                        ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(widget.iconUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty)
                        const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected ? Colors.white : AppTheme.primaryColor,
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
  bool _isHovering = false;
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
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovering = true);
                _hoverController.forward();
              },
              onExit: (_) {
                setState(() => _isHovering = false);
                _hoverController.reverse();
              },
              child: AnimatedBuilder(
                animation: _hoverController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08 + (_hoverAnimation.value * 0.05)),
                            blurRadius: 6 + (_hoverAnimation.value * 10),
                            offset: Offset(0, 2 + (_hoverAnimation.value * 4)),
                          ),
                          if (_isHovering)
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductImage(),
                            const SizedBox(height: 12),
                            _buildProductInfo(),
                            const SizedBox(height: 12),
                            _buildRatingRow(),
                            const SizedBox(height: 16),
                            _buildActionButton(),
                          ],
                        ),
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
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.primaryColor.withOpacity(0.02),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.item['image'] ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.local_laundry_service,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
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
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        const Text(
          "All shirts (eg. cotton, denim)",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              "\u20B9${widget.item['oldPrice']}",
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "\u20B9${widget.item['price']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          widget.item['discount'] ?? '',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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