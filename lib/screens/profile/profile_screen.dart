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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
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
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      padding: EdgeInsets.only(
          top: 60.h, bottom: 24.h, left: 20.w, right: 20.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48.r,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                child: Icon(Icons.person_rounded,
                    size: 56.sp, color: AppColors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 16.sp, color: AppColors.white),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Text(
            _userModel?.name ?? _user?.displayName ?? 'User',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            _userModel?.email ?? _user?.email ?? '',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),

          SizedBox(height: 12.h),

          Container(
            padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    color: Colors.amber, size: 16.sp),
                SizedBox(width: 6.w),
                Text(
                  'Verified User',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.white,
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
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
              '${_userModel?.totalRides ?? 0}',
              'Total\nRides',
              AppColors.primary),
          _buildDivider(),
          _buildStatItem(
              '${_userModel?.rating ?? 5.0}',
              'My\nRating',
              Colors.amber),
          _buildDivider(),
          _buildStatItem('₹2,450', 'Money\nSaved', AppColors.success),
          _buildDivider(),
          _buildStatItem('12kg', 'CO₂\nSaved', AppColors.info),
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
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40.h,
      color: AppColors.border,
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============ ACCOUNT ============
          _buildSectionTitle('Account'),
          _buildMenuItem(
            Icons.person_rounded,
            'Edit Profile',
            AppColors.primary,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditProfileScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.phone_rounded,
            'Phone Number',
            AppColors.primary,
                () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Phone: ${_user?.phoneNumber ?? "Not set"}'),
              ),
            ),
          ),
          _buildMenuItem(
            Icons.star_rounded,
            'My Ratings',
            Colors.amber,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(
                  userId: _user?.uid ?? '',
                  userName: _user?.displayName ?? 'User',
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ============ RIDES ============
          _buildSectionTitle('Rides'),
          _buildMenuItem(
            Icons.history_rounded,
            'Ride History',
            AppColors.secondary,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RideHistoryScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.directions_car_rounded,
            'My Offered Rides',
            AppColors.secondary,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RideHistoryScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.payments_rounded,
            'Payment History',
            AppColors.success,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PaymentHistoryScreen()),
            ),
          ),

          SizedBox(height: 16.h),

          // ============ SAFETY ============
          _buildSectionTitle('Safety'),
          _buildMenuItem(
            Icons.shield_rounded,
            'Safety Settings',
            AppColors.info,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SafetySettingsScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.contacts_rounded,
            'Emergency Contacts',
            AppColors.error,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmergencyContactsScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.sos_rounded,
            'SOS Settings',
            AppColors.error,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SOSSettingsScreen()),
            ),
          ),

          SizedBox(height: 16.h),

          // ============ APP ============
          _buildSectionTitle('App'),
          _buildMenuItem(
            Icons.notifications_rounded,
            'Notifications',
            AppColors.primary,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.language_rounded,
            'Language',
            AppColors.primary,
                () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
                title: const Text('Select Language'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('English'),
                      leading: const Text('🇬🇧'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      title: const Text('हिंदी'),
                      leading: const Text('🇮🇳'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildMenuItem(
            Icons.help_rounded,
            'Help & Support',
            AppColors.primary,
                () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
                title: const Text('Help & Support'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.email_rounded,
                          color: AppColors.primary),
                      title: const Text('Email Us'),
                      subtitle:
                      const Text('support@saathchalo.com'),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone_rounded,
                          color: AppColors.primary),
                      title: const Text('Call Us'),
                      subtitle: const Text('+91 98765 43210'),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat_rounded,
                          color: AppColors.primary),
                      title: const Text('WhatsApp'),
                      subtitle: const Text('+91 98765 43210'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          _buildMenuItem(
            Icons.info_rounded,
            'About SaathChalo',
            AppColors.primary,
                () => showAboutDialog(
              context: context,
              applicationName: 'SaathChalo',
              applicationVersion: '1.0.0',
              applicationIcon: Icon(
                Icons.directions_car_rounded,
                color: AppColors.primary,
                size: 40.sp,
              ),
              children: [
                const Text(
                  'SaathChalo is an AI powered carpooling app for India. Save money, reduce pollution & travel together!',
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ============ ADMIN BUTTON ============
          if (AdminConfig.isAdmin(_user?.email))
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                      const AdminDashboardScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  minimumSize: Size(double.infinity, 52.h),
                ),
                icon: const Icon(
                    Icons.admin_panel_settings_rounded),
                label: const Text('Admin Dashboard 👑'),
              ),
            ),

          // ============ LOGOUT BUTTON ============
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 32.h),
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: Size(double.infinity, 52.h),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
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
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14.sp, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}