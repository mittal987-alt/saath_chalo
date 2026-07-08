import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import 'driver_requests_screen.dart';
import 'active_ride_screen.dart';
import '../chat/ride_chat_screen.dart';
import 'ride_sharing_screen.dart';
import '../profile/report_issue_screen.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;
  final _firebaseService = FirebaseService();

  RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          StreamBuilder<List<BookingModel>>(
            stream: _firebaseService.getBookingsForRide(ride.rideId,
                statuses: ['pending']),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DriverRequestsScreen()),
                    ),
                    icon: const Icon(Icons.people_rounded),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
            icon: const Icon(Icons.report_problem_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildStatusCard(),
            SizedBox(height: 16.h),
            _buildRouteCard(),
            SizedBox(height: 16.h),
            _buildDetailsCard(),
            SizedBox(height: 16.h),
            _buildPassengersCard(),
            SizedBox(height: 16.h),
            _buildActionButtons(context),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildStatusCard() {
    final bool isActive = ride.status == 'active';
    final bool isCancelled = ride.status == 'cancelled';
    final bool isFull = ride.status == 'full';

    Color startColor;
    Color endColor;
    IconData statusIcon;
    String statusText;

    if (isActive) {
      startColor = AppColors.primary;
      endColor = AppColors.primaryDark;
      statusIcon = Icons.radio_button_checked;
      statusText = 'Active Ride 🟢';
    } else if (isCancelled) {
      startColor = AppColors.error;
      endColor = AppColors.error.withOpacity(0.8);
      statusIcon = Icons.cancel_rounded;
      statusText = 'Cancelled ❌';
    } else if (isFull) {
      startColor = AppColors.warning;
      endColor = AppColors.warning.withOpacity(0.8);
      statusIcon = Icons.event_busy_rounded;
      statusText = 'Fully Booked 🎫';
    } else {
      startColor = AppColors.textSecondary;
      endColor = AppColors.textHint;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Completed ✅';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: AppColors.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${ride.from} → ${ride.to}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.white.withOpacity(0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${ride.pricePerSeat.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                'per seat',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildRouteCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.circle, color: AppColors.primary, size: 12.sp),
                  Container(width: 2, height: 32.h, color: AppColors.border),
                  Icon(Icons.location_on, color: AppColors.secondary, size: 16.sp),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      ride.to,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ride.rideDate.day}/${ride.rideDate.month}/${ride.rideDate.year}',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    ride.rideTime,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Details',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(Icons.directions_car_rounded, 'Vehicle', ride.vehicle),
          _buildDetailRow(Icons.event_seat_rounded, 'Available Seats',
              '${ride.availableSeats}'),
          _buildDetailRow(Icons.currency_rupee_rounded, 'Price per Seat',
              '₹${ride.pricePerSeat.toStringAsFixed(0)}'),
          _buildDetailRow(Icons.woman_rounded, 'Women Only',
              ride.womenOnly ? 'Yes 👩' : 'No'),
          const Divider(),
          _buildDetailRow(Icons.music_note_rounded, 'Music Allowed',
              ride.musicAllowed ? 'Yes 🎵' : 'No'),
          _buildDetailRow(Icons.pets_rounded, 'Pets Allowed',
              ride.petsAllowed ? 'Yes 🐾' : 'No'),
          _buildDetailRow(Icons.smoking_rooms_rounded, 'Smoking Allowed',
              ride.smokingAllowed ? 'Yes 🚬' : 'No'),
          _buildDetailRow(Icons.ac_unit_rounded, 'AC Preferred',
              ride.acPreferred ? 'Yes ❄️' : 'No'),
          _buildDetailRow(Icons.info_rounded, 'Status', ride.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildPassengersCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          SizedBox(height: 12.h),
          StreamBuilder<List<BookingModel>>(
            stream: _firebaseService.getBookingsForRide(
              ride.rideId,
              statuses: ['accepted', 'confirmed', 'en_route', 'started', 'ended'],
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Column(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 40, color: AppColors.border),
                    const SizedBox(height: 8),
                    Text(
                      'No passengers yet.\nShare your ride to get passengers!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.sp, color: AppColors.textSecondary),
                    ),
                  ],
                );
              }

              return Column(
                children: snapshot.data!.map((b) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: _statusColor(b.status).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18.r,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 20.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.riderName.isEmpty ? 'Rider' : b.riderName,
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                              Text(
                                '${b.seatsBooked} seat(s)  •  ₹${b.totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 11.sp, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _statusColor(b.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            b.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(b.status),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportIssueScreen(
                                reportedId: b.riderUid,
                                type: 'user',
                                metadata: {
                                  'rideId': ride.rideId,
                                  'bookingId': b.bookingId,
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
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // ── View Requests Button ──────────────
        StreamBuilder<List<BookingModel>>(
          stream: _firebaseService.getBookingsForRide(ride.rideId,
              statuses: ['pending']),
          builder: (context, snap) {
            final count = snap.data?.length ?? 0;
            return ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    count > 0 ? AppColors.secondary : AppColors.primary,
                minimumSize: Size(double.infinity, 48.h),
              ),
              icon: const Icon(Icons.people_rounded),
              label: Text(
                count > 0
                    ? 'View $count Pending Request${count > 1 ? 's' : ''}  🔔'
                    : 'View All Requests',
              ),
            );
          },
        ),

// Add at top of action buttons:
    StreamBuilder<List<BookingModel>>(
    stream: _firebaseService.getBookingsForRide(
    ride.rideId,
    statuses: ['accepted', 'confirmed', 'en_route', 'started'],
    ),
    builder: (context, snap) {
    if (!snap.hasData || snap.data!.isEmpty) {
    return const SizedBox.shrink();
    }
    final booking = snap.data!.first;
    return Column(
    children: [
    ElevatedButton.icon(
    onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => RideSharingScreen(
    booking: booking,
    isDriver: true,
    ),
    ),
    ),
    style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    minimumSize: Size(double.infinity, 48.h),
    ),
    icon: const Icon(Icons.share_location_rounded),
    label: const Text('Share Ride & Navigate 🗺️'),
    ),
    SizedBox(height: 12.h),
    ],
    );
    },
    ),

        SizedBox(height: 12.h),

        // ── Chat Buttons per Passenger ────────
        StreamBuilder<List<BookingModel>>(
          stream: _firebaseService.getBookingsForRide(
            ride.rideId,
            statuses: ['accepted', 'confirmed', 'en_route', 'started'],
          ),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                // Section label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chat with Passengers',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                ...snap.data!.map((booking) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RideChatScreen(
                            booking: booking,
                            isDriver: true,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 44.h),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.chat_rounded,
                          color: AppColors.primary, size: 16.sp),
                      label: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chat with ${booking.riderName.isEmpty ? 'Rider' : booking.riderName}',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13.sp),
                            ),
                          ),
                          // Unread indicator
                          _buildUnreadBadge(booking.bookingId),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 4.h),
              ],
            );
          },
        ),

        // ── Open Active Ride Map ──────────────
        StreamBuilder<List<BookingModel>>(
          stream: _firebaseService.getBookingsForRide(
            ride.rideId,
            statuses: ['accepted', 'confirmed', 'en_route', 'started'],
          ),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final booking = snap.data!.first;
            return Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveRideScreen(
                        booking: booking,
                        isDriver: true,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Open Active Ride Map'),
                ),
                SizedBox(height: 12.h),
              ],
            );
          },
        ),

        // ── Cancel Ride ───────────────────────
        if (ride.status == 'active')
          Builder(
            builder: (context) => OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r)),
                    title: const Text('Cancel Ride?'),
                    content: const Text(
                        'This will cancel your ride and notify all passengers.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _firebaseService.updateRideStatus(
                      ride.rideId, 'cancelled');
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
              label: const Text('Cancel Ride',
                  style: TextStyle(color: AppColors.error)),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Unread message badge for each chat button
  // ─────────────────────────────────────────────
  Widget _buildUnreadBadge(String bookingId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_chats')
          .doc(bookingId)
          .collection('messages')
          .where('isDriver', isEqualTo: false)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '$count new',
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return AppColors.primary;
      case 'en_route':
        return AppColors.secondary;
      case 'started':
        return AppColors.success;
      case 'ended':
      case 'completed':
        return AppColors.textSecondary;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }
}
