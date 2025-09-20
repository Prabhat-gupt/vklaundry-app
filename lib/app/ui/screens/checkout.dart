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

class _CheckoutPageState extends State<CheckoutPage> {
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

  @override
  void initState() {
    super.initState();
    controller.activeOfferselected.value = {};
    discountApplied = false;

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
      // print("has selectedItems is ::::::::: ${selectedItems}");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter out items with zero quantity
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

    // currently applied offer (Map<String, dynamic> or empty if none)
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
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () async {
            Get.back();
            await controllersHome.fetchSubscriptions();
          },
          child: Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: WillPopScope(
        onWillPop: () async {
          await controllersHome.fetchSubscriptions();
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUnifiedServiceCard(selectedItems),
              const SizedBox(height: 10),
              _buildPickupSlotSelector(context),
              if (selectedPickupDate != null && selectedPickupSlot != null)
                _buildDeliveryDateDisplay(),
              const SizedBox(height: 10),

              /// Offers Section
              hasSubscription == 1
                  ? SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          showOffersBottomSheet(
                            context,
                            controller.activeOffer,
                            grandTotal,
                            (selectedOffer) {
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
                        child: const Text("View Offers"),
                      ),
                    ),

              const SizedBox(height: 10),

              /// Bill Details
              hasSubscription == 1
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, finalTotal, paymentMethod),
    );
  }

  Widget _buildUnifiedServiceCard(List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Selected Items",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['product']['image'] ??
                          'https://eu-images.contentstack.com/v3/assets/blte6b9e99033a702bd/blt7e5c15dd5c6fb1a3/67cacb6c91d4b6c9af49e7e3/Top_Shape_1.jpg?width=954&height=637&format=jpg&quality=80',
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product']['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Service: ${item['service_name']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(87, 104, 171, 1),
                          Color.fromRGBO(35, 42, 69, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            controller.removeFromCart(item['product']);
                            controller.update();
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.remove,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final quantity = controller.cartQuantities[
                                  '${item['service']}_${item['product']['id']}'] ??
                              0;
                          return Text(
                            "$quantity",
                            style: const TextStyle(color: Colors.white),
                          );
                        }),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.addToCart(item['product']);
                            controller.update();
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    final quantity = controller.cartQuantities[
                            '${item['service']}_${item['product']['id']}'] ??
                        0;
                    final totalPrice = quantity * item['product']['price'];
                    return Text("\u20B9$totalPrice");
                  }),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Missed something?",
                style: TextStyle(fontWeight: FontWeight.w500),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("+ Add More Items"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Update bill details to accept discount and label
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bill details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _billRow("Items total", "\u20B9${itemsTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _billRow(
            "Delivery charge",
            "\u20B9${deliveryCharge.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 8),
          _billRow(
            "Handling charge",
            "\u20B9${handlingCharge.toStringAsFixed(2)}",
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _billRow(
              "Discount",
              "-\u20B9${discount.toStringAsFixed(2)}",
              isBold: true,
            ),
            Text(discountLabel, style: const TextStyle(color: Colors.green)),
          ],
          const Divider(height: 24),
          // storage.read('subscriptionCheck') == 1
          //     ? _billRow("Grand Total", "0", isBold: true)
          //     :
          _billRow(
            "Grand Total",
            hasSubscription == 1
                ? "0"
                : "\u20B9${finalTotal.toStringAsFixed(2)}",
            isBold: true,
          ),
        ],
      ),
    );
  }

  // without suscription codeWritten
  Widget _buildBillDetailWithoutSubscription(
    double itemsTotal,
    int? totalItemDelivered,
  ) {
    final int totalSubscriptionItems = 30; // fixed total
    final int delivered = totalItemDelivered ?? 0; // avoid null
    final int newItems = controller.getTotalCartItems(); // new added items
    final int remaining = totalSubscriptionItems - (delivered + newItems);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bill details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _billRow("Total Subscription items", "$totalSubscriptionItems"),
          const SizedBox(height: 8),
          _billRow("New Items Added", "$newItems"),
          const SizedBox(height: 8),
          _billRow("Previous Items", "$delivered"),
          const SizedBox(height: 8),
          _billRow("Remaining Items", "$remaining", isBold: true),
        ],
      ),
    );
  }

  // ---------

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupSlotSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Pickup Date & Slot",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              DateTime date = DateTime.now().add(Duration(days: index));
              bool isSelected = selectedPickupDate != null &&
                  DateUtils.isSameDay(selectedPickupDate, date);
              return GestureDetector(
                onTap: () {
                  setState(() => selectedPickupDate = date);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E().format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Select Time Slot",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: pickupSlots.map((slot) {
            bool isSelected = slot == selectedPickupSlot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (_) {
                setState(() => selectedPickupSlot = slot);
              },
              checkmarkColor: Colors.white,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Colors.grey.shade200,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeliveryDateDisplay() {
    if (selectedPickupDate == null) {
      return const SizedBox();
    }

    final deliveryDate = selectedPickupDate!.add(const Duration(hours: 72));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Expected Delivery",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.blueGrey),
              const SizedBox(width: 10),
              Text(
                DateFormat(
                  'EEEE, MMM d, yyyy  |  hh:mm a',
                ).format(deliveryDate),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    double grandTotal,
    String? paymentMethod,
  ) {
    // final userId = profileController.dbUserId.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row(
          //   children: [
          //     Icon(Icons.location_on, color: AppTheme.primaryColor, size: 40),
          //     const SizedBox(width: 8),
          //     const Expanded(
          //       child: Text(
          //         "Pick Up from\nSy.No. 540'A, Gowdaval...",
          //         style: TextStyle(fontWeight: FontWeight.w500),
          //       ),
          //     ),
          //     const Icon(Icons.keyboard_arrow_down),
          //   ],
          // ),
          // const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: (selectedPickupDate != null &&
                        selectedPickupSlot != null)
                    ? () async {
                        final userIdMy = profileController.storages.read(
                          'userId',
                        );

                        final checkUserScreen =
                            await profileController.checkUserPincode(userIdMy);

                        print(
                          "check user screen here is :::::: $checkUserScreen",
                        );

                        if (checkUserScreen == false) {
                          Get.toNamed('/setup_screen');
                          return;
                        }

                        final customerName = profileController.name.value;
                        final customerPhone = profileController.phone.value;
                        final customerEmail = profileController.email.value;

                        final int totalSubscriptionItems = 30; // fixed total
                        // final int delivered =
                        //     totalItemDelivered ?? 0; // avoid null
                        final int newItems =
                            controller.getTotalCartItems(); // new added items
                        final num remaining = totalSubscriptionItems -
                            (profileController.currentCount);

                        final String? backendOrderId = null;
                        print("my hasSubscription is ::::::: $hasSubscription");
                        if (hasSubscription == 1) {
                          print(
                            "my remaining is :::: ${profileController.currentCount} ad ${remaining}",
                          );
                          int total = profileController.currentCount + newItems;

                          print(
                            "my item toal $total and $totalSubscriptionItems is ::::: ${total == totalSubscriptionItems}",
                          );
                          if (total > totalSubscriptionItems) {
                            Get.snackbar(
                              "Place order remaining",
                              "Remanining orders $remaining",
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                            );
                          } else if (total < totalSubscriptionItems ||
                              total == totalSubscriptionItems) {
                            await orderController.placeOrder(
                              selectedItems: controller.getSelectedCartItems(),
                              totalAmount: grandTotal,
                              paymentMethod: 'Subscription',
                              paymentStatus: 'paid',
                              pickupDateTime:
                                  "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
                              deliveryDateTime:
                                  "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(const Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(const Duration(hours: 72)))}",
                              userId: userIdMy,
                              addressId:
                                  userIdMy, // replace with actual address id if needed
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
                          // Start Razorpay payment
                          await controllersHome.fetchSubscriptions();

                          razorpayController.payNow(
                            amount: grandTotal,
                            orderId:
                                backendOrderId, // keep null if not using server-created order
                            customerName: customerName.isNotEmpty
                                ? customerName
                                : 'Laundry User',
                            description: 'Laundry order payment',
                            prefillContact:
                                customerPhone.isNotEmpty ? customerPhone : null,
                            prefillEmail:
                                customerEmail.isNotEmpty ? customerEmail : null,
                            notes: {
                              'user_id': '$userIdMy',
                              'pickup':
                                  "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} $selectedPickupSlot",
                            },
                            onSuccess: (paymentId, orderId, signature) async {
                              print(
                                "gjgjgjgjggjgjgj onSuccess is ::::::::: $paymentId",
                              );
                              try {
                                // Mark payment & place order in your DB
                                await orderController.placeOrder(
                                  selectedItems:
                                      controller.getSelectedCartItems(),
                                  totalAmount: grandTotal,
                                  paymentMethod: 'Razorpay',
                                  paymentStatus: 'paid',
                                  pickupDateTime:
                                      "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!)} : $selectedPickupSlot",
                                  deliveryDateTime:
                                      "${DateFormat('yyyy-MM-dd').format(selectedPickupDate!.add(const Duration(hours: 72)))} : ${DateFormat('HH:mm').format(selectedPickupDate!.add(const Duration(hours: 72)))}",
                                  userId: userIdMy,
                                  addressId:
                                      userIdMy, // replace with actual address id if you have it
                                  // If your order table wants paymentId/signature/orderId, add parameters to placeOrder
                                  transactionId: paymentId,
                                );

                                await profileController
                                    .updateAmountTransactionTable(
                                  grandTotal,
                                  paymentId,
                                );
                                Get.snackbar(
                                  "Payment successful",
                                  "ID: $paymentId",
                                  backgroundColor: Colors.green.shade600,
                                  colorText: Colors.white,
                                );

                                // Navigate to success screen (replace with real order id if you have it)
                                Get.offAllNamed(
                                  AppRoutes.SUCCESS,
                                  arguments: {'order_id': 58},
                                );
                              } catch (e) {
                                // Payment succeeded but order place failed: show a clear message
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
                              // Unified error UI with helpful text
                              final isCancelled = code == 2 ||
                                  message.toLowerCase().contains('cancel');
                              Get.snackbar(
                                isCancelled
                                    ? "Payment cancelled"
                                    : "Payment failed",
                                isCancelled
                                    ? "You cancelled the payment."
                                    : "($code) $message",
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                              );
                            },
                          );
                        } else {
                          // Subscription limit exceeded
                          // Get.snackbar(
                          //   "Subscription Limit Exceeded",
                          //   "You have exceeded your subscription limit. Please contact support or choose Pay Now.",
                          //   backgroundColor: Colors.red.shade600,
                          //   colorText: Colors.white,
                          // );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  children: [
                    hasSubscription == 1
                        ? SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "\u20B9${grandTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                "Total",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(width: 25),
                    const Text(
                      "Place Order",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
