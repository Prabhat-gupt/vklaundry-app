import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/orders_controller.dart';
import 'package:laundry_app/app/controllers/productlist_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ProductListController controller = Get.find<ProductListController>();

  final OrderController orderController = Get.put(OrderController());

  final ProfileController profileController = Get.find<ProfileController>();

  DateTime? selectedPickupDate;

  String? selectedPickupSlot;

  final List<String> pickupSlots = ["7AM to 10AM", "5PM to 8PM"];

  @override
  Widget build(BuildContext context) {
    final selectedItems = controller.getSelectedCartItems();
    final double itemsTotal = controller.calculateItemsTotal();
    final double deliveryCharge = 24.0;
    final double handlingCharge = 10.0;
    final double grandTotal = itemsTotal + deliveryCharge + handlingCharge;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUnifiedServiceCard(selectedItems),
            const SizedBox(height: 10),
            _buildPickupSlotSelector(context),
            if (selectedPickupDate != null && selectedPickupSlot != null)
              _buildDeliveryDateDisplay(),
            const SizedBox(height: 20),
            _buildBillDetails(
                itemsTotal, deliveryCharge, handlingCharge, grandTotal),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, grandTotal),
    );
  }

  Widget _buildUnifiedServiceCard(List<Map<String, dynamic>> items) {
    print("Numbers of items: $items");
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
          const Text("Selected Items",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item['product']['image'] ?? 'assets/icons/shirt.png',
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
                          Text(item['product']['name'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text("Service: ${item['service_name']}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(87, 104, 171, 1),
                            Color.fromRGBO(35, 42, 69, 1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.removeFromCart(item['product']);
                              controller.update();
                            },
                            child: const Icon(Icons.remove,
                                size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Obx(() {
                            final quantity = controller.cartQuantities[
                                    '${item['service']}_${item['product']['id']}'] ??
                                0;
                            return Text("$quantity",
                                style: const TextStyle(color: Colors.white));
                          }),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              controller.addToCart(item['product']);
                              controller.update();
                            },
                            child: const Icon(Icons.add,
                                size: 16, color: Colors.white),
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
                    // Text("\u20B9${item['product']['price'] ?? ''}")
                  ],
                ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Missed something?",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(87, 104, 171, 1),
                      Color.fromRGBO(35, 42, 69, 1)
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
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("+ Add More Items"),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails(double itemsTotal, double deliveryCharge,
      double handlingCharge, double grandTotal) {
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
          const Text("Bill details",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _billRow("Items total", "\u20B9${itemsTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _billRow(
              "Delivery charge", "\u20B9${deliveryCharge.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _billRow(
              "Handling charge", "\u20B9${handlingCharge.toStringAsFixed(2)}"),
          const Divider(height: 24),
          _billRow("Grand Total", "\u20B9${grandTotal.toStringAsFixed(2)}",
              isBold: true),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildPickupSlotSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Pickup Date & Slot",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Column(
                    children: [
                      Text(DateFormat.E().format(date),
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text(date.day.toString(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Select Time Slot",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  fontWeight: FontWeight.w500),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                DateFormat('EEEE, MMM d, yyyy  |  hh:mm a')
                    .format(deliveryDate),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, double grandTotal) {
    final userId = profileController.dbUserId.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryColor, size: 40),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Pick Up from\nSy.No. 540'A, Gowdaval...",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment,
                          color: AppTheme.lightTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text("PAY USING"),
                    ],
                  ),
                  const Text("Google Pay UPI",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                    (selectedPickupDate != null && selectedPickupSlot != null)
                        ? () async {
                            try {
                              // final orderId = await orderController.placeOrder(
                              //   selectedItems: controller.getSelectedCartItems(),
                              //   totalAmount: grandTotal,
                              //   paymentMethod: 'Google Pay UPI',
                              //   paymentStatus: 'paid',
                              //   userId: userId,
                              //   addressId: 1,
                              // );
                              Get.toNamed(
                                AppRoutes.SUCCESS,
                                arguments: {
                                  'order_id': 58,
                                },
                              );
                            } catch (e) {
                              Get.snackbar("Error", "Failed to place order: $e",
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white);
                            }
                          }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("\u20B9${grandTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const Text("Total",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                    const SizedBox(width: 25),
                    const Text("Place Order",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
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
