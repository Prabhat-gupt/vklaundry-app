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
    backgroundColor: Colors.transparent, // Make background transparent for the effect
    builder: (context) {
      return Container(
        // Glassmorphism effect
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Slight transparency for the effect
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                height: 4,
                width: 60,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Offers",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Offers List
              Obx(() {
                if (activeOffers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        "No active offers available",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: activeOffers.length,
                    itemBuilder: (context, index) {
                      final offer = activeOffers[index];
                      final discountType = offer['discount_type'] ?? 'flat';
                      final discountValue = (offer['discount_value'] ?? 0) as num;
                      final minAmount = (offer['min_amount'] ?? 0) as num;
                      final bool isEligible = totalPrice >= minAmount;
                      final bool isSelected = selectedIndex.value == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [AppTheme.primaryColor, const Color(0xFF5768AB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isEligible
                                ? Colors.green.shade400
                                : Colors.grey.shade300),
                            width: isSelected ? 0 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : (isEligible ? Icons.local_offer_rounded : Icons.lock_rounded),
                              color: isSelected ? Colors.white : (isEligible ? Colors.green : Colors.grey),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer['title'] ?? 'Discount Offer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: isSelected
                                          ? Colors.white
                                          : (isEligible ? const Color(0xFF1F2937) : Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    discountType == 'percentage'
                                        ? "$discountValue% off on orders above ₹$minAmount"
                                        : "₹$discountValue off on orders above ₹$minAmount",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected ? Colors.white70 : (isEligible ? Colors.black54 : Colors.grey),
                                    ),
                                  ),
                                  if (!isEligible && !isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "You are not eligible for this offer.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Apply/Remove Button
                            ElevatedButton(
                              onPressed: isEligible
                                  ? () {
                                if (isSelected) {
                                  selectedIndex.value = -1;
                                  onOfferSelected(null);
                                } else {
                                  selectedIndex.value = index;
                                  onOfferSelected(offer);
                                }
                                Navigator.pop(context);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.red.shade400
                                    : (isEligible ? AppTheme.primaryColor : Colors.grey),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: isEligible ? 5 : 0,
                                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isSelected ? "Remove" : "Apply",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}