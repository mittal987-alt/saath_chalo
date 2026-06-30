import 'package:flutter/material.dart';
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
import 'safety_settings_screen.dart';
import 'sos_settings_screen.dart';
import '../payment/payment_history_screen.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsRow(),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 40.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B09B), // Bright Green
            Color(0xFF00A86B), // Deep Emerald
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(45.r),
          bottomRight: Radius.circular(45.r),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 55.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  backgroundImage: _userModel?.profilePic.isNotEmpty == true
                      ? NetworkImage(_userModel!.profilePic)
                      : null,
                  child: _userModel?.profilePic.isNotEmpty == true
                      ? null
                      : Icon(Icons.person_rounded, size: 60.sp, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7043), // Orange camera icon
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, size: 16.sp, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            _userModel?.name ?? 'User',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          if (_userModel?.isVerified ?? false)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8.w),
                  Text(
                    'Verified User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalRides = _userModel?.totalRides ?? 0;
    final rating = _userModel?.rating ?? 5.0;
    // Logic for calculated stats
    final moneySaved = totalRides * 150; 
    final co2Reduced = totalRides * 1.5;

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('$totalRides', 'Total Rides', const Color(0xFF00A86B)),
          _buildDivider(),
          _buildStatItem('${rating.toStringAsFixed(1)} ★', 'My Rating', Colors.amber),
          _buildDivider(),
          _buildStatItem('₹$moneySaved', 'Saved', const Color(0xFF00A86B)),
          _buildDivider(),
          _buildStatItem('${co2Reduced.toStringAsFixed(0)}kg', 'CO₂ Saved', const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28.h, color: AppColors.border.withValues(alpha: 0.6));
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Account'),
          _buildMenuItem(Icons.person_rounded, 'Edit Profile', AppColors.primary, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          }),
          _buildMenuItem(Icons.phone_rounded, 'Phone Number', AppColors.primary, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Phone: ${_user?.phoneNumber ?? "Not set"}')),
            );
          }),
          _buildMenuItem(Icons.star_rounded, 'My Ratings', Colors.amber, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsScreen(userId: _user?.uid ?? '', userName: _user?.displayName ?? 'User')));
          }),

          _buildSectionTitle('Rides'),
          _buildMenuItem(Icons.history_rounded, 'Ride History', AppColors.secondary, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
          }),
          _buildMenuItem(Icons.directions_car_rounded, 'My Offered Rides', AppColors.secondary, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
          }),
          _buildMenuItem(Icons.payments_rounded, 'Payment History', AppColors.success, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
          }),

          _buildSectionTitle('Safety'),
          _buildMenuItem(Icons.shield_rounded, 'Safety Settings', AppColors.info, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetySettingsScreen()));
          }),
          _buildMenuItem(Icons.contacts_rounded, 'Emergency Contacts', AppColors.error, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
          }),
          _buildMenuItem(Icons.sos_rounded, 'SOS Settings', AppColors.error, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SosSettingsScreen()));
          }),

          _buildSectionTitle('App Preferences'),
          _buildMenuItem(Icons.notifications_rounded, 'Notifications', AppColors.primary, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          _buildMenuItem(Icons.language_rounded, 'Language', AppColors.primary, () => _showLanguageDialog()),
          _buildMenuItem(Icons.help_rounded, 'Help & Support', AppColors.primary, () => _showSupportDialog()),
          _buildMenuItem(Icons.info_rounded, 'About SaathChalo', AppColors.primary, () => _showAboutAppDialog()),

          SizedBox(height: 20.h),

          if (AdminConfig.isAdmin(_user?.email))
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  minimumSize: Size(double.infinity, 48.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                label: const Text('Admin Dashboard 👑', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16.h),
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.5),
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ),

          SizedBox(height: 100.h), // Safe spacing to keep content completely clear of floating bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 16.h, 0, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: AppColors.textHint.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('English'), leading: const Text('🇬🇧'), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text('हिंदी'), leading: const Text('🇮🇳'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.email_rounded, color: AppColors.primary), title: const Text('Email Us'), subtitle: const Text('support@saathchalo.com')),
            ListTile(leading: Icon(Icons.phone_rounded, color: AppColors.primary), title: const Text('Call Us'), subtitle: const Text('+91 98765 43210')),
            ListTile(leading: Icon(Icons.chat_rounded, color: AppColors.primary), title: const Text('WhatsApp'), subtitle: const Text('+91 98765 43210')),
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