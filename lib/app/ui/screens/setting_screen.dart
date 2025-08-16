import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,)),
        centerTitle: true,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.transparent,
                            child: Image(
                              image:
                                  AssetImage('assets/icons/setting_profile.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(controller.name.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF111827))),
                              Text(controller.phone.value,
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 14)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Your Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      // _buildListTile(Icons.shopping_bag_outlined, "Your Orders",
                      //     onTap: () {
                      //   Get.toNamed('/order_screen');
                      // }),
                      // const _DashedDivider(),
                      _buildListTile(
                          Icons.location_on_outlined, "Saved Address",
                          onTap: () {
                        Get.toNamed('/address_screen');
                      }),
                      const _DashedDivider(),
                      _buildListTile(Icons.person_outline, "Profile", onTap: () {
                        Get.toNamed('/profile_screen');
                      }),
                    ]),
                    const SizedBox(height: 24),
                    const Text("Other Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      // _buildListTile(Icons.notifications_none, "Notifications",
                      //     onTap: () {
                      //   Get.toNamed('/notification_screen');
                      // }),
                      const _DashedDivider(),
                      _buildListTile(Icons.info_outline, "Support",
                          onTap: () {
                        Get.toNamed('/support_screen');
                      }),
                    ]),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            Get.offAllNamed('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: const Text("Log Out",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "App version 18.5.7\nv69-2",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {required Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 22.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => Container(
                width: dashWidth,
                height: 1,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      },
    );
  }
}
