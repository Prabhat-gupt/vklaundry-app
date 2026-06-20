import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:timelines_plus/timelines_plus.dart';

/// Status mapping (reused)
const ORDER_STATUS = {
  'PENDING': 0,
  'ACCEPTED': 1,
  'PROCESSING': 2,
  'PICKEDUP': 3,
  'IN_TRANSIT': 4,
  'DELIVERED': 5,
  'UNDELIVERED': 6,
  'REJECTED': 7,
};

class TrackOrderPage extends StatefulWidget {
  const TrackOrderPage({super.key});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage>
    with TickerProviderStateMixin {
  final orderTrackController = Get.find<TrackOrderController>();
  
  late final AnimationController _pageLoadController;
  late final AnimationController _headerController;
  late final AnimationController _summaryController;
  late final AnimationController _timelineController;

  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _headerScaleAnimation;
  late final Animation<double> _summaryScaleAnimation;
  late final Animation<Offset> _summarySlideAnimation;
  late final Animation<double> _timelineFadeAnimation;

  bool _isAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    
    // Subscribe to real-time updates for this specific order
    final orderId = Get.arguments['order']?['id'];
    if (orderId != null) {
      orderTrackController.subscribeToOrderChanges(orderId);
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

    _summaryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _timelineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
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

    _summaryScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _summaryController,
        curve: Curves.easeOutBack,
      ),
    );

    _summarySlideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _summaryController,
      curve: Curves.easeOutCubic,
    ));

    _timelineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
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
        await Future.delayed(Duration(milliseconds: 250));
        if (mounted) _summaryController.forward();
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) _timelineController.forward();
      } catch (e) {
        if (mounted) {
          _pageLoadController.forward();
          _headerController.forward();
          _summaryController.forward();
          _timelineController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    orderTrackController.unsubscribeFromOrderChanges();
    _pageLoadController.dispose();
    _headerController.dispose();
    _summaryController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getCurrentOrder() {
    final orderId = Get.arguments['order']?['id'];
    if (orderId == null) return null;
    
    final orders = orderTrackController.order.value['orders'] as List?;
    if (orders == null) return null;
    
    try {
      return orders.firstWhere((o) => o['id'] == orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orderData = _getCurrentOrder() ?? Get.arguments['order'];
      final int status = orderData['status'] ?? 0;
      final statusText = _getStatusText(status);

    return Scaffold(
      backgroundColor: Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15.r),
          child: Column(
            children: [
              _buildAnimatedOrderSummary(orderData, status, statusText),
              SizedBox(height: 18.h),
              _buildAnimatedTimeline(status),
            ],
          ),
        ),
      ),
    );
    });
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: IconButton(
          icon: Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.blue,
              size: 18.sp,
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: ScaleTransition(
          scale: _headerScaleAnimation,
          child: Text(
            'Track Order',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOrderSummary(
      Map<String, dynamic> orderData,
      int status,
      String statusText,
      ) {
    return SlideTransition(
      position: _summarySlideAnimation,
      child: ScaleTransition(
        scale: _summaryScaleAnimation,
        child: Container(
          padding: EdgeInsets.all(23.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _getStatusColor(status).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildOrderHeader(orderData, status, statusText),
              SizedBox(height: 23.h),
              _buildDeliveryInfo(orderData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
      Map<String, dynamic> orderData,
      int status,
      String statusText,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Icon(
                Icons.receipt_long,
                color: Colors.blue,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Order #${orderData['id']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            _buildStatusBadge(status, statusText),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey,
                size: 15.sp,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'Placed on ${DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(orderData['created_at']).toLocal())}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int status, String statusText) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status),
                  _getStatusColor(status).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(23.r),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 15.sp,
                ),
                SizedBox(width: 7.w),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryInfo(Map<String, dynamic> orderData) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: Colors.blue,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected Delivery',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  orderData['delivery_datetime'] ?? 'To be confirmed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTimeline(int status) {
    return FadeTransition(
      opacity: _timelineFadeAnimation,
      child: Container(
        padding: EdgeInsets.all(23.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: Colors.green,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Order Timeline',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            SizedBox(height: 23.h),
            _buildEnhancedTimeline(status),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTimeline(int currentStatus) {
    List<Map<String, dynamic>> steps = [
      {'title': 'Order Placed', 'desc': 'Your order has been received', 'icon': Icons.shopping_cart_rounded},
      {'title': 'Order Confirmed', 'desc': 'Order accepted by laundry', 'icon': Icons.check_circle_outline},
      {'title': 'In Progress', 'desc': 'Your items are being processed', 'icon': Icons.local_laundry_service},
      {'title': 'Picked Up', 'desc': 'Items picked up from your location', 'icon': Icons.local_shipping_outlined},
      {'title': 'Out for Delivery', 'desc': 'Your items are on the way back', 'icon': Icons.directions_car},
      {'title': 'Delivered', 'desc': 'Order completed successfully', 'icon': Icons.done_all},
    ];

    if (currentStatus == 7) {
      steps = [
        {'title': 'Order Placed', 'desc': 'Your order has been received', 'icon': Icons.shopping_cart_rounded},
        {'title': 'Order Rejected', 'desc': 'Order has been rejected/cancelled', 'icon': Icons.cancel_outlined},
      ];
    } else if (currentStatus == 6) {
      steps[5] = {
        'title': 'Delivery Failed',
        'desc': 'Could not deliver the items',
        'icon': Icons.error_outline
      };
    }

    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        connectorTheme: const ConnectorThemeData(
          thickness: 3,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        itemCount: steps.length,
        nodePositionBuilder: (context, index) => 0.15,
        indicatorPositionBuilder: (context, index) => 0.15,
        contentsBuilder: (context, index) {
          final isRejected = currentStatus == 7;
          final isUndelivered = currentStatus == 6;
          
          bool isActive = false;
          if (isRejected) {
            isActive = index <= 1;
          } else if (isUndelivered) {
            isActive = index <= 5;
          } else {
            isActive = index <= currentStatus;
          }

          final step = steps[index];
          final isErrorState = (isRejected && index == 1) || (isUndelivered && index == 5);

          return Padding(
            padding: EdgeInsets.only(left: 32.0.w, bottom: 32.0.h),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset((1 - value) * 50, 0),
                    child: Container(
                      padding: EdgeInsets.all(15.r),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isErrorState
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1))
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isActive
                              ? (isErrorState
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3))
                              : Colors.grey.withOpacity(0.2),
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title']!.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: isActive
                                  ? (isErrorState
                                      ? Colors.red
                                      : Colors.green)
                                  : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            step['desc']!.toString(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        indicatorBuilder: (context, index) {
          final isRejected = currentStatus == 7;
          final isUndelivered = currentStatus == 6;
          
          bool isCompleted = false;
          bool isCurrent = false;
          
          if (isRejected) {
            isCompleted = index < 1;
            isCurrent = index == 1;
          } else if (isUndelivered) {
            isCompleted = index < 5;
            isCurrent = index == 5;
          } else {
            isCompleted = index < currentStatus;
            isCurrent = index == currentStatus;
          }

          final step = steps[index];

          if (isCurrent) {
            if (isRejected || isUndelivered) {
              return _buildAnimatedIndicator(
                color: Colors.red,
                icon: Icons.close,
                index: index,
              );
            }
            if (currentStatus == 5) {
              return _buildAnimatedIndicator(
                color: Colors.green,
                icon: Icons.check_circle,
                index: index,
              );
            }
            return _buildAnimatedIndicator(
              color: Colors.blue,
              icon: step['icon'] as IconData,
              index: index,
            );
          }

          if (isCompleted) {
            return _buildAnimatedIndicator(
              color: Colors.green,
              icon: Icons.check,
              index: index,
            );
          }

          return _buildAnimatedIndicator(
            color: Colors.grey.shade300,
            icon: step['icon'] as IconData,
            index: index,
          );
        },
        connectorBuilder: (context, index, connectorType) {
          final isRejected = currentStatus == 7;
          final isUndelivered = currentStatus == 6;
          
          bool isCompleted = false;
          if (isRejected) {
            isCompleted = index < 1;
          } else if (isUndelivered) {
            isCompleted = index < 5;
          } else {
            isCompleted = index < currentStatus;
          }

          return SolidLineConnector(
            color: isCompleted ? Colors.green : Colors.grey.shade300,
          );
        },
      ),
    );
  }

  Widget _buildAnimatedIndicator({
    required Color color,
    required IconData icon,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        );
      },
    );
  }
}

/// Status Text
String _getStatusText(int status) {
  switch (status) {
    case 0:
      return "Pending";
    case 1:
      return "Accepted";
    case 2:
      return "Processing";
    case 3:
      return "Picked Up";
    case 4:
      return "In Transit";
    case 5:
      return "Delivered";
    case 6:
      return "Undelivered";
    case 7:
      return "Rejected";
    default:
      return "Unknown";
  }
}

/// Status Color
Color _getStatusColor(int status) {
  switch (status) {
    case 0:
      return Colors.orange;
    case 1:
      return Colors.blue;
    case 2:
      return Colors.purple;
    case 3:
      return Colors.teal;
    case 4:
      return Colors.indigo;
    case 5:
      return Colors.green;
    case 6:
      return Colors.deepOrange;
    case 7:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Status Icon
IconData _getStatusIcon(int status) {
  switch (status) {
    case 0:
      return Icons.hourglass_empty;
    case 1:
      return Icons.check_circle_outline;
    case 2:
      return Icons.autorenew;
    case 3:
      return Icons.local_shipping_outlined;
    case 4:
      return Icons.directions_car;
    case 5:
      return Icons.check_circle;
    case 6:
      return Icons.warning_amber_rounded;
    case 7:
      return Icons.cancel;
    default:
      return Icons.help_outline;
  }
}