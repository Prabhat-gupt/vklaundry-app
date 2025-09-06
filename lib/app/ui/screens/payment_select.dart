import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/payment_select_controller.dart';

class PaymentSelectPage extends StatelessWidget {
  final paymentController = Get.find<PaymentSelectController>();

  PaymentSelectPage({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentTile({
    required String title,
    required IconData icon,
    required String value,
  }) {
    return Obx(() {
      return ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: Radio<String>(
          value: value,
          groupValue: paymentController.selectedPaymentMethod.value,
          onChanged: (val) => paymentController.selectPayment(val!),
        ),
        onTap: () => paymentController.selectPayment(value),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        centerTitle: true,
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('UPI'),
          _buildPaymentTile(
              title: 'Google Pay',
              icon: Icons.account_balance_wallet,
              value: 'GPay'),
          _buildPaymentTile(
              title: 'PhonePe', icon: Icons.phone_android, value: 'Phonepe'),
          _buildPaymentTile(
              title: 'Paytm', icon: Icons.payment, value: 'Paytm'),
          _buildPaymentTile(
              title: 'Amazon Pay', icon: Icons.shopping_cart, value: 'Amazonpay'),

          const Divider(),

          _buildSectionTitle('Net Banking'),
          _buildPaymentTile(
              title: 'Net Banking',
              icon: Icons.account_balance,
              value: 'netbanking'),

          const Divider(),

          _buildSectionTitle('Credit/Debit Card'),
          _buildPaymentTile(
              title: 'Credit/Debit Card',
              icon: Icons.credit_card,
              value: 'card'),

          const Divider(),

          _buildSectionTitle('Cash on Delivery'),
          _buildPaymentTile(
              title: 'Cash on Delivery', icon: Icons.money, value: 'cod'),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          bool isSelected = paymentController.selectedPaymentMethod.value.isNotEmpty;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isSelected
                ? () {
                    // Go back and pass the selected method
                    Get.back();
                  }
                : null,
            child: const Text('Continue', style: TextStyle(fontSize: 18)),
          );
        }),
      ),
    );
  }
}
