import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(21.w)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(21.w)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                height: 3.w,
                width: 42.w,
                margin: EdgeInsets.symmetric(vertical: 12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Available Offers",
                      style: TextStyle(
                        fontSize: 17.w,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey, size: 19.w),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Offers List
              Obx(() {
                if (activeOffers.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(17.w),
                    child: Center(
                      child: Text(
                        "No active offers available",
                        style: TextStyle(fontSize: 12.w, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 17.w),
                    itemCount: activeOffers.length,
                    itemBuilder: (context, index) {
                      final offer = activeOffers[index];
                      final discountType = offer['discount_type'] ?? 'flat';
                      final discountValue = (offer['discount_value'] ?? 0) as num;
                      final minAmount = (offer['min_amount'] ?? 0) as num;
                      final bool isEligible = totalPrice >= minAmount;
                      final bool isSelected = selectedIndex.value == index;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(bottom: 15.w),
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFF5768AB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(15.w),
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
                              size: 23.w,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer['title'] ?? 'Discount Offer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.w,
                                      color: isSelected
                                          ? Colors.white
                                          : (isEligible ? Color(0xFF1F2937) : Colors.grey),
                                    ),
                                  ),
                                  SizedBox(height: 5.w),
                                  Text(
                                    discountType == 'percentage'
                                        ? "$discountValue% off on orders above ₹$minAmount"
                                        : "₹$discountValue off on orders above ₹$minAmount",
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      color: isSelected ? Colors.white70 : (isEligible ? Colors.black54 : Colors.grey),
                                    ),
                                  ),
                                  if (!isEligible && !isSelected)
                                    Padding(
                                      padding: EdgeInsets.only(top: 6.w),
                                      child: Text(
                                        "You are not eligible for this offer.",
                                        style: TextStyle(
                                          fontSize: 8.w,
                                          color: Colors.red.shade400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
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
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                elevation: isEligible ? 5 : 0,
                                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 17.w,
                                  vertical: 11.w,
                                ),
                              ),
                              child: Text(
                                isSelected ? "Remove" : "Apply",
                                style: TextStyle(fontWeight: FontWeight.bold),
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