import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_services.dart';
import '../../models/ride_model.dart';
import '../../models/ride_alert_model.dart';
import '../../core/constants/app_colors.dart';
import '../payment/payment_screen.dart';
import 'live_tracking_screen.dart';
import '../rating/rating_screen.dart';
import 'package:uuid/uuid.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _seats = 1;
  bool _showResults = false;

  // ✅ Real data from Firebase
  Stream<List<RideModel>>? _ridesStream;

  void _searchRides() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter from & to location')),
      );
      return;
    }
    setState(() {
      _showResults = true;
      _ridesStream = FirebaseService().searchRides(
        _fromController.text,
        _toController.text,
      );
    });
  }

  Future<void> _setRideAlert() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final alert = RideAlertModel(
      id: const Uuid().v4(),
      uid: uid,
      from: _fromController.text,
      to: _toController.text,
      rideDate: _selectedDate,
      createdAt: DateTime.now(),
    );

    await FirebaseService().createRideAlert(alert);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride alert set! We will notify you when a match is found.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a Ride'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchCard(),
            if (_showResults) _buildRideResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From',
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _fromController,
            decoration: InputDecoration(
              hintText: 'Starting location',
              prefixIcon:
              Icon(Icons.circle, color: AppColors.primary, size: 14.sp),
            ),
          ),

          SizedBox(height: 8.h),

          Center(
            child: GestureDetector(
              onTap: () {
                final temp = _fromController.text;
                _fromController.text = _toController.text;
                _toController.text = temp;
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_vert_rounded,
                    color: AppColors.primary, size: 20.sp),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          Text('To',
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _toController,
            decoration: InputDecoration(
              hintText: 'Destination',
              prefixIcon: Icon(Icons.location_on,
                  color: AppColors.secondary, size: 20.sp),
            ),
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                      DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_seats > 1) setState(() => _seats--);
                        },
                        child: const Icon(Icons.remove_circle_outline,
                            color: AppColors.primary),
                      ),
                      Row(
                        children: [
                          Icon(Icons.event_seat_rounded,
                              color: AppColors.primary, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text('$_seats',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_seats < 4) setState(() => _seats++);
                        },
                        child: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          ElevatedButton.icon(
            onPressed: _searchRides,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search Rides'),
          ),
        ],
      ),
    );
  }

  Widget _buildRideResults() {
    return StreamBuilder<List<RideModel>>(
      stream: _ridesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                  SizedBox(height: 12.h),
                  const Text(
                    'Setting up search index...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  const Text(
                    'Please click the link in the console to create the required Firestore index.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                const Center(child: Text('No rides found for this route')),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _setRideAlert,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Notify me when available'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rides.length} Rides Found',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              ...rides.map((ride) => _buildRideCard(ride)),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r), // Premium rounded corners
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        child: Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 28.sp),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.driverName,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 14.sp),
                                    SizedBox(width: 2.w),
                                    Text('${ride.driverRating}',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[800])),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 14.sp),
                              SizedBox(width: 2.w),
                              Text('Verified', style: TextStyle(fontSize: 11.sp, color: AppColors.primary)),
                            ],
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
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Text('per seat',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.radio_button_checked, color: AppColors.primary, size: 16.sp),
                        Container(width: 2, height: 30.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                        ),
                        Icon(Icons.location_on_rounded,
                            color: AppColors.secondary, size: 18.sp),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.from,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 28.h),
                          Text(ride.to,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(ride.rideTime,
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Icon(Icons.event_seat_rounded,
                                size: 16.sp, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Text('${ride.availableSeats} Left',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: ride.availableSeats < 2 ? AppColors.error : AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car_filled_rounded,
                                size: 18.sp, color: AppColors.textSecondary),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(ride.vehicle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _buildFeatureIcon(Icons.ac_unit_rounded, "AC"),
                    SizedBox(width: 8.w),
                    _buildFeatureIcon(Icons.music_note_rounded, "Music"),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RatingScreen(
                            rideId: ride.rideId,
                            driverName: ride.driverName,
                            driverUid: ride.driverUid,
                            from: ride.from,
                            to: ride.to,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('View Profile'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Send request notification to driver
                      await FirebaseService().sendNotification(
                        toUid: ride.driverUid,
                        title: 'New Ride Request! 🚗',
                        body: '${FirebaseAuth.instance.currentUser?.displayName ?? 'Someone'} wants to join your ride from ${ride.from} to ${ride.to}.',
                        type: 'ride_request',
                        data: {'rideId': ride.rideId},
                      );

                      if (!context.mounted) return;

                      // Go to payment first
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            rideId: ride.rideId,
                            driverName: ride.driverName,
                            from: ride.from,
                            to: ride.to,
                            pricePerSeat: ride.pricePerSeat,
                            seats: _seats,
                          ),
                        ),
                      );

                      if (!context.mounted) return;

                      // After payment, open live tracking
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveTrackingScreen(
                            rideId: ride.rideId,
                            isDriver: false,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 16.sp, color: AppColors.primary),
    );
  }
}