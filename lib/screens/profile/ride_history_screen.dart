import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: uid == null 
        ? const Center(child: Text('Please login to view history'))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .where('driverUid', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final ride = RideModel.fromMap(
                      snapshot.data!.docs[index].data() as Map<String, dynamic>);
                  return _buildRideCard(ride);
                },
              );
            },
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64.sp, color: AppColors.border),
          SizedBox(height: 16.h),
          Text(
            'No rides yet!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your completed rides will appear here.',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isCompleted = ride.status == 'active' || ride.status == 'completed';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${ride.pricePerSeat.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, height: 1),
          SizedBox(height: 12.h),

          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.circle,
                      color: AppColors.primary, size: 10.sp),
                  Container(
                      width: 1.5,
                      height: 20.h,
                      color: AppColors.border),
                  Icon(Icons.location_on,
                      color: AppColors.secondary, size: 14.sp),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.from,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 12.h),
                    Text(ride.to,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${DateFormat('MMM d').format(ride.rideDate)}, ${ride.rideTime}',
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary)),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(Icons.event_seat_rounded,
                          size: 12.sp,
                          color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text('${ride.availableSeats} seats',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}