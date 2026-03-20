import 'package:flutter/material.dart';
import 'package:laundry_app/app/constants/app_theme.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.white,
        shadowColor: const Color.fromARGB(255, 158, 158, 158),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Terms and Conditions – VK Laundry",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "VK Laundry Private Limited (hereinafter referred to as “Company”) provides its services subject to your (“Customer”) compliance and acceptance with the terms and conditions set forth below.\n"
              "By availing VK Laundry services, the Customer agrees to be bound by the following Terms and Conditions:",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            // Garment Handling
            buildSectionTitle("Garment Handling and Liability"),
            buildBullet(
              "All garments are inspected at the time of receiving and again at the processing unit.",
            ),
            buildBullet(
              "If any damage or defect (cuts, holes, scratches, stains, etc.) is detected, the same will be informed to the Customer. Such garments will be processed only after Customer confirmation.",
            ),
            buildBullet("VK Laundry follows standard cleaning procedures."),
            buildBullet(
              "The Company will not be held responsible for damage caused due to poor garment quality, old garments, color fading, shrinkage, or prints/embellishments that cannot withstand standard processing.",
            ),
            buildBullet(
              "While every effort is made to remove stains, 100% stain removal is not guaranteed. Processing of stained garments is done strictly at the Customer’s risk.",
            ),
            buildBullet(
              "Undergarments, heavily damaged articles, or garments with pre-existing defects may not be accepted for processing.",
            ),
            buildBullet(
              "The Company is not responsible for loss or damage of personal belongings left in garments, including wallets, money, jewellery, cards, keys, handkerchiefs, pens, etc.",
            ),

            // Compensation
            buildSectionTitle("Compensation Policy"),
            buildBullet(
              "In case of misplacement or damage to the garment the maximum compensation is limited to Rs.2000/-.",
            ),
            buildBullet(
              "The garment for which the compensation is made shall be retained by the company.",
            ),
            buildBullet(
              "The compensation shall be given in the form of service but not by cash. This service shall be used within one month from the date of delivery.",
            ),

            // Delivery
            buildSectionTitle("Delivery and Collection"),
            buildBullet("Wash & Fold – 3 working days."),
            buildBullet("Wash & Iron / Dry Cleaning – 3 working days."),
            buildBullet(
              "Designer wear – timelines will be informed after inspection.",
            ),
            buildBullet(
              "Delays may occur due to unforeseen circumstances. Prior intimation will be given, but no compensation or discounts will be provided.",
            ),
            buildBullet(
              "Processed garments must be collected within 10 days of notification. After 10 days, storage charges of ₹10 per garment per day will apply.",
            ),
            buildBullet(
              "Garments not collected within 30 days may be disposed of by the Company to recover costs.",
            ),
            buildBullet(
              "Customers are requested to check and verify garments at the time of delivery. Once delivery is accepted, VK Laundry will not entertain claims for missing or damaged garments.",
            ),

            // Pricing
            buildSectionTitle("Pricing and Payment"),
            buildBullet(
              "Prices are displayed at the store and/or on the official website/app.",
            ),
            buildBullet(
              "Designer wear tariffs will be decided on a case-to-case basis.",
            ),
            buildBullet(
              "Customers must pay the full invoice amount at the time of delivery.",
            ),
            buildBullet(
              "Payments can be made in cash, card, UPI, or prepaid balance.",
            ),
            buildBullet("Taxes (GST) will be charged as per applicable law."),

            // General Terms
            buildSectionTitle("General Terms"),
            buildBullet(
              "The Company reserves the right to refuse processing of any garment.",
            ),
            buildBullet(
              "The Company is not liable for natural wear and tear, color fading, shrinkage, or damage to delicate fabrics.",
            ),
            buildBullet(
              "Delays or damages due to Force Majeure (fire, burglary, strikes, accidents, natural calamities, etc.) are not covered.",
            ),
            buildBullet(
              "Customers may receive transactional or promotional updates from VK Laundry via SMS, WhatsApp, Calls, Email, or App notifications. Customers can opt out by contacting Customer Care.",
            ),

            // Jurisdiction
            buildSectionTitle("Legal Jurisdiction"),
            buildBullet(
              "All disputes are subject to the jurisdiction of the courts in Hyderabad, Telangana.",
            ),

            // Contact
            buildSectionTitle("Contact"),
            buildBullet("📧 support@vklaundry.com"),
            buildBullet("📞 +91 7995500760"),
          ],
        ),
      ),
    );
  }
}
