import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/orders_controller.dart';
import 'package:laundry_app/app/controllers/payment_select_controller.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:laundry_app/app/controllers/razorpay_payment_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:laundry_app/app/ui/screens/myOffers.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with TickerProviderStateMixin {
  final ProductListController controller = Get.find<ProductListController>();
  final HomePageController controllersHome = Get.find<HomePageController>();
  final OrderController orderController = Get.put(OrderController());
  final ProfileController profileController = Get.find<ProfileController>();
  final paymentController = Get.put(PaymentSelectController(), permanent: true);

  String? paymentMethod;
  DateTime? selectedPickupDate;
  String? selectedPickupSlot;
  var storage = GetStorage();
  final List<String> pickupSlots = ["7AM to 10AM", "5PM to 8PM"];

  late RazorpayPaymentController razorpayController;
  int? hasSubscription;
  bool discountApplied = false;

  // Animation controllers
  late final AnimationController _pageLoadController;
  late final AnimationController _itemsController;
  late final AnimationController _dateController;
  late final AnimationController _billController;
  late final AnimationController _bottomBarController;

  // Animations
  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _itemsScaleAnimation;
  late final Animation<Offset> _dateSlideAnimation;
  late final Animation<double> _billFadeAnimation;
  late final Animation<Offset> _bottomBarSlideAnimation;

  bool _isAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    controller.activeOfferselected.value = {};
    discountApplied = false;

    _initializeAnimations();

    razorpayController = Get.put(
      RazorpayPaymentController(razorpayKeyId: 'RAZORPAY_KEY_ID_HERE'),
      permanent: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selectedItems = controller.getSelectedCartItems();
      final totalItemsCount = selectedItems.fold<int>(0, (sum, item) {
        final quantity = controller.cartQuantities[
        '${item['service']}_${item['product']['id']}'] ??
            0;
        return sum + quantity;
      });

      hasSubscription = await profileController.validateAndUpdateSubscription(
        storage.read('userId'),
      );
      setState(() {});
      print("has subscrition is ::::::::: $hasSubscription");

      _startAnimationSequence();
    });
  }

  void _initializeAnimations() {
    _pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _itemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _dateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _billController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bottomBarController = AnimationController(
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

    _itemsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _itemsController,
        curve: Curves.easeOutBack,
      ),
    );

    _dateSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dateController,
      curve: Curves.easeOutCubic,
    ));

    _billFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _billController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bottomBarController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimationSequence() async {
    if (!mounted || _isAnimationStarted) return;
    _isAnimationStarted = true;

    try {
      _pageLoadController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _itemsController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _dateController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _billController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _bottomBarController.forward();
    } catch (e) {
      if (mounted) {
        _pageLoadController.forward();
        _itemsController.forward();
        _dateController.forward();
        _billController.forward();
        _bottomBarController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _itemsController.dispose();
    _dateController.dispose();
    _billController.dispose();
    _bottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      "my subscription is checking here is ::::: ${storage.read('subscriptionCheck')}",
    );
    final selectedItems = controller.getSelectedCartItems().where((item) {
      final quantity = controller
          .cartQuantities['${item['service']}_${item['product']['id']}'] ??
          0;
      return quantity > 0;
    }).toList();

    if (selectedItems.isEmpty) {
      Future.microtask(() => Get.back());
      return const SizedBox();
    }

    final double itemsTotal = controller.calculateItemsTotal();
    final double deliveryCharge = 5.0;
    final double handlingCharge = 2.0;
    final double grandTotal = itemsTotal + deliveryCharge + handlingCharge;

    final offer = controller.activeOfferselected.isEmpty
        ? null
        : controller.activeOfferselected;

    double discount = 0.0;
    String discountLabel = "";

    if (discountApplied && offer != null) {
      final double minAmount = (offer['min_amount'] ?? 0).toDouble();
      if (grandTotal >= minAmount) {
        if (offer['discount_type'] == 'percentage') {
          discount = grandTotal * ((offer['discount_value'] ?? 0) / 100);
          discountLabel = "${offer['title']} (${offer['discount_value']}% off)";
        } else if (offer['discount_type'] == 'fixed') {
          discount = (offer['discount_value'] ?? 0).toDouble();
          discountLabel =
          "${offer['title']} (₹${discount.toStringAsFixed(2)} off)";
        }
      }
    }

    final double finalTotal = (grandTotal - discount).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: WillPopScope(
        onWillPop: () async {
          await controllersHome.fetchSubscriptions();
          return true;
        },
        child: FadeTransition(
          opacity: _pageOpacityAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAnimatedItemsCard(selectedItems),
                const SizedBox(height: 16),
                _buildAnimatedPickupSlotSelector(context),
                if (selectedPickupDate != null && selectedPickupSlot != null)
                  _buildAnimatedDeliveryDateDisplay(),
                const SizedBox(height: 16),
                _buildAnimatedOffersSection(grandTotal),
                const SizedBox(height: 16),
                _buildAnimatedBillDetails(
                  itemsTotal,
                  deliveryCharge,
                  handlingCharge,
                  grandTotal,
                  discount,
                  discountLabel,
                ),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(context, finalTotal, paymentMethod),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: Text(
          "Checkout",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      centerTitle: true,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: GestureDetector(
          onTap: () async {
            Get.back();
            await controllersHome.fetchSubscriptions();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItemsCard(List<Map<String, dynamic>> items) {
    return ScaleTransition(
      scale: _itemsScaleAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Selected Items",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _EnhancedItemRow(
                  item: item,
                  controller: controller,
                  index: index,
                  onUpdate: () => setState(() {}),
                );
              }),
              const SizedBox(height: 16),
              _buildAddMoreSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMoreSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Missed something?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(87, 104, 171, 1),
                  Color.fromRGBO(35, 42, 69, 1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(87, 104, 171, 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Text(
                    "+ Add More Items",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPickupSlotSelector(BuildContext context) {
    return SlideTransition(
      position: _dateSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Select Pickup Date & Slot",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  DateTime date = DateTime.now().add(Duration(days: index));
                  bool isSelected = selectedPickupDate != null &&
                      DateUtils.isSameDay(selectedPickupDate, date);
                  return _EnhancedDateCard(
                    date: date,
                    isSelected: isSelected,
                    onTap: () => setState(() => selectedPickupDate = date),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Time Slot",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: pickupSlots.map((slot) {
                bool isSelected = slot == selectedPickupSlot;
                return _EnhancedTimeSlot(
                  slot: slot,
                  isSelected: isSelected,
                  onTap: () => setState(() => selectedPickupSlot = slot),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDeliveryDateDisplay() {
    if (selectedPickupDate == null) {
      return const SizedBox();
    }

    final deliveryDate = selectedPickupDate!.add(const Duration(hours: 72));

    return SlideTransition(
      position: _dateSlideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Expected Delivery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy  |  hh:mm a').format(deliveryDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOffersSection(double grandTotal) {
    return FadeTransition(
      opacity: _billFadeAnimation,
      child: hasSubscription == 1
          ? const SizedBox.shrink()
          : Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showOffersBottomSheet(
                context,
                controller.activeOffer,
                grandTotal,
                    (selectedOffer) {
                  setState(() {
                    if (selectedOffer != null) {
                      controller.activeOfferselected.value = selectedOffer;
                      discountApplied = true;
                    } else {
                      controller.activeOfferselected.value = {};
                      discountApplied = false;
                    }
                  });
                },
                alreadyAppliedOffer: controller.activeOfferselected,
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "View Available Offers",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.orange,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBillDetails(
      double itemsTotal,
      double deliveryCharge,
      double handlingCharge,
      double grandTotal,
      double discount,
      String discountLabel,
      ) {
    return FadeTransition(
      opacity: _billFadeAnimation,
      child: hasSubscription == 1
          ? _buildBillDetailWithoutSubscription(
        itemsTotal,
        profileController.totalPreviousCount,
      )
          : _buildBillDetails(
        itemsTotal,
        deliveryCharge,
        handlingCharge,
        grandTotal,
        discount,
        discountLabel,
      ),
    );
  }

  Widget _buildBillDetails(
      double itemsTotal,
      double deliveryCharge,
      double handlingCharge,
      double grandTotal,
      double discount,
      String discountLabel,
      ) {
    final double finalTotal = grandTotal - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Bill Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _billRow("Items total", "\u20B9${itemsTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _billRow("Delivery charge", "\u20B9${deliveryCharge.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _billRow("Handling charge", "\u20B9${handlingCharge.toStringAsFixed(2)}"),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _billRow(
              "Discount",
              "-\u20B9${discount.toStringAsFixed(2)}",
              isDiscount: true,
            ),
            const SizedBox(height: 4),
            Text(
              discountLabel,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.5),
                ],
              ),
            ),
          ),
          _billRow(
            "Grand Total",
            hasSubscription == 1
                ? "Free with Subscription"
                : "\u20B9${finalTotal.toStringAsFixed(2)}",
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetailWithoutSubscription(
      double itemsTotal,
      int? totalItemDelivered,
      ) {
    final int totalSubscriptionItems = 30;
    final int delivered = totalItemDelivered ?? 0;
    final int newItems = controller.getTotalCartItems();
    final int remaining = totalSubscriptionItems - (delivered + newItems);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.2),
                      Colors.green.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Subscription Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSubscriptionRow("Total Subscription Items", "$totalSubscriptionItems", Icons.inventory_2),
          _buildSubscriptionRow("New Items Added", "$newItems", Icons.add_circle_outline, Colors.blue),
          _buildSubscriptionRow("Previous Items", "$delivered", Icons.check_circle_outline, Colors.green),
          _buildSubscriptionRow("Remaining Items", "$remaining", Icons.pending_actions, Colors.orange, true),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(String label, String value, IconData icon, [Color? color, bool isBold = false]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child:           Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.primaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: isDiscount
                ? Colors.green
                : isBold
                ? AppTheme.primaryColor
                : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBottomBar(
      BuildContext context,
      double grandTotal,
      String? paymentMethod,
      ) {
    return SlideTransition(
      position: _bottomBarSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildPlaceOrderButton(grandTotal),
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(double grandTotal) {
    final bool canPlaceOrder = selectedPickupDate != null && selectedPickupSlot != null;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canPlaceOrder
              ? [Colors.green.shade600, Colors.green.shade700]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: canPlaceOrder
            ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPlaceOrder ? () => _handlePlaceOrder(grandTotal) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasSubscription != 1) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\u20B9${grandTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Place Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(double grandTotal) async {
    final userIdMy = profileController.storages.read('userId');
    final checkUserScreen = await profileController.checkUserPincode(userIdMy);

    print("check user screen here is :::::: $checkUserScreen");

    if (checkUserScreen == false) {
      Get.toNamed('/setup_screen');
      return;
    }

    final customerName = profileController.name.value;
    final customerPhone = profileController.phone.value;
    final customerEmail = profileController.email.value;

    final int totalSubscriptionItems = 30;
    final int newItems = controller.getTotalCartItems();
    final num remaining = totalSubscriptionItems - (profileController.currentCount);

    final String? backendOrderId = null;
    print("my hasSubscription is ::::::: $hasSubscription");

    if (hasSubscription == 1) {
      print("my remaining is :::: ${profileController.currentCount} ad ${remaining}");
      int total = profileController.currentCount + newItems;

      print("my item toal $total and $totalSubscriptionItems is ::::: ${total == totalSubscriptionItems}");

      if (total > totalSubscriptionItems) {
        Get.snackbar(
          "Place order remaining",
          "Remanining orders $remaining",
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      } else if (total < totalSubscriptionItems || total == totalSubscriptionItems) {
        await orderController.placeOrder(
          selectedItems: controller.getSelectedCartItems(),
          totalAmount: grandTotal,
          paymentMethod: 'Subscription',
          paymentStatus: 'paid',
          pickupDateTime: "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
          deliveryDateTime: "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(const Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(const Duration(hours: 72)))}",
          userId: userIdMy,
          addressId: userIdMy,
        );

        Get.snackbar(
          "Order Placed",
          "Your order has been placed using your subscription.",
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );

        await profileController.UpdateSubscription(
          storage.read('userId'),
          profileController.currentCount,
          newItems,
        );
        Get.offAllNamed(
          AppRoutes.SUCCESS,
          arguments: {'order_id': 58},
        );
      }
    } else if (hasSubscription == 0) {
      await controllersHome.fetchSubscriptions();

      razorpayController.payNow(
        amount: grandTotal,
        orderId: backendOrderId,
        customerName: customerName.isNotEmpty ? customerName : 'Laundry User',
        description: 'Laundry order payment',
        prefillContact: customerPhone.isNotEmpty ? customerPhone : null,
        prefillEmail: customerEmail.isNotEmpty ? customerEmail : null,
        notes: {
          'user_id': '$userIdMy',
          'pickup': "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} $selectedPickupSlot",
        },
        onSuccess: (paymentId, orderId, signature) async {
          print("gjgjgjgjggjgjgj onSuccess is ::::::::: $paymentId");
          try {
            await orderController.placeOrder(
              selectedItems: controller.getSelectedCartItems(),
              totalAmount: grandTotal,
              paymentMethod: 'Razorpay',
              paymentStatus: 'paid',
              pickupDateTime: "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
              deliveryDateTime: "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(const Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(const Duration(hours: 72)))}",
              userId: userIdMy,
              addressId: userIdMy,
              transactionId: paymentId,
            );

            await profileController.updateAmountTransactionTable(grandTotal, paymentId);

            Get.snackbar(
              "Payment successful",
              "ID: $paymentId",
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white,
            );

            Get.offAllNamed(
              AppRoutes.SUCCESS,
              arguments: {'order_id': 58},
            );
          } catch (e) {
            Get.snackbar(
              "Order Error",
              "Payment captured, but order creation failed.\n${e.toString()}",
              backgroundColor: Colors.orange.shade700,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
        },
        onFailure: (code, message) {
          final isCancelled = code == 2 || message.toLowerCase().contains('cancel');
          Get.snackbar(
            isCancelled ? "Payment cancelled" : "Payment failed",
            isCancelled ? "You cancelled the payment." : "($code) $message",
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
          );
        },
      );
    }
  }
}

// Enhanced Item Row with animations
class _EnhancedItemRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final ProductListController controller;
  final int index;
  final VoidCallback onUpdate;

  const _EnhancedItemRow({
    required this.item,
    required this.controller,
    required this.index,
    required this.onUpdate,
  });

  @override
  _EnhancedItemRowState createState() => _EnhancedItemRowState();
}

class _EnhancedItemRowState extends State<_EnhancedItemRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _slideAnimation.value) * 300, 0),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    AppTheme.primaryColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildItemImage(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['product']['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Service: ${widget.item['service_name']}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _buildQuantityControls(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPriceDisplay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.item['product']['image'] ??
              'https://eu-images.contentstack.com/v3/assets/blte6b9e99033a702bd/blt7e5c15dd5c6fb1a3/67cacb6c91d4b6c9af49e7e3/Top_Shape_1.jpg?width=954&height=637&format=jpg&quality=80',
          height: 60,
          width: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.local_laundry_service,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Expanded(
      flex: 3, // Give more space to the text area
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item['product']['name'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
            maxLines: 2, // Allow up to 2 lines
            overflow: TextOverflow.ellipsis, // Handle overflow gracefully
          ),
          const SizedBox(height: 8), // Increased spacing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Service: ${widget.item['service_name']}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(87, 104, 171, 1),
            Color.fromRGBO(35, 42, 69, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(87, 104, 171, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.controller.removeFromCart(widget.item['product']);
                widget.controller.update();
                widget.onUpdate();
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.remove,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() {
              final quantity = widget.controller.cartQuantities[
              '${widget.item['service']}_${widget.item['product']['id']}'] ??
                  0;
              return Text(
                "$quantity",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.controller.addToCart(widget.item['product']);
                widget.controller.update();
                widget.onUpdate();
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Obx(() {
      final quantity = widget.controller.cartQuantities[
      '${widget.item['service']}_${widget.item['product']['id']}'] ??
          0;
      final totalPrice = quantity * widget.item['product']['price'];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          "\u20B9$totalPrice",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
        ),
      );
    });
  }
}

// Enhanced Date Card
class _EnhancedDateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnhancedDateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          )
              : null,
          color: !isSelected ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Time Slot
class _EnhancedTimeSlot extends StatelessWidget {
  final String slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnhancedTimeSlot({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          )
              : null,
          color: !isSelected ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
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
            Icon(
              Icons.schedule,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              slot,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}