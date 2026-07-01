import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  bool _showResults = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  void _searchRides() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter from & to location')),
      );
      return;
    }
    setState(() => _showResults = true);
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
            if (_showResults) _buildLiveRideResults(),
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
            color: Colors.black.withOpacity(0.08),
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
              prefixIcon: Icon(Icons.circle,
                  color: AppColors.primary, size: 14.sp),
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
                  color: AppColors.primary.withOpacity(0.1),
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

  Widget _buildLiveRideResults() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('rides')
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56.sp, color: AppColors.border),
                    SizedBox(height: 12.h),
                    Text('No rides available right now!',
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          final fromQuery =
          _fromController.text.toLowerCase().trim();
          final toQuery = _toController.text.toLowerCase().trim();

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final from =
            (data['from'] ?? '').toString().toLowerCase();
            final to = (data['to'] ?? '').toString().toLowerCase();
            final seats = data['availableSeats'] ?? 0;
            final matchFrom =
                fromQuery.isEmpty || from.contains(fromQuery);
            final matchTo =
                toQuery.isEmpty || to.contains(toQuery);
            // Don't show user their own rides
            final notOwn =
                data['driverUid'] != _user?.uid;
            return seats > 0 && matchFrom && matchTo && notOwn;
          }).toList();

          if (docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Center(
                child: Text(
                  'No matching rides for this route!\nTry different locations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${docs.length} Rides Found',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              ...docs.map((doc) {
                final data =
                doc.data() as Map<String, dynamic>;
                return _LiveRideCard(
                  rideId: doc.id,
                  data: data,
                  currentUserUid: _user?.uid ?? '',
                  currentUserName:
                  _user?.displayName ?? 'Rider',
                  currentUserPhone:
                  _user?.phoneNumber ?? '',
                );
              }),
              SizedBox(height: 20.h),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual ride card — has its own live stream
// so seat count updates without rebuilding list
// ─────────────────────────────────────────────
class _LiveRideCard extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> data;
  final String currentUserUid;
  final String currentUserName;
  final String currentUserPhone;

  const _LiveRideCard({
    required this.rideId,
    required this.data,
    required this.currentUserUid,
    required this.currentUserName,
    required this.currentUserPhone,
  });

  @override
  State<_LiveRideCard> createState() => _LiveRideCardState();
}

class _LiveRideCardState extends State<_LiveRideCard> {
  int _seatsToBook = 1;
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final d = snap.data!.data() as Map<String, dynamic>;
        final int availableSeats = d['availableSeats'] ?? 0;
        final double pricePerSeat =
        (d['pricePerSeat'] ?? 0).toDouble();
        final String driverName = d['driverName'] ?? 'Driver';
        final String driverUid = d['driverUid'] ?? '';
        final String from = d['from'] ?? '';
        final String to = d['to'] ?? '';
        final String vehicle = d['vehicle'] ?? '';
        final String rideTime = d['rideTime'] ?? '';
        final double driverRating =
        (d['driverRating'] ?? 5.0).toDouble();

        if (availableSeats <= 0) return const SizedBox.shrink();

        // Clamp selector if seats reduced live
        if (_seatsToBook > availableSeats) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _seatsToBook = availableSeats);
          });
        }

        final double totalAmount = pricePerSeat * _seatsToBook;

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
            children: [
              // Driver row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor:
                    AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 26.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName,
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14.sp),
                            SizedBox(width: 2.w),
                            Text(driverRating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${pricePerSeat.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
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

              SizedBox(height: 16.h),
              Divider(color: AppColors.divider, height: 1),
              SizedBox(height: 16.h),

              // Route
              Row(
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle,
                          color: AppColors.primary, size: 10.sp),
                      Container(
                          width: 1.5,
                          height: 24.h,
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
                        Text(from,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 16.h),
                        Text(to,
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
                      Text(rideTime,
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 16.h),

                      // ✅ Live seat badge — updates instantly!
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: availableSeats <= 1
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_seat_rounded,
                                size: 12.sp,
                                color: availableSeats <= 1
                                    ? AppColors.error
                                    : AppColors.success),
                            SizedBox(width: 4.w),
                            Text(
                              '$availableSeats left',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: availableSeats <= 1
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Vehicle chip
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: 16.sp,
                        color: AppColors.textSecondary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(vehicle,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ✅ Seat selector — clamped to availableSeats
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seats to book',
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _seatsToBook > 1
                              ? () =>
                              setState(() => _seatsToBook--)
                              : null,
                          child: Icon(Icons.remove_circle_outline,
                              color: _seatsToBook > 1
                                  ? AppColors.primary
                                  : AppColors.border,
                              size: 28.sp),
                        ),
                        SizedBox(width: 16.w),
                        Text('$_seatsToBook',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: _seatsToBook < availableSeats
                              ? () =>
                              setState(() => _seatsToBook++)
                              : null,
                          child: Icon(Icons.add_circle_outline,
                              color: _seatsToBook < availableSeats
                                  ? AppColors.primary
                                  : AppColors.border,
                              size: 28.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // ✅ Total amount — always accurate
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_seatsToBook seat${_seatsToBook > 1 ? 's' : ''} × ₹${pricePerSeat.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Request button
              ElevatedButton(
                onPressed: _isRequesting
                    ? null
                    : () => _sendBookingRequest(
                  driverUid,
                  driverName,
                  from,
                  to,
                  pricePerSeat,
                  totalAmount,
                ),
                child: _isRequesting
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2),
                )
                    : Text(
                    'Request $_seatsToBook Seat${_seatsToBook > 1 ? 's' : ''}'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendBookingRequest(
      String driverUid,
      String driverName,
      String from,
      String to,
      double pricePerSeat,
      double totalAmount,
      ) async {
    setState(() => _isRequesting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      print('DEBUG: Current UID = ${user?.uid}');
      print('DEBUG: Current Name = ${user?.displayName}');
      final bookingId =
      DateTime.now().millisecondsSinceEpoch.toString();


      final booking = BookingModel(
        bookingId: bookingId,
        rideId: widget.rideId,
        riderUid: user?.uid ?? '',        // ✅ Must match logged in user
        riderName: user?.displayName ?? 'Rider',
        riderPhone: user?.phoneNumber ?? '',
        driverUid: driverUid,
        driverName: driverName,
        from: from,
        to: to,
        rideDate: DateTime.now(),         // ✅ Add rideDate
        rideTime: '',
        seatsBooked: _seatsToBook,
        totalPrice: totalAmount,          // ✅ Use totalPrice not totalAmount
        pricePerSeat: pricePerSeat,
        paymentMethod: 'Razorpay',
        createdAt: DateTime.now(),
      );


      await FirebaseService().createBookingRequest(booking);
      setState(() => _isRequesting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_rounded,
                    color: AppColors.primary, size: 64.sp),
                SizedBox(height: 16.h),
                Text('Request Sent! ⏳',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text(
                  'Waiting for $driverName to accept.\nYou\'ll get a notification once confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_seatsToBook seat(s)',
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary)),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK, Got It!'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isRequesting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}