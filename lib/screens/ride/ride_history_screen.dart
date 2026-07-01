import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../ride/ride_details_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        title: const Text('Ride History'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.6),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Offered'),
            Tab(text: 'Booked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfferedRides(),
          _buildBookedRides(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1 — Rides I offered as driver
  // ─────────────────────────────────────────────
  Widget _buildOfferedRides() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverUid', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No rides offered yet!',
            subtitle: 'Rides you offer will appear here.',
          );
        }

        final rides = snapshot.data!.docs.map((doc) {
          return RideModel.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _OfferedRideCard(ride: rides[index]);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2 — Rides I booked as rider
  // ─────────────────────────────────────────────
  Widget _buildBookedRides() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('riderUid', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No rides booked yet!',
            subtitle: 'Rides you book will appear here.',
          );
        }

        final bookings = snapshot.data!.docs.map((doc) {
          return BookingModel.fromMap(
              doc.data() as Map<String, dynamic>);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _BookedRideCard(booking: bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: AppColors.border),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48.sp, color: AppColors.error),
            SizedBox(height: 12.h),
            Text(
              'Something went wrong!',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Offered Ride Card (Driver view)
// ─────────────────────────────────────────────
class _OfferedRideCard extends StatelessWidget {
  final RideModel ride;
  const _OfferedRideCard({required this.ride});

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'full': return AppColors.warning;
      case 'completed': return AppColors.primary;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active': return Icons.radio_button_checked;
      case 'full': return Icons.event_busy_rounded;
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
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
        children: [
          // Top color bar by status
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: _statusColor(ride.status),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Status + Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusIcon(ride.status),
                          color: _statusColor(ride.status),
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          ride.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(ride.status),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${ride.pricePerSeat.toStringAsFixed(0)}/seat',
                      style: TextStyle(
                        fontSize: 16.sp,
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
                          Text(
                            ride.from,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            ride.to,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ride.rideDate.day}/${ride.rideDate.month}/${ride.rideDate.year}',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          ride.rideTime,
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                Divider(color: AppColors.divider, height: 1),
                SizedBox(height: 12.h),

                // Seats + Requests + View Details
                Row(
                  children: [
                    // Seats left
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ride.availableSeats > 0
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_seat_rounded,
                            size: 12.sp,
                            color: ride.availableSeats > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${ride.availableSeats} left',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: ride.availableSeats > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Pending requests badge
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('rideId', isEqualTo: ride.rideId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_add_rounded,
                                  size: 12.sp,
                                  color: AppColors.secondary),
                              SizedBox(width: 4.w),
                              Text(
                                '$count request${count > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // View Details
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RideDetailScreen(ride: ride),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10.sp, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Booked Ride Card (Rider view)
// ─────────────────────────────────────────────
class _BookedRideCard extends StatelessWidget {
  final BookingModel booking;
  const _BookedRideCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.primary;
      case 'en_route': return AppColors.secondary;
      case 'started': return AppColors.success;
      case 'ended': return AppColors.textSecondary;
      case 'cancelled':
      case 'rejected': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Waiting for Driver';
      case 'confirmed': return 'Confirmed ✅';
      case 'en_route': return 'Driver Coming 🚗';
      case 'started': return 'Ride Started 🟢';
      case 'ended': return 'Completed ✅';
      case 'cancelled': return 'Cancelled ❌';
      case 'rejected': return 'Declined ❌';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool needsPayment = booking.status == 'ended' &&
        booking.paymentStatus == 'unpaid';

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: needsPayment
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top color bar
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: _statusColor(booking.status),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Status + Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _statusLabel(booking.status),
                        style: TextStyle(
                          fontSize: 12.sp,
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
                          Text(
                            booking.from,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            booking.to,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${booking.rideDate.day}/${booking.rideDate.month}/${booking.rideDate.year}',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          '${booking.seatsBooked} seat(s)',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                Divider(color: AppColors.divider, height: 1),
                SizedBox(height: 12.h),

                // Driver info + action
                Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 14.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      booking.driverName,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary),
                    ),

                    const Spacer(),

                    // Pay Now button if ride ended but unpaid
                    if (needsPayment)
                      GestureDetector(
                        onTap: () {
                          // Navigate to payment
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Pay ₹${booking.totalPrice.toStringAsFixed(0)}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    if (!needsPayment &&
                        booking.paymentStatus == 'paid')
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Paid ✅',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}