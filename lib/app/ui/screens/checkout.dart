import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
// Removed get_storage import - using SharedPreferences instead
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
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> dynamicPickupSlots = [];
  List<DateTime> availableDates = [];
  bool isLoadingSlots = false;
  bool isLoadingDates = false;
  List<Map<String, dynamic>> _allAvailability = [];

  late RazorpayPaymentController razorpayController;
  int? hasSubscription;
  bool discountApplied = false;
  int _newEligibleItemsCount = 0;

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
  String _selectedPaymentMethod = 'Online';

  @override
  void initState() {
    super.initState();
    controller.activeOfferselected.value = {};
    discountApplied = false;

    _initializeAnimations();

    razorpayController = Get.put(
      RazorpayPaymentController(
        razorpayKeyId: dotenv.env['RAZORPAY_KEY_ID'] ?? '',
      ),
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

      // Get userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      print("my subscription is checking here is ::::: $userId");

      if (userId != null) {
        hasSubscription =
            await profileController.validateAndUpdateSubscription(userId);
      } else {
        hasSubscription = 0; // Default to no subscription if userId is null
      }

      setState(() {});
      print("has subscrition is ::::::::: $hasSubscription");

      _startAnimationSequence();
      
      _startAnimationSequence();
      
      _calculateAvailableDates();
    });
  }

  void _initializeAnimations() {
    _pageLoadController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _itemsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _dateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _billController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _bottomBarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
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
      await Future.delayed(Duration(milliseconds: 200));
      if (mounted) _itemsController.forward();
      await Future.delayed(Duration(milliseconds: 200));
      if (mounted) _dateController.forward();
      await Future.delayed(Duration(milliseconds: 200));
      if (mounted) _billController.forward();
      await Future.delayed(Duration(milliseconds: 200));
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

  Future<void> _calculateAvailableDates() async {
    if (!mounted) return;
    setState(() => isLoadingDates = true);

    try {
      final response = await controllersHome.supabase
          .from('availability')
          .select()
          .eq('is_active', true);

      _allAvailability = List<Map<String, dynamic>>.from(response);
      final List<DateTime> dates = [];
      final DateTime now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        DateTime date = now.add(Duration(days: i));
        String dayName = DateFormat('EEEE').format(date);
        bool isToday = i == 0;

        final daySlots = _allAvailability.where((row) => row['day_of_week'] == dayName).toList();
        
        bool hasValidSlots = false;
        if (isToday) {
          for (var row in daySlots) {
            final timeParts = row['start_time'].split(':');
            final slotHour = int.parse(timeParts[0]);
            final slotMinute = int.parse(timeParts[1]);
            DateTime slotStartTime = DateTime(now.year, now.month, now.day, slotHour, slotMinute);
            if (slotStartTime.isAfter(now)) {
              hasValidSlots = true;
              break;
            }
          }
        } else {
          hasValidSlots = daySlots.isNotEmpty;
        }

        if (hasValidSlots) {
          dates.add(date);
        }
      }

      if (mounted) {
        setState(() {
          availableDates = dates;
          if (availableDates.isNotEmpty) {
            selectedPickupDate = availableDates.first;
            _updateSlotsForSelectedDate();
          }
        });
      }
    } catch (e) {
      print("Error calculating available dates: $e");
    } finally {
      if (mounted) setState(() => isLoadingDates = false);
    }
  }

  void _updateSlotsForSelectedDate() {
    if (selectedPickupDate == null) return;
    
    String dayName = DateFormat('EEEE').format(selectedPickupDate!);
    final daySlots = _allAvailability
        .where((row) => row['day_of_week'] == dayName)
        .toList();
    
    // Sort by start_time
    daySlots.sort((a, b) => (a['start_time'] as String).compareTo(b['start_time'] as String));

    List<String> slots = [];
    DateTime now = DateTime.now();
    bool isToday = DateUtils.isSameDay(selectedPickupDate!, now);

    for (var row in daySlots) {
      String startTimeStr = row['start_time'];
      String endTimeStr = row['end_time'];
      
      if (isToday) {
         final timeParts = startTimeStr.split(':');
         final slotHour = int.parse(timeParts[0]);
         final slotMinute = int.parse(timeParts[1]);
         DateTime slotStartTime = DateTime(now.year, now.month, now.day, slotHour, slotMinute);
         
         if (slotStartTime.isAfter(now)) {
           slots.add(_formatSlot(startTimeStr, endTimeStr));
         }
      } else {
        slots.add(_formatSlot(startTimeStr, endTimeStr));
      }
    }

    setState(() {
      dynamicPickupSlots = slots;
      if (selectedPickupSlot != null && !dynamicPickupSlots.contains(selectedPickupSlot)) {
        selectedPickupSlot = null;
      }
    });
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
     // This is now handled by _updateSlotsForSelectedDate after _allAvailability is loaded
     _updateSlotsForSelectedDate();
  }

  String _formatSlot(String start, String end) {
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      
      final startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      final endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      
      final startStr = _formatTimeOfDay(startTime);
      final endStr = _formatTimeOfDay(endTime);
      
      return "$startStr to $endStr";
    } catch (e) {
      return "$start to $end";
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour $period";
  }

  @override
  Widget build(BuildContext context) {
    // Removed GetStorage check - using SharedPreferences
    final selectedItems = controller.getSelectedCartItems().where((item) {
      final quantity = controller
              .cartQuantities['${item['service']}_${item['product']['id']}'] ??
          0;
      return quantity > 0;
    }).toList();

    if (selectedItems.isEmpty) {
      Future.microtask(() => Get.back());
      return SizedBox();
    }

    double itemsTotal = 0.0;
    _newEligibleItemsCount = 0;
    double deliveryCharge = 5.0;
    double handlingCharge = 2.0;

    if (hasSubscription == 1) {
      deliveryCharge = 0.0;
      handlingCharge = 0.0;
      
      final int remainingQuota = profileController.remainingQuota;

      for (var item in selectedItems) {
        final quantity = controller.cartQuantities['${item['service']}_${item['product']['id']}'] ?? 0;
        if (quantity > 0) {
          final productId = item['product']['id'];
          final price = double.tryParse(item['product']['price'].toString()) ?? 0.0;
          final categoryId = item['product']['category_id'];
          bool isEligible = profileController.eligibleItemKeys.isEmpty || profileController.eligibleItemKeys.contains("${categoryId}_${productId}");
          
          if (isEligible) {
            if (_newEligibleItemsCount + quantity <= remainingQuota) {
              // Fully covered by subscription
              _newEligibleItemsCount += quantity;
            } else {
              // Partially or fully NOT covered
              final int covered = remainingQuota > _newEligibleItemsCount ? remainingQuota - _newEligibleItemsCount : 0;
              final int notCovered = quantity - covered;
              
              _newEligibleItemsCount += covered;
              itemsTotal += (price * notCovered);
            }
          } else {
            // Not eligible
            itemsTotal += (price * quantity);
          }
        }
      }
    } else {
      itemsTotal = controller.calculateItemsTotal();
    }

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
      backgroundColor: Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: WillPopScope(
        onWillPop: () async {
          await controllersHome.fetchSubscriptions();
          return true;
        },
        child: FadeTransition(
          opacity: _pageOpacityAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(14.r),
            child: Column(
              children: [
                _buildAnimatedItemsCard(selectedItems),
                SizedBox(height: 14.h),
                _buildAnimatedPickupSlotSelector(context),
                if (selectedPickupDate != null && selectedPickupSlot != null)
                  _buildAnimatedDeliveryDateDisplay(),
                SizedBox(height: 14.h),
                _buildAnimatedOffersSection(grandTotal),
                SizedBox(height: 14.h),
                _buildAnimatedBillDetails(
                  itemsTotal,
                  deliveryCharge,
                  handlingCharge,
                  grandTotal,
                  discount,
                  discountLabel,
                ),
                SizedBox(height: 15.h), // Space for bottom bar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          _buildAnimatedBottomBar(context, finalTotal, paymentMethod),
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
            fontSize: 15.sp,
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
            margin: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11.r),
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
            borderRadius: BorderRadius.circular(15.r),
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
          padding: EdgeInsets.all(15.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(11.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: AppTheme.primaryColor,
                      size: 21.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    "Selected Items",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _EnhancedItemRow(
                  item: item,
                  controller: controller,
                  index: index,
                  hasSubscription: hasSubscription,
                  eligibleItemKeys: profileController.eligibleItemKeys,
                  onUpdate: () => setState(() {}),
                );
              }),
              SizedBox(height: 14.h),
              _buildAddMoreSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMoreSection() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 15.sp,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    "Missed something?",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(87, 104, 171, 1),
                  Color.fromRGBO(35, 42, 69, 1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11.r),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(87, 104, 171, 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(11.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
                  child: Text(
                    "+ Add More",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
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
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
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
                  padding: EdgeInsets.all(11.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.primaryColor,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  "Select Pickup Date & Slot",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: isLoadingDates 
                  ? [const CircularProgressIndicator()]
                  : availableDates.map((date) {
                      bool isSelected = selectedPickupDate != null &&
                          DateUtils.isSameDay(selectedPickupDate, date);
                      return _EnhancedDateCard(
                        date: date,
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelected) return;
                          setState(() {
                            selectedPickupDate = date;
                            selectedPickupSlot = null;
                          });
                          _updateSlotsForSelectedDate();
                        },
                      );
                    }).toList(),
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              "Select Time Slot",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 11.h),
            if (isLoadingSlots || isLoadingDates)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (dynamicPickupSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(11.r),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, color: Colors.redAccent, size: 25.sp),
                    SizedBox(height: 6.h),
                    Text(
                      "No slots available for this date",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: dynamicPickupSlots.map((slot) {
                    bool isSelected = slot == selectedPickupSlot;
                    return Padding(
                      padding: EdgeInsets.only(right: 11.w),
                      child: _EnhancedTimeSlot(
                        slot: slot,
                        isSelected: isSelected,
                        onTap: () => setState(() => selectedPickupSlot = slot),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDeliveryDateDisplay() {
    if (selectedPickupDate == null) {
      return SizedBox();
    }

    final deliveryDate = selectedPickupDate!.add(Duration(hours: 72));

    return SlideTransition(
      position: _dateSlideAnimation,
      child: Container(
        margin: EdgeInsets.only(top: 14.h),
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(11.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.green,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  "Expected Delivery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 11.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy  |  hh:mm a')
                    .format(deliveryDate),
                style: TextStyle(
                  fontSize: 14.sp,
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
      child: (hasSubscription == 1 && grandTotal == 0.0)
          ? SizedBox.shrink()
          : Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.w,
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
                        if (selectedOffer != null && selectedOffer['type'] == 'first_order' && profileController.isFirstApply.value) {
                          Get.snackbar(
                            "Not Eligible", 
                            "You have already used the first order coupon.",
                            backgroundColor: Colors.red.shade700,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        setState(() {
                          if (selectedOffer != null) {
                            controller.activeOfferselected.value =
                                selectedOffer;
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
                  borderRadius: BorderRadius.circular(15.r),
                  child: Container(
                    padding: EdgeInsets.all(15.r),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(11.r),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(11.r),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: Colors.orange,
                            size: 21.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            "View Available Offers",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange,
                          size: 15.sp,
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
      child: Column(
        children: [
          if (hasSubscription == 1)
            _buildBillDetailWithoutSubscription(
              itemsTotal,
              profileController.totalPreviousCount,
              _newEligibleItemsCount,
            ),
          if (hasSubscription == 1 && itemsTotal > 0)
            SizedBox(height: 14.h),
          if (hasSubscription != 1 || itemsTotal > 0)
            _buildBillDetails(
              itemsTotal,
              deliveryCharge,
              handlingCharge,
              grandTotal,
              discount,
              discountLabel,
            ),
        ],
      )
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
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
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
                padding: EdgeInsets.all(11.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppTheme.primaryColor,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                "Bill Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          _billRow("Items total", "\u20B9${itemsTotal.toStringAsFixed(2)}"),
          SizedBox(height: 11.h),
          _billRow(
              "Delivery charge", "\u20B9${deliveryCharge.toStringAsFixed(2)}"),
          SizedBox(height: 11.h),
          _billRow(
              "Handling charge", "\u20B9${handlingCharge.toStringAsFixed(2)}"),
          if (discount > 0) ...[
            SizedBox(height: 11.h),
            _billRow(
              "Discount",
              "-\u20B9${discount.toStringAsFixed(2)}",
              isDiscount: true,
            ),
            SizedBox(height: 6.h),
            Text(
              discountLabel,
              style: TextStyle(
                color: Colors.green,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          Container(
            margin: EdgeInsets.symmetric(vertical: 14.h),
            height: 1.w,
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
            (hasSubscription == 1 && finalTotal == 0.0)
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
    int newEligibleItemsCount,
  ) {
    final int totalSubscriptionItems = profileController.maxPieces;
    final int delivered = totalItemDelivered ?? 0;
    final int newItems = newEligibleItemsCount;
    final int remaining = (totalSubscriptionItems - (delivered + newItems)).clamp(0, totalSubscriptionItems);

    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
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
                padding: EdgeInsets.all(11.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.2),
                      Colors.green.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.card_membership_rounded,
                  color: Colors.green,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                "Subscription Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          _buildSubscriptionRow("Total Subscription Items",
              "$totalSubscriptionItems", Icons.inventory_2),
          _buildSubscriptionRow("New Items Added", "$newItems",
              Icons.add_circle_outline, Colors.blue),
          _buildSubscriptionRow("Previous Items", "$delivered",
              Icons.check_circle_outline, Colors.green),
          _buildSubscriptionRow("Remaining Items", "$remaining",
              Icons.pending_actions, Colors.orange, true),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(String label, String value, IconData icon,
      [Color? color, bool isBold = false]) {
    return Container(
      margin: EdgeInsets.only(bottom: 11.h),
      padding: EdgeInsets.all(11.r),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.05),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primaryColor, size: 15.sp),
          SizedBox(width: 11.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.primaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value,
      {bool isBold = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
            color: Color(0xFF1F2937),
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
                    : Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBottomBar(
    BuildContext context,
    double finalTotal,
    String? paymentMethod,
  ) {
    return SlideTransition(
      position: _bottomBarSlideAnimation,
      child: Container(
        padding: EdgeInsets.all(15.r),
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
          child: _buildPlaceOrderButton(finalTotal),
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(double finalTotal) {
    final bool canPlaceOrder =
        selectedPickupDate != null && selectedPickupSlot != null;

    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canPlaceOrder
              ? [Colors.green.shade600, Colors.green.shade700]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(14.r),
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
          onTap: canPlaceOrder
              ? () {
                  if (hasSubscription != 1 || finalTotal > 0) {
                    _showPaymentMethodPopup(finalTotal);
                  } else {
                    _handlePlaceOrder(finalTotal);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 21.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasSubscription != 1 || finalTotal > 0) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\u20B9${finalTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 21.w),
                ],
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.white,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 11.w),
                Text(
                  "Place Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
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

  void _showPaymentMethodPopup(double finalTotal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(21.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(21.r),
              topRight: Radius.circular(21.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 21.h),
              Text(
                "Select Payment Method",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 21.h),
              _buildPopupOption(
                title: "Pay Online",
                subtitle: "Credit/Debit Card, UPI, Wallets",
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.blue,
                onTap: () {
                  Get.back();
                  setState(() => _selectedPaymentMethod = 'Online');
                  _handlePlaceOrder(finalTotal);
                },
              ),
              SizedBox(height: 14.h),
              _buildPopupOption(
                title: "Cash on Delivery",
                subtitle: "Pay when you receive the order",
                icon: Icons.money_rounded,
                color: Colors.green,
                onTap: () {
                  Get.back();
                  setState(() => _selectedPaymentMethod = 'COD');
                  _handlePlaceOrder(finalTotal);
                },
              ),
              SizedBox(height: 14.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(11.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(double finalTotal) async {
    final prefs = await SharedPreferences.getInstance();
    final userIdMy = prefs.getInt('user_id');

    if (userIdMy == null) {
      Get.snackbar('Error', 'User not logged in. Please login again.');
      Get.offAllNamed(AppRoutes.LOGIN);
      return;
    }

    final checkUserScreen = await profileController.checkUserPincode(userIdMy);

    print("check user screen here is :::::: $checkUserScreen");

    if (checkUserScreen == false) {
      Get.toNamed('/setup_screen');
      return;
    }

    final customerName = profileController.name.value;
    final customerPhone = profileController.phone.value;
    final customerEmail = profileController.email.value;

    final int totalSubscriptionItems = profileController.maxPieces;
    final int newItems = hasSubscription == 1 ? _newEligibleItemsCount : controller.getTotalCartItems();
    final num remaining = (totalSubscriptionItems - profileController.currentCount).clamp(0, totalSubscriptionItems);

    final String? backendOrderId = null;
    print("my hasSubscription is ::::::: $hasSubscription");

    if (hasSubscription == 1 && finalTotal == 0) {
      print(
          "my remaining is :::: ${profileController.currentCount} ad ${remaining}");

      await profileController.UpdateSubscription(
        userIdMy,
        profileController.currentCount,
        newItems,
      );
      
      // Place the order
      await orderController.placeOrder(
        selectedItems: controller.getSelectedCartItems(),
        totalAmount: finalTotal,
        paymentMethod: 1,
        paymentStatus: 1,
        pickupDateTime:
            "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
        deliveryDateTime:
            "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(Duration(hours: 72)))}",
        userId: userIdMy,
        addressId: userIdMy,
      );

      Get.snackbar(
        "Order Placed",
        "Your order has been placed successfully.",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );

      if (controller.activeOfferselected.isNotEmpty && controller.activeOfferselected['type'] == 'first_order') {
        await profileController.markFirstOrderDone(userIdMy);
      }

      Get.offAllNamed(
        AppRoutes.SUCCESS,
        arguments: {'order_id': 58},
      );
      return;
    }

    if (_selectedPaymentMethod == 'COD') {
        try {
          final orderId = await orderController.placeOrder(
            selectedItems: controller.getSelectedCartItems(),
            totalAmount: finalTotal,
            paymentMethod: 2, // 2 for COD
            paymentStatus: 0, // 0 for Unpaid/Pending
            pickupDateTime:
                "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
            deliveryDateTime:
                "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(Duration(hours: 72)))}",
            userId: userIdMy,
            addressId: userIdMy,
          );

          Get.snackbar(
            "Order Placed",
            "Your order has been placed via Cash on Delivery.",
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );
          
          if (hasSubscription == 1) {
            await profileController.UpdateSubscription(
              userIdMy,
              profileController.currentCount,
              newItems,
            );
          }

          if (controller.activeOfferselected.isNotEmpty && controller.activeOfferselected['type'] == 'first_order') {
            await profileController.markFirstOrderDone(userIdMy);
          }

          Get.offAllNamed(
            AppRoutes.SUCCESS,
            arguments: {'order_id': orderId ?? 58},
          );
        } catch (e) {
          Get.snackbar(
            "Order Error",
            "Failed to place order.\n${e.toString()}",
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
        }
      } else {
        await controllersHome.fetchSubscriptions();

      razorpayController.payNow(
        amount: finalTotal,
        orderId: backendOrderId,
        customerName: customerName.isNotEmpty ? customerName : 'Laundry User',
        description: 'Laundry order payment',
        prefillContact: customerPhone.isNotEmpty ? customerPhone : null,
        prefillEmail: customerEmail.isNotEmpty ? customerEmail : null,
        notes: {
          'user_id': '$userIdMy',
          'pickup':
              "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} $selectedPickupSlot",
        },
        onSuccess: (paymentId, orderId, signature) async {
          print("gjgjgjgjggjgjgj onSuccess is ::::::::: $paymentId");
          try {
            await orderController.placeOrder(
              selectedItems: controller.getSelectedCartItems(),
              totalAmount: finalTotal,
              paymentMethod: 1,
              paymentStatus: 1,
              pickupDateTime:
                  "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
              deliveryDateTime:
                  "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(Duration(hours: 72)))}",
              userId: userIdMy,
              addressId: userIdMy,
              transactionId: paymentId,
            );

            await profileController.updateAmountTransactionTable(
                finalTotal, paymentId);

            if (hasSubscription == 1) {
              await profileController.UpdateSubscription(
                userIdMy,
                profileController.currentCount,
                newItems,
              );
            }

            if (controller.activeOfferselected.isNotEmpty && controller.activeOfferselected['type'] == 'first_order') {
              await profileController.markFirstOrderDone(userIdMy);
            }

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
              duration: Duration(seconds: 5),
            );
          }
        },
        onFailure: (code, message) {
          final isCancelled =
              code == 2 || message.toLowerCase().contains('cancel');
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
  final int? hasSubscription;
  final List<String> eligibleItemKeys;
  final VoidCallback onUpdate;

  const _EnhancedItemRow({
    required this.item,
    required this.controller,
    required this.index,
    required this.hasSubscription,
    required this.eligibleItemKeys,
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
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    AppTheme.primaryColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  _buildItemImage(),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['product']['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "Service: ${widget.item['service_name']}",
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 11.h),
                        _buildQuantityControls(),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
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
        borderRadius: BorderRadius.circular(11.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: Image.network(
          widget.item['product']['image'] ??
              'https://eu-images.contentstack.com/v3/assets/blte6b9e99033a702bd/blt7e5c15dd5c6fb1a3/67cacb6c91d4b6c9af49e7e3/Top_Shape_1.jpg?width=954&height=637&format=jpg&quality=80',
          height: 50.h,
          width: 50.w,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 50.h,
            width: 50.w,
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
              size: 21.sp,
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: Color(0xFF1F2937),
            ),
            maxLines: 2, // Allow up to 2 lines
            overflow: TextOverflow.ellipsis, // Handle overflow gracefully
          ),
          SizedBox(height: 6.h), // Increased spacing
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              "Service: ${widget.item['service_name']}",
              style: TextStyle(
                fontSize: 10.sp,
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(87, 104, 171, 1),
              Color.fromRGBO(35, 42, 69, 1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11.r),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(87, 104, 171, 0.3),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11.r),
                  bottomLeft: Radius.circular(11.r),
                ),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(
                    Icons.remove,
                    size: 15.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              child: Obx(() {
                final quantity = widget.controller.cartQuantities[
                        '${widget.item['service']}_${widget.item['product']['id']}'] ??
                    0;
                return Text(
                  "$quantity",
                  style: TextStyle(
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
                borderRadius: BorderRadius.zero,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(
                    Icons.add,
                    size: 15.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              width: 1.w,
              height: 20.h,
              color: Colors.white.withOpacity(0.3),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.controller.addBulkToCart(widget.item['product'], 5);
                  widget.controller.update();
                  widget.onUpdate();
                },
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(11.r),
                  bottomRight: Radius.circular(11.r),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  alignment: Alignment.center,
                  child: Text(
                    '+5',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Obx(() {
      final quantity = widget.controller.cartQuantities[
              '${widget.item['service']}_${widget.item['product']['id']}'] ??
          0;
      final productId = widget.item['product']['id'];
      
      final categoryId = widget.item['product']['category_id'];
      bool isEligible = false;
      if (widget.hasSubscription == 1) {
        if (widget.eligibleItemKeys.isNotEmpty) {
          isEligible = widget.eligibleItemKeys.contains("${categoryId}_${productId}");
        } else {
          isEligible = true; // Fallback
        }
      }

      if (isEligible) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.w,
                ),
              ),
              child: Text(
                "FREE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "via Sub",
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        );
      } else {
        final totalPrice = quantity * widget.item['product']['price'];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.w,
            ),
          ),
          child: Text(
            "\u20B9$totalPrice",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: Color(0xFF1F2937),
            ),
          ),
        );
      }
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
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 11.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8)
                  ],
                )
              : null,
          color: !isSelected ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2.w,
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
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 15.sp,
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
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8)
                  ],
                )
              : null,
          color: !isSelected ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(21.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2.w,
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
              size: 14.sp,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            SizedBox(width: 6.w),
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
