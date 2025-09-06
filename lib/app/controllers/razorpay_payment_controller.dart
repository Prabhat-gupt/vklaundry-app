import 'dart:developer';

import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentController extends GetxController {
  late Razorpay _razorpay;

  // Expose payment states if you want to observe from UI
  final isPaying = false.obs;
  final lastError = RxnString();
  final lastPaymentId = RxnString();
  final lastOrderId = RxnString();
  final lastSignature = RxnString();

  // Replace with your key (or inject via constructor/env)
  final String razorpayKeyId;

  RazorpayPaymentController({required this.razorpayKeyId});

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    // VERY IMPORTANT to avoid leaks/crashes on hot reload/back nav
    _razorpay.clear();
    super.onClose();
  }

  /// Opens Razorpay Checkout.
  ///
  /// [amount] in INR (will be converted to paise).
  /// [orderId] is optional but recommended if you create Razorpay orders from your backend.
  /// [prefillContact], [prefillEmail] improve UX.
  /// [notes] will be visible in Razorpay dashboard/payment object.
  /// [onSuccess] will be invoked with `(paymentId, orderId, signature)` on success.
  /// [onFailure] invoked with `(code, message)` on failure.
  void payNow({
    required double amount,
    String? orderId,
    String? customerName,
    String? description,
    String? prefillContact,
    String? prefillEmail,
    Map<String, String>? notes,
    required void Function(String paymentId, String? orderId, String? signature)
        onSuccess,
    required void Function(int code, String message) onFailure,
  }) {
    if (amount <= 0) {
      onFailure(-1, 'Invalid amount');
      return;
    }

    // Convert to paise, guard for floating errors
    final int amountInPaise = (amount * 100).round();

    final options = {
      'key': 'rzp_test_R5aav0MP84trbb',
      'amount': amountInPaise,
      'currency': 'INR',
      if (orderId != null) 'order_id': orderId,
      'name': customerName ?? 'Laundry App',
      'description': description ?? 'Order payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        if (prefillContact != null) 'contact': prefillContact,
        if (prefillEmail != null) 'email': prefillEmail,
      },
      'notes': notes ?? {},
      'theme': {
        'color': '#2563EB', // brand-ish (ignored by some UIs)
      },
    };

    try {
      isPaying.value = true;
      lastError.value = null;
      _pendingSuccess = onSuccess;
      _pendingFailure = onFailure;
      _razorpay.open(options);
    } catch (e, st) {
      isPaying.value = false;
      lastError.value = 'Unable to open Razorpay: $e';
      log('Razorpay open error: $e\n$st');
      onFailure(-2, 'Unable to start payment: $e');
    }
  }

  // Store callbacks for this payment attempt
  void Function(String paymentId, String? orderId, String? signature)?
      _pendingSuccess;
  void Function(int code, String message)? _pendingFailure;

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    isPaying.value = false;
    lastPaymentId.value = response.paymentId;
    lastOrderId.value = response.orderId;
    lastSignature.value = response.signature;

    try {
      _pendingSuccess?.call(
        response.paymentId ?? '',
        response.orderId,
        response.signature,
      );
    } catch (e, st) {
      log('onSuccess callback error: $e\n$st');
    } finally {
      _clearPending();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isPaying.value = false;

    final code = response.code;
    final message = (response.message is String)
        ? (response.message as String)
        : (response.message?.toString() ?? 'Unknown error');

    lastError.value = '($code) $message';

    // Common Razorpay codes:
    // 0-unknown, 2-payment_cancelled, etc.
    try {
      _pendingFailure?.call(code!, message);
    } catch (e, st) {
      log('onFailure callback error: $e\n$st');
    } finally {
      _clearPending();
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // If you want to accept payments via external wallets like Paytm,
    // you can handle it here. For now, just log.
    log('External wallet selected: ${response.walletName}');
  }

  void _clearPending() {
    _pendingSuccess = null;
    _pendingFailure = null;
  }
}
