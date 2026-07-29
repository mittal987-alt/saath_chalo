import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../ride/ride_details_screen.dart';
import '../chat/ride_chat_screen.dart';
import '../ride/active_ride_screen.dart';
import '../payment/payment_screen.dart';
import '../rating/rating_screen.dart';
import 'report_issue_screen.dart';

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
          _buildOfferedRides(),
          _buildBookedRides(),
        ],
      ),
    );
  }

  Widget _buildOfferedRides() {
    return StreamBuilder<List<RideModel>>(
      stream: FirebaseService().getMyRides(_uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No offered rides found!', 'Rides you offer will appear here.');
        }

        final rides = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          physics: const BouncingScrollPhysics(),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _buildRideCard(rides[index]);
          },
        );
      },
    );
  }

  Widget _buildBookedRides() {
    return StreamBuilder<List<BookingModel>>(
      stream: FirebaseService().getMyBookings(_uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No booked rides found!', 'Rides you book will appear here.');
        }

        final bookings = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          physics: const BouncingScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getBookingStatusColor(booking.status);
    final isActive = ['accepted', 'confirmed', 'en_route', 'started'].contains(booking.status);
    final isCompleted = booking.status == 'ended';
    final isPending = booking.status == 'pending';
    final isCancelled = booking.status == 'cancelled' || booking.status == 'rejected';

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
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
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.3),
                ),
              ),
              Text(
                '₹${booking.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildRouteInfo(booking.from, booking.to, booking.rideDate, booking.rideTime),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14.sp, color: AppColors.textHint),
              SizedBox(width: 6.w),
              Text(
                booking.driverName,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              if (isActive)
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RideChatScreen(booking: booking, isDriver: false))),
                  icon: Icon(Icons.chat_rounded, color: AppColors.primary, size: 18.sp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              SizedBox(width: 8.w),
              if (isActive)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveRideScreen(booking: booking, isDriver: false))),
                  child: Text(
                    'Track Ride',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              if (isPending || (booking.status == 'accepted' && !isCompleted && !isCancelled))
                TextButton(
                  onPressed: () => _showCancelDialog(booking),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isCompleted)
                Row(
                  children: [
                    if (booking.paymentStatus != 'paid')
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking))),
                        child: Text('Pay Now', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      ),
                    SizedBox(width: 8.w),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RatingScreen(
                            rideId: booking.rideId,
                            driverName: booking.driverName,
                            driverUid: booking.driverUid,
                            from: booking.from,
                            to: booking.to,
                          ),
                        ),
                      ),
                      child: Text('Rate', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportIssueScreen(
                            reportedId: booking.rideId,
                            type: 'ride',
                            metadata: {
                              'bookingId': booking.bookingId,
                              'driverId': booking.driverUid,
                            },
                          ),
                        ),
                      ),
                      icon: Icon(Icons.report_problem_outlined, color: AppColors.error, size: 18.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, keep it'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await FirebaseService().cancelBooking(
                  bookingId: booking.bookingId,
                  rideId: booking.rideId,
                  seatsToReturn: booking.seatsBooked,
                  wasAccepted: booking.status != 'pending',
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Booking cancelled successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Yes, cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String from, String to, DateTime date, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Column(
            children: [
              Icon(Icons.circle, color: AppColors.primary, size: 8.sp),
              Column(
                children: List.generate(3, (index) => Container(
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
              Text(from, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              SizedBox(height: 14.h),
              Text(to, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('MMM d').format(date), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(time, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Color _getBookingStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted':
      case 'confirmed': return AppColors.primary;
      case 'started': return AppColors.success;
      case 'completed': return AppColors.textHint;
      case 'cancelled':
      case 'rejected': return AppColors.error;
      default: return AppColors.textHint;
    }
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
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
          _buildRouteInfo(ride.from, ride.to, ride.rideDate, ride.rideTime),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.directions_car_rounded, size: 14.sp, color: AppColors.textHint),
              SizedBox(width: 6.w),
              Text(
                ride.vehicle,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideDetailScreen(ride: ride),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10.sp, color: AppColors.primary),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportIssueScreen(
                      reportedId: ride.rideId,
                      type: 'ride',
                    ),
                  ),
                ),
                icon: Icon(Icons.report_problem_outlined, color: AppColors.error, size: 18.sp),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}