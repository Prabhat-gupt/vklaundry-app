import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry_app/app/constants/app_theme.dart';
import 'package:laundry_app/app/controllers/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_app/app/ui/widgets/terms_conditions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final controller = Get.put(ProfileController());

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

        // Fetch user data
        await controller.fetchUserProfile(controller.storages.read('userId'));

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
      backgroundColor: const Color(0xFFF1F2F5),
      appBar: _buildAppBar(),
      body: Obx(
            () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
          opacity: _pageOpacityAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedProfileCard(),
                const SizedBox(height: 32),
                _buildAnimatedSection(
                  "Your Information",
                  [
                    _EnhancedListTile(
                      icon: Icons.location_on_rounded,
                      title: "Saved Address",
                      subtitle: "Manage your delivery locations",
                      onTap: () => Get.toNamed('/address_screen'),
                      delay: 0,
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _EnhancedListTile(
                      icon: Icons.person_rounded,
                      title: "Profile",
                      subtitle: "Edit your personal information",
                      onTap: () => Get.toNamed('/profile_screen'),
                      delay: 100,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildAnimatedSection(
                  "Other Information",
                  [
                    _EnhancedListTile(
                      icon: Icons.support_agent_rounded,
                      title: "Support",
                      subtitle: "Get help and contact us",
                      onTap: () => Get.toNamed('/support_screen'),
                      delay: 200,
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _EnhancedListTile(
                      icon: Icons.article_rounded,
                      title: "Terms & Conditions",
                      subtitle: "Read our terms and policies",
                      onTap: () => Get.to(() => const TermsAndConditionsPage()),
                      delay: 300,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildAnimatedLogoutButton(),
                const SizedBox(height: 20),
                // _buildVersionInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Text(
        "Settings",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildAnimatedProfileCard() {
    return SlideTransition(
      position: _profileSlideAnimation,
      child: ScaleTransition(
        scale: _profileScaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 24),
              Expanded(child: _buildProfileInfo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: Colors.transparent,
        child: Icon(
          Icons.person_rounded,
          size: 44,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.name.value.isNotEmpty ? controller.name.value : "Loading...",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            controller.phone.value.isNotEmpty ? controller.phone.value : "Loading...",
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSection(String title, List<Widget> children) {
    return SlideTransition(
      position: _sectionsSlideAnimation,
      child: FadeTransition(
        opacity: _sectionsOpacityAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title),
            const SizedBox(height: 16),
            _buildInfoCard(children),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogoutButton() {
    return ScaleTransition(
      scale: _logoutButtonAnimation,
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: _AnimatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                controller.storages.erase();
                Get.offAllNamed('/login');
              } catch (e) {
                // Handle logout error
                Get.snackbar('Error', 'Failed to logout. Please try again.');
              }
            },
            child: const Text(
              "Log Out",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Widget _buildVersionInfo() {
  //   return FadeTransition(
  //     opacity: _logoutButtonAnimation,
  //     child: const Center(
  //       child: Text(
  //         "App version 18.5.7\nv69-2",
  //         textAlign: TextAlign.center,
  //         style: TextStyle(fontSize: 12, color: Colors.grey),
  //       ),
  //     ),
  //   );
  // }
}

// Enhanced List Tile with stable animations
class _EnhancedListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;

  const _EnhancedListTile({
    required this.icon,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.icon,
        color: AppTheme.primaryColor,
        size: 24,
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