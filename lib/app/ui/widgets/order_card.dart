import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/order_track_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

/// 🔹 Status mapping
const ORDER_STATUS = {
  'PENDING': 0,
  'ACCEPTED': 1,
  'PROCESSING': 2,
  'COMPLETED': 3,
  'REJECTED': 4,
};

class OrderCard extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final int numbersOrders;

  const OrderCard({
    super.key,
    required this.orders,
    required this.numbersOrders,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(numbersOrders, (index) {
          final order = orders[index];
          final int status = order['status'] ?? 0;
          final String statusText = _getStatusText(status);
          print("my order is rejected here :::::: ${orders[index]}");
          return GestureDetector(
            onTap: () => _showOrderDetail(context, order),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔹 Left side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'Placed: ${_formatDateTimeWithTime(order['created_at'])}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  // 🔹 Right side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order['amount']?.toString() ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          '$statusText • ${_formatTimeOnly(order['updated_at'] ?? order['created_at'])}',
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('yyyy-MM-dd').format(date);
  } catch (e) {
    return '';
  }
}

String _formatDateTimeWithTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  try {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  } catch (e) {
    return '';
  }
}

String _formatTimeOnly(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  try {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('hh:mm a').format(date);
  } catch (e) {
    return '';
  }
}

void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
  final orderTrackController = Get.find<TrackOrderController>();
  final int orderId = order['id'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            ),
            child: Obx(() {
              // Get updated order data from controller
              final ordersData = orderTrackController.order['orders'] ?? [];
              final currentOrder = ordersData.firstWhere(
                (o) => o['id'] == orderId,
                orElse: () => order,
              );

              final int status = currentOrder['status'] ?? 0;
              final String statusText = _getStatusText(status);

              return SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(13.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${currentOrder['id']?.toString() ?? ''}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Ordered on: ${_formatDateTimeWithTime(currentOrder['created_at'])}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 13.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Status',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10.sp)),
                                SizedBox(height: 5.h),
                                Text(
                                  _getPaymentStatusText(currentOrder['payment_status']),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getPaymentStatusColor(currentOrder['payment_status'])),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Mode',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10.sp)),
                                SizedBox(height: 5.h),
                                Text(
                                  _getPaymentModeText(currentOrder['payment_mode'] ?? currentOrder['payment_method']),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13.h),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup Date & Time',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10.sp)),
                                SizedBox(height: 5.h),
                                Text(
                                  currentOrder['pickup_datetime'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery Date & Time',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10.sp)),
                                SizedBox(height: 5.h),
                                Text(
                                  currentOrder['delivery_datetime'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13.h),
                    Text('Items',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10.h),
                    ...List.generate(currentOrder['items']?.length ?? 0, (i) {
                      final item = currentOrder['items'][i];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product']?['name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['service_name']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item['quantity']} item'),
                                Text(
                                  '₹${item['price']}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 13.h),
                    Divider(color: Colors.grey.shade300),

                    // 🔹 Price Summary
                    _priceRow(
                      'Subtotal',
                      '₹${(currentOrder['amount'] - 2)?.toString() ?? '0'}',
                    ),
                    _priceRow('Delivery Fee', '₹5'),
                    _priceRow(
                      'Total',
                      '₹${currentOrder['amount']?.toString() ?? '0'}',
                      isBold: true,
                      isTotal: true,
                    ),

                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        icon:
                            Icon(Icons.location_on, color: Colors.white),
                        label: Text(
                          'Track Order',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.TRACKING,
                            arguments: {'order': currentOrder},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      );
    },
  );
}

Widget _priceRow(
  String title,
  String price, {
  bool isBold = false,
  bool isTotal = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.blue : Colors.black,
          ),
        ),
      ],
    ),
  );
}

/// 🔹 Status text mapper
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

/// 🔹 Status Icon
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

/// 🔹 Payment Status Text
String _getPaymentStatusText(dynamic status) {
  if (status == null) return "PENDING";
  if (status is int) {
    if (status == 1) return "PAID";
    if (status == 2) return "FAILED";
    return "PENDING";
  }
  return status.toString().toUpperCase();
}

/// 🔹 Payment Status Color
Color _getPaymentStatusColor(dynamic status) {
  if (status == null) return Colors.orange;
  if (status is int) {
    if (status == 1) return Colors.green;
    if (status == 2) return Colors.red;
    return Colors.orange;
  }
  final str = status.toString().toLowerCase();
  if (str == 'paid' || str == 'success') return Colors.green;
  if (str == 'failed') return Colors.red;
  return Colors.orange;
}

/// 🔹 Payment Mode Text
String _getPaymentModeText(dynamic mode) {
  if (mode == null) return "N/A";
  if (mode is int) {
    if (mode == 0) return "CASH";
    if (mode == 1) return "ONLINE";
    return "UNKNOWN";
  }
  return mode.toString().toUpperCase();
}

/// 🔹 Status color mapper
Color _getStatusColor(int status) {
  switch (status) {
    case 0:
      return Colors.orange; // Pending
    case 1:
      return Colors.blue; // Accepted
    case 2:
      return Colors.purple; // Processing
    case 3:
      return Colors.teal; // Picked Up
    case 4:
      return Colors.indigo; // In Transit
    case 5:
      return Colors.green; // Delivered
    case 6:
      return Colors.deepOrange; // Undelivered
    case 7:
      return Colors.red; // Rejected
    default:
      return Colors.grey;
  }
}