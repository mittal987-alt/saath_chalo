import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _logoController.forward().then((_) => _textController.forward());

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => user != null ? const HomeScreen() : const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E37),
              Color(0xFF0F9D58),
              Color(0xFF43A047),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Decorative blobs ──────────────────────
            Positioned(
              top: -80.h,
              right: -60.w,
              child: _blob(260.w, 0.08),
            ),
            Positioned(
              bottom: -60.h,
              left: -80.w,
              child: _blob(300.w, 0.06),
            ),
            Positioned(
              top: 180.h,
              left: -40.w,
              child: _blob(140.w, 0.05),
            ),

            // ── Main Content ───────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 130.w,
                        height: 130.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 40,
                              spreadRadius: 4,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0F9D58).withOpacity(0.4),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 72.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 36.h),

                // App name + tagline
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 46.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 9.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                          ),
                          child: Text(
                            AppStrings.tagline,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 90.h),

                // Loading dots
                FadeTransition(
                  opacity: _textFade,
                  child: _LoadingDots(),
                ),
              ],
            ),

            // ── Bottom version tag ─────────────────────
            Positioned(
              bottom: 32.h,
              child: FadeTransition(
                opacity: _textFade,
                child: Text(
                  'v1.0.0  •  Made with 💚 in India',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)));
    _dotAnims = _dotControllers.map((c) => Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _dotControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dotAnims[i],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _dotAnims[i].value),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}