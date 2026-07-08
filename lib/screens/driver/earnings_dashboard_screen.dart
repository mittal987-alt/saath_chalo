import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState
    extends State<EarningsDashboardScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedPeriod = 'This Week';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'All Time'
  ];

  // Filter bookings by period
  List<BookingModel> _filterByPeriod(List<BookingModel> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return bookings.where((b) {
      final bDate = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
      switch (_selectedPeriod) {
        case 'Today':
          return bDate.isAtSameMomentAs(today);
        case 'This Week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          return bDate.isAtSameMomentAs(weekStart) || bDate.isAfter(weekStart);
        case 'This Month':
          return b.createdAt.year == now.year &&
              b.createdAt.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('driverUid', isEqualTo: _uid)
            .where('status', whereIn: [
          'accepted',
          'confirmed',
          'en_route',
          'started',
          'ended',
          'completed'
        ]).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final allBookings = (snapshot.data?.docs ?? [])
              .map((doc) => BookingModel.fromMap(
              doc.data() as Map<String, dynamic>))
              .toList();

          final filtered = _filterByPeriod(allBookings);

          // Calculate stats
          final totalEarnings = filtered.fold<double>(
              0, (sum, b) => sum + b.totalPrice);
          final totalRides = filtered.length;
          final totalSeats = filtered.fold<int>(
              0, (sum, b) => sum + b.seatsBooked);
          final paidRides =
              filtered.where((b) => b.paymentStatus == 'paid').length;
          final pendingAmount = filtered
              .where((b) => b.paymentStatus == 'unpaid')
              .fold<double>(0, (sum, b) => sum + b.totalPrice);

          // Platform fee (5%)
          final platformFee = totalEarnings * 0.05;
          final netEarnings = totalEarnings - platformFee;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selector
                _buildPeriodSelector(),
                SizedBox(height: 16.h),

                // Total earnings card
                _buildTotalEarningsCard(
                    netEarnings, totalEarnings, platformFee),
                SizedBox(height: 16.h),

                // Stats grid
                _buildStatsGrid(
                    totalRides, totalSeats, paidRides, pendingAmount),
                SizedBox(height: 16.h),

                // Earnings chart
                _buildEarningsChart(filtered),
                SizedBox(height: 16.h),

                // Recent earnings list
                _buildRecentEarnings(filtered),
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [],
              ),
              child: Text(
                period,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalEarningsCard(
      double net, double gross, double fee) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Earnings',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _selectedPeriod,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '₹${net.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 42.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _earningChip('Gross', '₹${gross.toStringAsFixed(0)}',
                  Icons.currency_rupee_rounded),
              SizedBox(width: 12.w),
              _earningChip('Platform Fee',
                  '-₹${fee.toStringAsFixed(0)}', Icons.percent_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earningChip(String label, String value, IconData icon) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 14.sp),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      int rides, int seats, int paid, double pending) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.6,
      children: [
        _statCard('Total Rides', '$rides',
            Icons.directions_car_rounded, AppColors.secondary),
        _statCard('Seats Filled', '$seats',
            Icons.event_seat_rounded, AppColors.primary),
        _statCard('Payments Done', '$paid',
            Icons.check_circle_rounded, AppColors.success),
        _statCard('Pending Amount', '₹${pending.toStringAsFixed(0)}',
            Icons.pending_rounded, AppColors.warning),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
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

  Widget _buildEarningsChart(List<BookingModel> bookings) {
    String title = 'Earnings 📊';
    List<String> labels = [];
    Map<String, double> chartData = {};
    String currentHighlight = '';

    final now = DateTime.now();

    if (_selectedPeriod == 'Today') {
      title = 'Today\'s Activity 📊';
      labels = ['6AM', '12PM', '6PM', '12AM'];
      for (var l in labels) chartData[l] = 0;
      for (var b in bookings) {
        int hour = b.createdAt.hour;
        String label;
        if (hour < 6) label = '12AM';
        else if (hour < 12) label = '6AM';
        else if (hour < 18) label = '12PM';
        else label = '6PM';
        chartData[label] = (chartData[label] ?? 0) + b.totalPrice;
      }
      int hour = now.hour;
      if (hour < 6) currentHighlight = '12AM';
      else if (hour < 12) currentHighlight = '6AM';
      else if (hour < 18) currentHighlight = '12PM';
      else currentHighlight = '6PM';

    } else if (_selectedPeriod == 'This Week') {
      title = 'Weekly Earnings 📊';
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (var l in labels) chartData[l] = 0;
      for (var b in bookings) {
        final dayName = labels[b.createdAt.weekday - 1];
        chartData[dayName] = (chartData[dayName] ?? 0) + b.totalPrice;
      }
      currentHighlight = labels[now.weekday - 1];

    } else if (_selectedPeriod == 'This Month') {
      title = 'Monthly Progress 📊';
      labels = ['W1', 'W2', 'W3', 'W4+'];
      for (var l in labels) chartData[l] = 0;
      for (var b in bookings) {
        int week = ((b.createdAt.day - 1) / 7).floor() + 1;
        String label = week >= 4 ? 'W4+' : 'W$week';
        chartData[label] = (chartData[label] ?? 0) + b.totalPrice;
      }
      int week = ((now.day - 1) / 7).floor() + 1;
      currentHighlight = week >= 4 ? 'W4+' : 'W$week';

    } else {
      title = 'Recent Months 📊';
      for (int i = 5; i >= 0; i--) {
        DateTime d = DateTime(now.year, now.month - i, 1);
        String m = _getMonthName(d.month);
        labels.add(m);
        chartData[m] = 0;
      }
      for (var b in bookings) {
        String m = _getMonthName(b.createdAt.month);
        if (chartData.containsKey(m)) {
          chartData[m] = (chartData[m] ?? 0) + b.totalPrice;
        }
      }
      currentHighlight = _getMonthName(now.month);
    }

    final maxVal = chartData.values.isEmpty
        ? 1.0
        : chartData.values
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 120.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: labels.map((label) {
                final val = chartData[label] ?? 0;
                final heightPercent = val / maxVal;
                final isHighlighted = label == currentHighlight;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (val > 0)
                      Text(
                        '₹${val.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 4.h),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: (200.w / labels.length).clamp(24.0, 45.0),
                      height: (heightPercent * 80.h).clamp(4.0, 80.h),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.primary
                            : val > 0
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.border,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6.r),
                          topRight: Radius.circular(6.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isHighlighted
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: isHighlighted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  Widget _buildRecentEarnings(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded,
                  size: 48.sp, color: AppColors.border),
              SizedBox(height: 12.h),
              Text(
                'No earnings yet for $_selectedPeriod',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by date descending
    final sorted = List<BookingModel>.from(bookings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Earnings',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${sorted.length} rides',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...sorted.take(10).map((booking) {
            final isPaid = booking.paymentStatus == 'paid';
            final net = booking.totalPrice * 0.95;
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isPaid
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      color: isPaid
                          ? AppColors.success
                          : AppColors.warning,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.from} → ${booking.to}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Text(
                              booking.riderName.isEmpty
                                  ? 'Rider'
                                  : booking.riderName,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(' • ',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color:
                                    AppColors.textSecondary)),
                            Text(
                              '${booking.seatsBooked} seat(s)',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(booking.createdAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${net.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isPaid ? 'Paid' : 'Pending',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}