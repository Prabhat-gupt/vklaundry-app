import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_app/app/ui/widgets/terms_conditions.dart';

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
      duration: const Duration(milliseconds: 500),
    );

    _profileCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _sectionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoutButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

        // Fetch user data using SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId != null) {
          await controller.fetchUserProfile(userId);
        }

        if (!mounted) return;

        // Start staggered animations
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) _profileCardController.forward();

        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _sectionsController.forward();

        await Future.delayed(const Duration(milliseconds: 300));
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _pageOpacityAnimation,
                child: Column(
                  children: [
                    _buildGradientHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedSection(
                              icon: Icons.person_pin_rounded,
                              iconColor: const Color(0xFF3D52A0),
                              "Your Information",
                              [
                                _EnhancedListTile(
                                  icon: Icons.location_on_rounded,
                                  iconColor: const Color(0xFF2DC9B7),
                                  title: "Saved Address",
                                  subtitle: "Manage your delivery locations",
                                  onTap: () => Get.toNamed('/address_screen'),
                                  delay: 0,
                                ),
                                const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFEEEFF3)),
                                _EnhancedListTile(
                                  icon: Icons.manage_accounts_rounded,
                                  iconColor: const Color(0xFF9C6FFF),
                                  title: "Profile",
                                  subtitle: "Edit your personal information",
                                  onTap: () => Get.toNamed('/profile_screen'),
                                  delay: 100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedSection(
                              icon: Icons.info_outline_rounded,
                              iconColor: const Color(0xFFFF8C42),
                              "Other Information",
                              [
                                _EnhancedListTile(
                                  icon: Icons.support_agent_rounded,
                                  iconColor: const Color(0xFF2DC9B7),
                                  title: "Support",
                                  subtitle: "Get help and contact us",
                                  onTap: () => Get.toNamed('/support_screen'),
                                  delay: 200,
                                ),
                                const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFEEEFF3)),
                                _EnhancedListTile(
                                  icon: Icons.article_rounded,
                                  iconColor: const Color(0xFFFFB800),
                                  title: "Terms & Conditions",
                                  subtitle: "Read our terms and policies",
                                  onTap: () =>
                                      Get.to(() => const TermsAndConditionsPage()),
                                  delay: 300,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildAnimatedLogoutButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
            bottom: 28,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D52A0), Color(0xFF1A2340)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 18),
              // Name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          controller.name.value.isNotEmpty
                              ? controller.name.value
                              : 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        )),
                    const SizedBox(height: 6),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            controller.phone.value.isNotEmpty
                                ? controller.phone.value
                                : 'Loading...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 20),
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53E3E), Color(0xFF9B1F1F)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53E3E).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
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
      duration: const Duration(milliseconds: 200),
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
                borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
                  splashColor: AppTheme.primaryColor.withOpacity(0.1),
                  highlightColor: AppTheme.primaryColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        _buildIcon(),
                        const SizedBox(width: 20),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: widget.iconColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        widget.icon,
        color: widget.iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
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
            size: 18,
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
      duration: const Duration(milliseconds: 150),
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
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 2,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
