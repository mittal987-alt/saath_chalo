import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import 'admin_users_screen.dart';
import 'admin_rides_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_moderation_screen.dart';

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
              SizedBox(height: 24.h),

              // Charts
              _buildRevenueChart(),
              SizedBox(height: 24.h),

              _buildRideTypeDistribution(),
              SizedBox(height: 24.h),

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

  Widget _buildRevenueChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Trend (Last 7 Days)',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 220.h,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 300),
                    FlSpot(1, 450),
                    FlSpot(2, 200),
                    FlSpot(3, 600),
                    FlSpot(4, 800),
                    FlSpot(5, 750),
                    FlSpot(6, 900),
                  ],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideTypeDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ride Status Distribution',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 200.h,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: AppColors.success,
                  value: 40,
                  title: '40%',
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.primary,
                  value: 30,
                  title: '30%',
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.amber,
                  value: 20,
                  title: '20%',
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.error,
                  value: 10,
                  title: '10%',
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Completed', AppColors.success),
            SizedBox(width: 16.w),
            _buildLegendItem('Active', AppColors.primary),
            SizedBox(width: 16.w),
            _buildLegendItem('Full', Colors.amber),
            SizedBox(width: 16.w),
            _buildLegendItem('Cancelled', AppColors.error),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
              '⚠️ Reports',
              AppColors.error,
              Icons.report_gmailerrorred_rounded,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const AdminReportsScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _buildActionButton(
              '🛡️ Mod',
              Colors.blueGrey,
              Icons.gavel_rounded,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const AdminModerationScreen()),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('notifications')
              .where('toUid', isEqualTo: 'admin_panel')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return _buildActivityItem({
                  'icon': _getActivityIcon(data['type']),
                  'color': _getActivityColor(data['type']),
                  'text': data['title'] ?? 'New Notification',
                  'time': _formatTimestamp(data['timestamp'] as Timestamp?),
                });
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'sos_alert': return Icons.sos_rounded;
      case 'admin_report': return Icons.report_problem_rounded;
      case 'admin_moderation': return Icons.gavel_rounded;
      case 'payment': return Icons.payments_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  int _getActivityColor(String? type) {
    switch (type) {
      case 'sos_alert': return 0xFFD32F2F;
      case 'admin_report': return 0xFFFF9800;
      case 'admin_moderation': return 0xFF1565C0;
      case 'payment': return 0xFF00C853;
      default: return 0xFF607D8B;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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