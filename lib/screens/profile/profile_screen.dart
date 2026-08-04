import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/admin_config.dart';
import '../../models/user_model.dart';
import '../../services/firebase_services.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../rating/reviews_screen.dart';
import 'edit_profile_screen.dart';
import 'ride_history_screen.dart';
import 'emergency_contact_screen.dart';
import 'notification_screen.dart';
import '../driver/earnings_dashboard_screen.dart';
import 'safety_settings_screen.dart';
import 'sos_settings_screen.dart';
import '../payment/payment_history_screen.dart';
import '../ride/my_bookings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      final user = await FirebaseService().getUser(_user!.uid);
      if (mounted) setState(() => _userModel = user);
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Text(l10n.logout),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(isDark, l10n),
            _buildStatsRow(isDark, l10n),
            _buildMenuSection(isDark, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F9D58),
            Color(0xFF0B8043),
            Color(0xFF1A3C34),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              child: Column(
                children: [
                  // Avatar with edit badge
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 52.r,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          backgroundImage: _userModel?.profilePic.isNotEmpty == true
                              ? NetworkImage(_userModel!.profilePic)
                              : null,
                          child: _userModel?.profilePic.isNotEmpty == true
                              ? null
                              : Icon(Icons.person_rounded, size: 56.sp, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 4.h,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            _fetchUserData();
                          },
                          child: Container(
                            padding: EdgeInsets.all(7.w),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt_rounded, size: 14.sp, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    _userModel?.name ?? 'User',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  if (_userModel?.isVerified ?? false)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(25.r),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.amber, size: 16),
                              SizedBox(width: 6.w),
                              Text(
                                l10n.verified,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, AppLocalizations l10n) {
    final totalRides = _userModel?.totalRides ?? 0;
    final rating = _userModel?.rating ?? 5.0;
    final moneySaved = _userModel?.totalMoneySaved ?? 0.0;
    final co2Reduced = _userModel?.totalCo2Saved ?? 0.0;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('$totalRides', l10n.totalRides.split(' ').last, Icons.directions_car_rounded, AppColors.primary, isDark),
            _buildVerticalDivider(isDark),
            _buildStatItem('${rating.toStringAsFixed(1)}★', 'Rating', Icons.star_rounded, Colors.amber, isDark),
            _buildVerticalDivider(isDark),
            _buildStatItem('₹${moneySaved.toStringAsFixed(0)}', l10n.moneySaved.split(' ').last, Icons.savings_rounded, AppColors.success, isDark),
            _buildVerticalDivider(isDark),
            _buildStatItem('${co2Reduced.toStringAsFixed(1)}kg', l10n.co2Reduced.split(' ').first, Icons.eco_rounded, AppColors.info, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40.h,
      color: isDark ? AppColors.darkDivider : AppColors.border,
    );
  }

  Widget _buildMenuSection(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Account', isDark),
          _buildMenuItem(Icons.person_rounded, l10n.editProfile, 'Update your personal info', AppColors.primary, isDark, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            _fetchUserData();
          }),
          _buildMenuItem(Icons.account_balance_wallet_rounded, l10n.earnings, 'Track your driver earnings', AppColors.success, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsDashboardScreen()))),
          _buildMenuItem(Icons.star_rounded, 'My Ratings', 'See reviews from passengers', Colors.amber, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsScreen(userId: _user?.uid ?? '', userName: _user?.displayName ?? 'User')))),

          _buildSectionTitle('Rides', isDark),
          _buildMenuItem(Icons.event_seat_rounded, 'My Bookings', 'View active and upcoming rides', AppColors.primary, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
          _buildMenuItem(Icons.history_rounded, l10n.rideHistory, 'View your past trips', AppColors.secondary, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()))),
          _buildMenuItem(Icons.payments_rounded, 'Payment History', 'Manage payments & receipts', AppColors.success, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()))),

          _buildSectionTitle('Safety', isDark),
          _buildMenuItem(Icons.shield_rounded, l10n.safetySettings, 'Configure travel safety options', AppColors.info, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetySettingsScreen()))),
          _buildMenuItem(Icons.contacts_rounded, l10n.emergencyContacts, 'Manage trusted contacts', AppColors.error, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()))),
          _buildMenuItem(Icons.sos_rounded, 'SOS Settings', 'Configure emergency alert', AppColors.error, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosSettingsScreen()))),

          _buildSectionTitle('Preferences', isDark),
          _buildMenuItem(Icons.notifications_rounded, l10n.notifications, 'Manage app alerts', AppColors.primary, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          _buildMenuItem(Icons.language_rounded, l10n.language, 'English / हिंदी', AppColors.primary, isDark, () => _showLanguageDialog()),
          _buildMenuItem(Icons.help_rounded, l10n.helpSupport, 'Get help, contact us', AppColors.primary, isDark, () => _showSupportDialog()),
          _buildMenuItem(Icons.info_rounded, l10n.aboutApp, 'App info & version', AppColors.primary, isDark, () => _showAboutAppDialog()),

          SizedBox(height: 20.h),

          if (AdminConfig.isAdmin(_user?.email))
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              height: 52.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10.w),
                      Text(l10n.adminDashboard, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                    ],
                  ),
                ),
              ),
            ),

          // Logout
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16.h),
            height: 52.h,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20.sp),
                    SizedBox(width: 10.w),
                    Text(l10n.logout, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15.sp)),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 110.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 20.h, 0, 10.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final langProvider = context.read<LanguageProvider>();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Text('${l10n.language} / भाषा चुनें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(langProvider, 'English', '🇬🇧', 'en'),
            const Divider(),
            _langOption(langProvider, 'हिंदी', '🇮🇳', 'hi'),
          ],
        ),
      ),
    );
  }

  Widget _langOption(LanguageProvider provider, String label, String flag, String code) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 24.sp)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      onTap: () async {
        if (code == 'hi') {
          await provider.setHindi();
        } else {
          await provider.setEnglish();
        }
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(code == 'hi' ? 'भाषा हिंदी में बदल गई!' : 'Language changed to English!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
      },
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.email_rounded, color: AppColors.primary), title: Text('Email Us'), subtitle: Text('support@saathchalo.com')),
            ListTile(leading: Icon(Icons.phone_rounded, color: AppColors.primary), title: Text('Call Us'), subtitle: Text('+91 98765 43210')),
            ListTile(leading: Icon(Icons.chat_rounded, color: AppColors.primary), title: Text('WhatsApp'), subtitle: Text('+91 98765 43210')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAboutAppDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'SaathChalo',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 36.sp),
      children: [
        const Text('SaathChalo is an AI powered carpooling app for India. Save money, reduce pollution & travel together!'),
      ],
    );
  }
}