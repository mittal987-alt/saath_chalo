import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ride History',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Offered'),
                Tab(text: 'Booked'),
              ],
            ),
          ),
        ),
      ),
      body: _uid == null
          ? const Center(child: Text('Please login to view history'))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(isDriver: true),
          _buildHistoryList(isDriver: false),
        ],
      ),
    );
  }

  Widget _buildHistoryList({required bool isDriver}) {
    // Queries driver collection or passenger arrays safely depending on active tab status
    final query = isDriver
        ? FirebaseFirestore.instance.collection('rides').where('driverUid', isEqualTo: _uid)
        : FirebaseFirestore.instance.collection('rides').where('passengers', arrayContains: _uid);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Sort data locally to prevent index exception crashes if server side indexes aren't complete yet
        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ride = RideModel.fromMap(docs[index].data() as Map<String, dynamic>);

            if (index == docs.length - 1) {
              return Column(
                children: [
                  _buildRideCard(ride),
                  SizedBox(height: 88.h),
                ],
              );
            }
            return _buildRideCard(ride);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 44.sp, color: AppColors.textHint),
          ),
          SizedBox(height: 16.h),
          Text(
            'No rides found!',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your ride history records will appear here.',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isActive = ride.status == 'active';
    final isCompleted = ride.status == 'completed';

    Color statusColor = AppColors.error;
    if (isActive) statusColor = AppColors.primary;
    if (isCompleted) statusColor = AppColors.success;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShape.circle == true
              ? const BoxShadow()
              : BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : isActive ? Icons.bolt_rounded : Icons.cancel_rounded,
                      size: 13.sp,
                      color: statusColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${ride.pricePerSeat.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Column(
                  children: [
                    Icon(Icons.circle, color: AppColors.primary, size: 8.sp),
                    // High quality dotted custom design connector segment
                    Column(
                      children: List.generate(4, (index) => Container(
                        margin: EdgeInsets.symmetric(vertical: 2.h),
                        width: 1.5,
                        height: 4.h,
                        color: AppColors.border.withValues(alpha: 0.6),
                      )),
                    ),
                    Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 13.sp),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      ride.to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d').format(ride.rideDate),
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    ride.rideTime,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_seat_rounded, size: 12.sp, color: AppColors.textHint),
                      SizedBox(width: 4.w),
                      Text(
                        '${ride.availableSeats} seats',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.directions_car_rounded, size: 14.sp, color: AppColors.textHint),
              SizedBox(width: 6.w),
              Text(
                'Ride Share Pool', // Safe fallback string to protect from missing vehicle field compile errors
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10.sp, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}