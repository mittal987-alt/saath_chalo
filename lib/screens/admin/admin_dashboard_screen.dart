import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import 'admin_users_screen.dart';
import 'admin_rides_screen.dart';
import 'admin_notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _totalRides = 0;
  int _activeRides = 0;
  double _totalRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final users = await _db.collection('users').count().get();
      final rides = await _db.collection('rides').count().get();
      final active = await _db
          .collection('rides')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      final payments = await _db.collection('payments').get();

      double revenue = 0;
      for (var doc in payments.docs) {
        revenue += (doc.data()['amount'] ?? 0).toDouble();
      }

      setState(() {
        _totalUsers = users.count ?? 0;
        _totalRides = rides.count ?? 0;
        _activeRides = active.count ?? 0;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.white, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Admin Dashboard'),
          ],
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF1A237E)))
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              _buildWelcomeCard(),
              SizedBox(height: 16.h),

              // Stats Grid
              _buildStatsGrid(),
              SizedBox(height: 16.h),

              // Quick Actions
              _buildQuickActions(),
              SizedBox(height: 16.h),

              // Recent Activity
              _buildRecentActivity(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.white, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Admin! 👑',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              '👥 Total Users',
              _totalUsers.toString(),
              Icons.people_rounded,
              const Color(0xFF1565C0),
              '+12 today',
            ),
            _buildStatCard(
              '🚗 Total Rides',
              _totalRides.toString(),
              Icons.directions_car_rounded,
              AppColors.secondary,
              '+5 today',
            ),
            _buildStatCard(
              '✅ Active Rides',
              _activeRides.toString(),
              Icons.electric_car_rounded,
              AppColors.success,
              'Live now',
            ),
            _buildStatCard(
              '💰 Revenue',
              '₹${_totalRevenue.toStringAsFixed(0)}',
              Icons.payments_rounded,
              AppColors.primary,
              'Platform fees',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value,
      IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildActionButton(
              '👥 Users',
              const Color(0xFF1565C0),
              Icons.people_rounded,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _buildActionButton(
              '🚗 Rides',
              AppColors.secondary,
              Icons.directions_car_rounded,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminRidesScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _buildActionButton(
              '🔔 Notify',
              AppColors.primary,
              Icons.notifications_rounded,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const AdminNotificationsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color,
      IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.white, size: 28.sp),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('rides')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            final activities = [
              {'icon': Icons.person_add_rounded, 'color': 0xFF1565C0, 'text': 'New user signed up', 'time': '2 min ago'},
              {'icon': Icons.directions_car_rounded, 'color': 0xFF00A86B, 'text': 'New ride offered: Noida → Delhi', 'time': '5 min ago'},
              {'icon': Icons.payments_rounded, 'color': 0xFF00C853, 'text': 'Payment received ₹120', 'time': '10 min ago'},
              {'icon': Icons.star_rounded, 'color': 0xFFFFC107, 'text': 'New 5 star review received', 'time': '15 min ago'},
              {'icon': Icons.sos_rounded, 'color': 0xFFD32F2F, 'text': 'SOS alert triggered!', 'time': '1 hour ago'},
            ];

            return Column(
              children: activities
                  .map((a) => _buildActivityItem(a))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Color(activity['color']).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: Color(activity['color']),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              activity['text'],
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            activity['time'],
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}