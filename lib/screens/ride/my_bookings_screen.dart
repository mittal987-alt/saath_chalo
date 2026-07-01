import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/ride_status.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import 'active_ride_screen.dart';
import '../payment/payment_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseService().getMyBookings(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 64.sp, color: AppColors.border),
                  SizedBox(height: 16.h),
                  Text('No rides yet!',
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 8.h),
                  Text('Your booked rides will appear here.',
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _BookingCard(booking: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final bool isActive = [
      RideStatus.confirmed,
      RideStatus.enRoute,
      RideStatus.started,
    ].contains(booking.status);

    final bool needsPayment =
        booking.status == RideStatus.ended &&
            booking.paymentStatus == 'unpaid';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isActive
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  RideStatus.getLabel(booking.status),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
              Text(
                '₹${booking.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Route
          Row(
            children: [
              Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${booking.from} → ${booking.to}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          Row(
            children: [
              Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 14.sp),
              SizedBox(width: 6.w),
              Text(
                'Driver: ${booking.driverName}  •  ${booking.seatsBooked} seat(s)',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Action buttons
          if (isActive)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveRideScreen(
                    booking: booking,
                    isDriver: false,
                  ),
                ),
              ),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Track My Ride'),
            ),

          if (needsPayment)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    rideId: booking.rideId,
                    driverName: booking.driverName,
                    from: booking.from,
                    to: booking.to,
                    amount: booking.totalPrice,
                    seats: booking.seatsBooked,
                    pricePerSeat: booking.pricePerSeat,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              icon: const Icon(Icons.payment_rounded),
              label: Text(
                  'Pay ₹${booking.totalPrice.toStringAsFixed(0)}'),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case RideStatus.pending:
        return AppColors.warning;
      case RideStatus.confirmed:
        return AppColors.primary;
      case RideStatus.enRoute:
        return AppColors.secondary;
      case RideStatus.started:
        return AppColors.success;
      case RideStatus.ended:
        return AppColors.textSecondary;
      case RideStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }
}