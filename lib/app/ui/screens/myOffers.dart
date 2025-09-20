import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';

void showOffersBottomSheet(
  BuildContext context,
  RxList activeOffers,
  double totalPrice,
  Function(Map<String, dynamic>? offer) onOfferSelected, {
  Map<String, dynamic>? alreadyAppliedOffer,
}) {
  RxInt selectedIndex = (-1).obs;

  if (alreadyAppliedOffer != null) {
    final idx = activeOffers.indexWhere(
      (o) => o['id'] == alreadyAppliedOffer['id'],
    );
    if (idx != -1) selectedIndex.value = idx;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Obx(() {
        if (activeOffers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text("No active offers available")),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Available Offers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeOffers.length,
                  itemBuilder: (context, index) {
                    final offer = activeOffers[index];

                    final discountType = offer['discount_type'] ?? 'flat';
                    final discountValue = (offer['discount_value'] ?? 0) as num;
                    final minAmount = (offer['min_amount'] ?? 0) as num;

                    final bool isSelected = selectedIndex.value == index;
                    final bool isEligible = totalPrice >= minAmount;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer['title'] ?? 'Discount Offer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  discountType == 'percentage'
                                      ? "$discountValue% off on orders above ₹$minAmount"
                                      : "₹$discountValue off on orders above ₹$minAmount",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isEligible ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isEligible
                                ? () {
                                    if (isSelected) {
                                      // Remove selected coupon
                                      selectedIndex.value = -1;
                                      Navigator.pop(context);
                                      onOfferSelected(null);
                                    } else {
                                      // Apply this coupon
                                      selectedIndex.value = index;
                                      Navigator.pop(context);
                                      onOfferSelected(offer);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.red
                                  : (isEligible
                                      ? AppTheme.primaryColor
                                      : Colors.grey),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(isSelected ? "Remove" : "Apply"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
