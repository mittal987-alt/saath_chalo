import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/ride_status.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../../widgets/shimmer_loading.dart';
import 'active_ride_screen.dart';
import '../payment/payment_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Collapsing Header ─────────────────
          SliverAppBar(
            expandedHeight: 110.h,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20.w, 0, 0, 16.h),
              title: Text(
                'My Bookings',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<BookingModel>>(
              stream: FirebaseService().getMyBookings(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: List.generate(3, (index) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: ShimmerLoading(width: double.infinity, height: 180.h, borderRadius: 24.r),
                      )),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: 500.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            size: 80.sp,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'No rides booked yet!',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Find a ride and start your carpooling journey.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _BookingCard(booking: snapshot.data![index], isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isDark;
  const _BookingCard({required this.booking, required this.isDark});

  Color _statusColor(String status) {
    switch (status) {
      case RideStatus.pending: return AppColors.warning;
      case RideStatus.confirmed: return AppColors.primary;
      case RideStatus.enRoute: return AppColors.secondary;
      case RideStatus.started: return AppColors.success;
      case RideStatus.ended: return AppColors.textSecondary;
      case RideStatus.rejected: return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case RideStatus.pending: return Icons.hourglass_top_rounded;
      case RideStatus.confirmed: return Icons.check_circle_rounded;
      case RideStatus.enRoute: return Icons.navigation_rounded;
      case RideStatus.started: return Icons.directions_car_rounded;
      case RideStatus.ended: return Icons.flag_rounded;
      case RideStatus.rejected: return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = [
      RideStatus.confirmed,
      RideStatus.enRoute,
      RideStatus.started,
    ].contains(booking.status);

    final bool needsPayment =
        booking.status == RideStatus.ended && booking.paymentStatus == 'unpaid';

    final statusColor = _statusColor(booking.status);

    return GestureDetector(
      onTap: isActive
          ? () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ActiveRideScreen(booking: booking, isDriver: false),
              ));
            }
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isActive ? statusColor.withOpacity(0.4) : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? statusColor.withOpacity(0.12)
                  : Colors.black.withOpacity(isDark ? 0.0 : 0.04),
              blurRadius: isActive ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top status bar ──────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(booking.status), color: statusColor, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    RideStatus.getLabel(booking.status),
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  if (!isActive)
                    Text(
                      '₹${booking.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                ],
              ),
            ),

            // ── Card body ───────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Route row
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10.w, height: 10.w,
                            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                          Container(width: 1.5, height: 28.h, color: AppColors.border),
                          Icon(Icons.location_on_rounded, color: AppColors.error, size: 14.sp),
                        ],
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.from,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 18.h),
                            Text(
                              booking.to,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '₹${booking.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 14.h),
                  Divider(color: isDark ? AppColors.darkDivider : AppColors.divider, height: 1),
                  SizedBox(height: 12.h),

                  // ── Driver info row ──────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 22.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.driverName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? "s" : ""} booked',
                              style: TextStyle(fontSize: 11.sp, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.background,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_seat_rounded, size: 12.sp, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              '${booking.seatsBooked}x',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Action buttons ───────────────────────
                  if (isActive)
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ActiveRideScreen(booking: booking, isDriver: false),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          ),
                          icon: const Icon(Icons.map_rounded, color: Colors.white),
                          label: const Text('Track My Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),

                  if (needsPayment)
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              rideId: booking.rideId,
                              driverName: booking.driverName,
                              from: booking.from,
                              to: booking.to,
                              amount: booking.totalPrice,
                              seats: booking.seatsBooked,
                              pricePerSeat: booking.pricePerSeat,
                            ),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        icon: const Icon(Icons.payment_rounded, color: Colors.white),
                        label: Text(
                          'Pay ₹${booking.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}