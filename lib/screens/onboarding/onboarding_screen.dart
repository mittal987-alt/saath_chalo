import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconController;
  late Animation<double> _iconBounce;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.people_alt_rounded,
      'title': AppStrings.onboard1Title,
      'desc': AppStrings.onboard1Desc,
      'gradient': [const Color(0xFF0F9D58), const Color(0xFF1B5E37)],
      'iconBg': const Color(0xFF81C784),
      'badge': '🚗 Carpool Together',
    },
    {
      'icon': Icons.savings_rounded,
      'title': AppStrings.onboard2Title,
      'desc': AppStrings.onboard2Desc,
      'gradient': [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
      'iconBg': const Color(0xFF64B5F6),
      'badge': '💰 Save Every Trip',
    },
    {
      'icon': Icons.verified_user_rounded,
      'title': AppStrings.onboard3Title,
      'desc': AppStrings.onboard3Desc,
      'gradient': [const Color(0xFF6A1B9A), const Color(0xFF4A148C)],
      'iconBg': const Color(0xFFCE93D8),
      'badge': '🛡️ Ride Safe',
    },
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _iconBounce = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconController.forward();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconController.reset();
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final gradient = page['gradient'] as List<Color>;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page counter
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Skip button
                    TextButton(
                      onPressed: _goToLogin,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                      child: Text(
                        AppStrings.skip,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pages ───────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => _buildPage(_pages[index]),
                ),
              ),

              // ── Bottom Panel ─────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w, 36.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36.r),
                    topRight: Radius.circular(36.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = _currentPage == index;
                        final pageGrad = _pages[index]['gradient'] as List<Color>;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: isActive ? 28.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: isActive ? pageGrad[0] : pageGrad[0].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 28.h),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 58.h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1
                                    ? AppStrings.getStarted
                                    : AppStrings.next,
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                _currentPage == _pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              page['badge'] as String,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 36.h),

          // Animated Icon
          ScaleTransition(
            scale: _iconBounce,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  page['icon'] as IconData,
                  size: 90.sp,
                  color: (page['gradient'] as List<Color>)[0],
                ),
              ),
            ),
          ),

          SizedBox(height: 48.h),

          // Title
          Text(
            page['title'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Description
          Text(
            page['desc'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}