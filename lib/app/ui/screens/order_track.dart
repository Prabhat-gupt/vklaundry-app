import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

/// Status mapping (reused)
const ORDER_STATUS = {
  'PENDING': 0,
  'ACCEPTED': 1,
  'PROCESSING': 2,
  'COMPLETED': 3,
  'REJECTED': 4,
};

class TrackOrderPage extends StatefulWidget {
  const TrackOrderPage({super.key});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage>
    with TickerProviderStateMixin {
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

    _summaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _timelineController = AnimationController(
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
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _headerController.forward();
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) _summaryController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
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
    _pageLoadController.dispose();
    _headerController.dispose();
    _summaryController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderData = Get.arguments['order'];
    final int status = orderData['status'] ?? 0;
    final statusText = _getStatusText(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: _buildAnimatedAppBar(),
      body: FadeTransition(
        opacity: _pageOpacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAnimatedOrderSummary(orderData, status, statusText),
              const SizedBox(height: 20),
              _buildAnimatedTimeline(status),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.blue,
              size: 20,
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: ScaleTransition(
          scale: _headerScaleAnimation,
          child: const Text(
            'Track Order',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 24),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order #${orderData['id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            _buildStatusBadge(status, statusText),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Placed on ${DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(orderData['created_at']).toLocal())}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
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
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status),
                  _getStatusColor(status).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
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
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expected Delivery',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderData['delivery_datetime'] ?? 'To be confirmed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Timeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildEnhancedTimeline(status),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTimeline(int currentStatus) {
    final steps = [
      {
        'title': 'Order Placed',
        'desc': 'Your order has been received',
        'icon': Icons.shopping_cart_rounded
      },
      {
        'title': 'Order Confirmed',
        'desc': 'We are preparing your order',
        'icon': Icons.check_circle_outline
      },
      {
        'title': 'In Progress',
        'desc': 'Your items are being processed',
        'icon': Icons.local_laundry_service
      },
      {
        'title': 'Ready for Delivery',
        'desc': 'Order completed and ready',
        'icon': Icons.done_all
      },
    ];

    if (currentStatus == 4) {
      steps[3] = {
        'title': 'Order Cancelled',
        'desc': 'Order has been cancelled',
        'icon': Icons.cancel_outlined
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
          final isActive = (currentStatus != 4 && index <= currentStatus) ||
              (currentStatus == 4 && index == 3);
          final step = steps[index];

          return Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 32.0),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset((1 - value) * 50, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (currentStatus == 4 && index == 3
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1))
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? (currentStatus == 4 && index == 3
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3))
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title']!.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isActive
                                  ? (currentStatus == 4 && index == 3
                                  ? Colors.red
                                  : Colors.green)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['desc']!.toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
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
          final isCompleted = currentStatus == 3;
          final isRejected = currentStatus == 4;
          final step = steps[index];

          if (isRejected) {
            if (index == 3) {
              return _buildAnimatedIndicator(
                color: Colors.red,
                icon: Icons.close,
                index: index,
              );
            } else {
              return _buildAnimatedIndicator(
                color: Colors.grey,
                icon: Icons.radio_button_unchecked,
                index: index,
              );
            }
          }

          if (index < currentStatus) {
            return _buildAnimatedIndicator(
              color: Colors.green,
              icon: Icons.check,
              index: index,
            );
          } else if (index == currentStatus) {
            if (isCompleted) {
              return _buildAnimatedIndicator(
                color: Colors.green,
                icon: Icons.check_circle,
                index: index,
              );
            } else {
              return _buildAnimatedIndicator(
                color: Colors.blue,
                icon: step['icon'] as IconData,
                index: index,
              );
            }
          } else {
            return _buildAnimatedIndicator(
              color: Colors.grey.shade300,
              icon: step['icon'] as IconData,
              index: index,
            );
          }
        },
        connectorBuilder: (context, index, connectorType) {
          Color connectorColor;
          if (currentStatus == 4) {
            connectorColor = Colors.grey.shade300;
          } else if (index < currentStatus) {
            connectorColor = Colors.green;
          } else {
            connectorColor = Colors.grey.shade300;
          }
          return SolidLineConnector(color: connectorColor);
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
            width: 32,
            height: 32,
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
              size: 20,
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
      return "Completed";
    case 4:
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
      return Colors.green;
    case 4:
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
      return Icons.check_circle;
    case 4:
      return Icons.cancel;
    default:
      return Icons.help_outline;
  }
}