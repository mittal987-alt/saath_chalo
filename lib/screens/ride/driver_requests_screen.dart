import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../payment/payment_screen.dart';

class DriverRequestsScreen extends StatelessWidget {
  const DriverRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride Requests'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseService().getDriverRequests(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.secondary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64.sp, color: AppColors.border),
                  SizedBox(height: 16.h),
                  Text(
                    'No pending requests!',
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Ride requests from passengers\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _RequestCard(booking: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final BookingModel booking;
  const _RequestCard({required this.booking});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isAccepting = false;
  bool _isRejecting = false;

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    final result = await FirebaseService().acceptBookingRequest(
      widget.booking.bookingId,
      widget.booking.rideId,
      widget.booking.seatsBooked,
    );
    setState(() => _isAccepting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );

      if (result['success'] == true) {
        // Show remaining seats info
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 64.sp),
                SizedBox(height: 16.h),
                Text('Request Accepted!',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text(
                  '${widget.booking.riderName} has been confirmed!\n${result['remainingSeats']} seat(s) remaining in your ride.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Great!'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _isRejecting = true);
    await FirebaseService()
        .rejectBookingRequest(widget.booking.bookingId);
    setState(() => _isRejecting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rider info
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor:
                AppColors.secondary.withOpacity(0.1),
                child: Icon(Icons.person_rounded,
                    color: AppColors.secondary, size: 26.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.riderName,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(b.riderPhone,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Seats badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  children: [
                    Text(
                      '${b.seatsBooked}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text('seat(s)',
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(color: AppColors.divider, height: 1),
          SizedBox(height: 12.h),

          // Route
          Row(
            children: [
              Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${b.from} → ${b.to}',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Amount
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded,
                  color: AppColors.success, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                '₹${b.totalPrice.toStringAsFixed(0)} total  •  ₹${b.pricePerSeat.toStringAsFixed(0)}/seat',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Accept / Reject buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRejecting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: _isRejecting
                      ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error))
                      : Icon(Icons.close_rounded,
                      color: AppColors.error, size: 18.sp),
                  label: Text('Decline',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAccepting ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: _isAccepting
                      ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white))
                      : Icon(Icons.check_rounded,
                      color: AppColors.white, size: 18.sp),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}