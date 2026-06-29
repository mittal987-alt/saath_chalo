import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class AdminRidesScreen extends StatelessWidget {
  const AdminRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Rides'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1A237E)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 64.sp, color: AppColors.border),
                  SizedBox(height: 16.h),
                  Text('No rides yet!',
                      style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data()
              as Map<String, dynamic>;
              final docId = snapshot.data!.docs[index].id;
              return _buildRideCard(context, data, docId);
            },
          );
        },
      ),
    );
  }

  Widget _buildRideCard(
      BuildContext context, Map<String, dynamic> data, String rideId) {
    final status = data['status'] ?? 'active';
    final isActive = status == 'active';

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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
              Text(
                '₹${data['pricePerSeat'] ?? 0}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                data['driverName'] ?? 'Unknown Driver',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.route_rounded,
                  color: AppColors.secondary, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                '${data['from'] ?? ''} → ${data['to'] ?? ''}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_seat_rounded,
                      color: AppColors.textHint, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '${data['availableSeats'] ?? 0} seats',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (isActive)
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('rides')
                        .doc(rideId)
                        .update({'status': 'cancelled'});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ride cancelled by admin!'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                  icon: Icon(Icons.cancel_rounded,
                      color: AppColors.error, size: 16.sp),
                  label: Text(
                    'Cancel Ride',
                    style: TextStyle(
                        color: AppColors.error, fontSize: 12.sp),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}