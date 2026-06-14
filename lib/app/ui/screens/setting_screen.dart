import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/home_page_controller.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:laundry_app/app/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_app/app/ui/widgets/terms_conditions.dart';
import 'package:laundry_app/app/ui/widgets/privacy_policy.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final controller = Get.find<ProfileController>();

  late final AnimationController _pageLoadController;
  late final AnimationController _profileCardController;
  late final AnimationController _sectionsController;
  late final AnimationController _logoutButtonController;

  late final Animation<double> _pageOpacityAnimation;
  late final Animation<Offset> _profileSlideAnimation;
  late final Animation<double> _profileScaleAnimation;
  late final Animation<Offset> _sectionsSlideAnimation;
  late final Animation<double> _sectionsOpacityAnimation;
  late final Animation<double> _logoutButtonAnimation;

  bool _isAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Initialize animation controllers with reasonable durations
    _pageLoadController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _profileCardController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _sectionsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    _logoutButtonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    // Initialize animations with safer curves
    _pageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageLoadController,
        curve: Curves.easeInOut,
      ),
    );

    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _profileCardController,
      curve: Curves.easeOutCubic,
    ));

    _profileScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileCardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _sectionsSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sectionsController,
      curve: Curves.easeOutCubic,
    ));

    _sectionsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sectionsController,
        curve: Curves.easeInOut,
      ),
    );

    _logoutButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutButtonController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _startAnimationSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isAnimationStarted) return;
      _isAnimationStarted = true;

      try {
        // Start page load animation
        _pageLoadController.forward();

        // Check guest mode
        final prefs = await SharedPreferences.getInstance();
        final isGuest = prefs.getBool('isGuest') ?? false;
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        final isGuestMode = isGuest && !isLoggedIn;

        if (!isGuestMode) {
          final userId = prefs.getInt('user_id');
          if (userId != null) {
            await controller.fetchUserProfile(userId);
          }
        }

        if (!mounted) return;

        // Start staggered animations
        await Future.delayed(Duration(milliseconds: 100));
        if (mounted) _profileCardController.forward();

        await Future.delayed(Duration(milliseconds: 200));
        if (mounted) _sectionsController.forward();

        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) _logoutButtonController.forward();
      } catch (e) {
        // Handle any animation errors gracefully
        if (mounted) {
          _pageLoadController.forward();
          _profileCardController.forward();
          _sectionsController.forward();
          _logoutButtonController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _profileCardController.dispose();
    _sectionsController.dispose();
    _logoutButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomePageController>();
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F8),
      body: Obx(
        () {
          // Show guest screen if in guest mode
          if (homeController.isGuestMode.value) {
            return _buildGuestScreen(context);
          }
          return controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _pageOpacityAnimation,
                  child: Column(
                    children: [
                      _buildGradientHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: 17.w,
                            vertical: 18.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnimatedSection(
                                icon: Icons.person_pin_rounded,
                                iconColor: Color(0xFF3D52A0),
                                "Your Information",
                                [
                                  _EnhancedListTile(
                                    icon: Icons.location_on_rounded,
                                    iconColor: Color(0xFF2DC9B7),
                                    title: "Saved Address",
                                    subtitle: "Manage your delivery locations",
                                    onTap: () => Get.toNamed('/address_screen'),
                                    delay: 0,
                                  ),
                                  Divider(height: 1.w, indent: 64, endIndent: 16, color: Color(0xFFEEEFF3)),
                                  _EnhancedListTile(
                                    icon: Icons.manage_accounts_rounded,
                                    iconColor: Color(0xFF9C6FFF),
                                    title: "Profile",
                                    subtitle: "Edit your personal information",
                                    onTap: () => Get.toNamed('/profile_screen'),
                                    delay: 100,
                                  ),
                                ],
                              ),
                              SizedBox(height: 18.h),
                              _buildAnimatedSection(
                                icon: Icons.info_outline_rounded,
                                iconColor: Color(0xFFFF8C42),
                                "Other Information",
                                [
                                  _EnhancedListTile(
                                    icon: Icons.support_agent_rounded,
                                    iconColor: Color(0xFF2DC9B7),
                                    title: "Support",
                                    subtitle: "Get help and contact us",
                                    onTap: () => Get.toNamed('/support_screen'),
                                    delay: 200,
                                  ),
                                  Divider(height: 1.w, indent: 64, endIndent: 16, color: Color(0xFFEEEFF3)),
                                  _EnhancedListTile(
                                    icon: Icons.article_rounded,
                                    iconColor: Color(0xFFFFB800),
                                    title: "Terms & Conditions",
                                    subtitle: "Read our terms and policies",
                                    onTap: () =>
                                        Get.to(() => const TermsAndConditionsPage()),
                                    delay: 300,
                                  ),
                                  Divider(height: 1.w, indent: 64, endIndent: 16, color: Color(0xFFEEEFF3)),
                                  _EnhancedListTile(
                                    icon: Icons.privacy_tip_rounded,
                                    iconColor: Color(0xFF2196F3),
                                    title: "Privacy Policy",
                                    subtitle: "How we protect your data",
                                    onTap: () =>
                                        Get.to(() => const PrivacyPolicyPage()),
                                    delay: 400,
                                  ),
                                ],
                              ),
                              SizedBox(height: 25.h),
                              _buildAnimatedLogoutButton(),
                              SizedBox(height: 18.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildGuestScreen(BuildContext context) {
    return Column(
      children: [
        // Guest header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 19.w,
            left: 15.w,
            right: 15.w,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x553D52A0),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 65.w,
                height: 65.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.4), width: 2.w),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 33.sp,
                ),
              ),
              SizedBox(width: 17.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Browsing as guest',
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Login CTA card
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(18.r),
            child: Column(
              children: [
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(25.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Color(0xFF3D52A0).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_circle_rounded,
                          size: 48.sp,
                          color: Color(0xFF3D52A0),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Login to unlock all features',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      Text(
                        'Sign in to place orders, track deliveries,\nmanage your profile and addresses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.sp, color: Colors.grey, height: 1.w),
                      ),
                      SizedBox(height: 23.h),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.LOGIN),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF5768AB),
                                Color(0xFF232F46),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(45.r),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Color(0xFF5768AB).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Login / Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Terms & Conditions still accessible for guests
                SizedBox(height: 18.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _EnhancedListTile(
                        icon: Icons.support_agent_rounded,
                        iconColor: Color(0xFF2DC9B7),
                        title: 'Support',
                        subtitle: 'Get help and contact us',
                        onTap: () => Get.toNamed('/support_screen'),
                        delay: 0,
                      ),
                      Divider(
                          height: 1.w,
                          indent: 64,
                          endIndent: 16,
                          color: Color(0xFFEEEFF3)),
                      _EnhancedListTile(
                        icon: Icons.article_rounded,
                        iconColor: Color(0xFFFFB800),
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms and policies',
                        onTap: () =>
                            Get.to(() => const TermsAndConditionsPage()),
                        delay: 100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return SlideTransition(
      position: _profileSlideAnimation,
      child: ScaleTransition(
        scale: _profileScaleAnimation,
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 19.w,
            left: 15.w,
            right: 15.w,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x553D52A0),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 65.w,
                height: 65.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2.w),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 33.sp,
                ),
              ),
              SizedBox(width: 17.w),
              // Name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          controller.name.value.isNotEmpty
                              ? controller.name.value
                              : 'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        )),
                    SizedBox(height: 6.h),
                    Obx(() => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            controller.phone.value.isNotEmpty
                                ? controller.phone.value
                                : 'Loading...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              // Edit icon
              GestureDetector(
                onTap: () => Get.toNamed('/profile_screen'),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.w),
                  ),
                  child: Icon(Icons.edit_rounded,
                      color: Colors.white, size: 18.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(
    String title,
    List<Widget> children, {
    required IconData icon,
    required Color iconColor,
  }) {
    return SlideTransition(
      position: _sectionsSlideAnimation,
      child: FadeTransition(
        opacity: _sectionsOpacityAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 15.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2340),
                    fontSize: 15.sp,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogoutButton() {
    return ScaleTransition(
      scale: _logoutButtonAnimation,
      child: GestureDetector(
        onTap: () async {
          try {
            await Supabase.instance.client.auth.signOut();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Get.offAllNamed('/login');
          } catch (e) {
            Get.snackbar('Error', 'Failed to logout. Please try again.');
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53E3E), Color(0xFF9B1F1F)],
            ),
            borderRadius: BorderRadius.circular(17.r),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFE53E3E).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 18.sp),
              SizedBox(width: 10.w),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// Enhanced List Tile with stable animations
class _EnhancedListTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;

  const _EnhancedListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  _EnhancedListTileState createState() => _EnhancedListTileState();
}

class _EnhancedListTileState extends State<_EnhancedListTile>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHoverStart() {
    if (mounted && !_isHovering) {
      setState(() => _isHovering = true);
      _animationController.forward();
    }
  }

  void _handleHoverEnd() {
    if (mounted && _isHovering) {
      setState(() => _isHovering = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverStart(),
      onExit: (_) => _handleHoverEnd(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: _hoverAnimation.value * 4,
                vertical: _hoverAnimation.value * 2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                gradient: _isHovering
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      )
                    : null,
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(15.r),
                  splashColor: AppTheme.primaryColor.withOpacity(0.1),
                  highlightColor: AppTheme.primaryColor.withOpacity(0.05),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 15.h,
                    ),
                    child: Row(
                      children: [
                        _buildIcon(),
                        SizedBox(width: 18.w),
                        Expanded(child: _buildContent()),
                        _buildTrailingIcon(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(11.r),
      decoration: BoxDecoration(
        color: widget.iconColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Icon(
        widget.icon,
        color: widget.iconColor,
        size: 20.sp,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon() {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_hoverAnimation.value * 3, 0),
          child: Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 17.sp,
          ),
        );
      },
    );
  }
}

// Stable Animated Button
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.child,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (mounted) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp() {
    if (mounted) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (mounted) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17.r),
                  border: Border.all(
                    color: Color(0xFFCBD5E1),
                    width: 2.w,
                  ),
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(15.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      child: Center(child: widget.child),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}