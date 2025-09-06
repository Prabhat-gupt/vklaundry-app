import 'package:get/get.dart';

class PaymentSelectController extends GetxController {
  var selectedPaymentMethod = ''.obs;

  // Payment methods with category and options
  final paymentMethods = [
    {
      "category": "UPI",
      "options": [
        {"name": "Google Pay", "icon": "assets/icons/gpay.png"},
        {"name": "PhonePe", "icon": "assets/icons/phonepe.png"},
        {"name": "Paytm", "icon": "assets/icons/paytm.png"},
        {"name": "Amazon Pay", "icon": "assets/icons/amazonpay.png"},
        {"name": "BHIM", "icon": "assets/icons/bhim.png"},
      ]
    },
    {
      "category": "Cards",
      "options": [
        {"name": "Credit Card", "icon": "assets/icons/credit_card.png"},
        {"name": "Debit Card", "icon": "assets/icons/debit_card.png"},
      ]
    },
    {
      "category": "Wallets",
      "options": [
        {"name": "Freecharge", "icon": "assets/icons/freecharge.png"},
        {"name": "Mobikwik", "icon": "assets/icons/mobikwik.png"},
      ]
    },
    {
      "category": "Cash",
      "options": [
        {"name": "Cash on Delivery", "icon": "assets/icons/cash.png"},
      ]
    }
  ];

  void selectPayment(String name) {
    selectedPaymentMethod.value = name;
  }
}
