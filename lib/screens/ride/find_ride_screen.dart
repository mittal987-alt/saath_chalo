import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../../widgets/shimmer_loading.dart';

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
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter from & to location'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium SliverAppBar ─────────────────────
          SliverAppBar(
            expandedHeight: 110.h,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20.w, 0, 0, 16.h),
              title: Text(
                'Find a Ride',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F9D58),
                      Color(0xFF0B8043),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchCard(isDark),
                if (_showResults) _buildLiveRideResults(isDark),
                if (!_showResults) _buildIdleState(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From field
          _buildSearchFieldLabel('From', Icons.radio_button_checked, AppColors.primary, isDark),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _fromController,
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15.sp),
            decoration: _searchInputDeco('e.g. Connaught Place, Delhi', isDark),
          ),

          // Swap button
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final temp = _fromController.text;
                  _fromController.text = _toController.text;
                  _toController.text = temp;
                },
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22.sp),
                ),
              ),
            ),
          ),

          // To field
          _buildSearchFieldLabel('To', Icons.location_on_rounded, AppColors.error, isDark),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _toController,
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15.sp),
            decoration: _searchInputDeco('e.g. Noida Sector 18', isDark),
          ),

          SizedBox(height: 20.h),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _searchRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                label: Text('Search Rides', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFieldLabel(String label, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  InputDecoration _searchInputDeco(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }

  Widget _buildIdleState(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        children: [
          SizedBox(
            height: 180.h,
            child: Lottie.network('https://lottie.host/a4de3b1d-e5dd-481b-9cb2-77fd1ef91db4/cepFJ2VJbA.json'),
          ),
          Text(
            'Find your perfect carpool',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your pickup and drop-off locations above to search for available rides near you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRideResults(bool isDark) {
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
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                children: List.generate(3, (index) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: ShimmerLoading(width: double.infinity, height: 220.h, borderRadius: 20.r),
                )),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Column(
                children: [
                  SizedBox(
                    height: 160.h,
                    child: Lottie.network('https://lottie.host/804c8612-4cf0-4963-8a30-80252ad8b9ed/cWl4XFhH0R.json'),
                  ),
                  Text('No rides available right now!',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  SizedBox(height: 6.h),
                  Text('Try different locations or check back later.', style: TextStyle(fontSize: 12.sp, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            );
          }

          final fromQuery = _fromController.text.toLowerCase().trim();
          final toQuery = _toController.text.toLowerCase().trim();

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final from = (data['from'] ?? '').toString().toLowerCase();
            final to = (data['to'] ?? '').toString().toLowerCase();
            final seats = data['availableSeats'] ?? 0;
            final matchFrom = fromQuery.isEmpty || from.contains(fromQuery);
            final matchTo = toQuery.isEmpty || to.contains(toQuery);
            final notOwn = data['driverUid'] != _user?.uid;
            return seats > 0 && matchFrom && matchTo && notOwn;
          }).toList();

          if (docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Column(
                children: [
                  Icon(Icons.route_rounded, size: 56.sp, color: AppColors.border),
                  SizedBox(height: 12.h),
                  Text(
                    'No matching rides for this route!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                  SizedBox(height: 6.h),
                  Text('Try different locations.', style: TextStyle(fontSize: 12.sp, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${docs.length} Rides Found 🎉',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _LiveRideCard(
                  rideId: doc.id,
                  data: data,
                  currentUserUid: _user?.uid ?? '',
                  currentUserName: _user?.displayName ?? 'Rider',
                  currentUserPhone: _user?.phoneNumber ?? '',
                  isDark: isDark,
                );
              }),
              SizedBox(height: 100.h),
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
  final bool isDark;

  const _LiveRideCard({
    required this.rideId,
    required this.data,
    required this.currentUserUid,
    required this.currentUserName,
    required this.currentUserPhone,
    required this.isDark,
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

        // Preferences
        final bool musicAllowed = d['preferences']?['musicAllowed'] ?? d['musicAllowed'] ?? true;
        final bool petsAllowed = d['preferences']?['petsAllowed'] ?? d['petsAllowed'] ?? false;
        final bool smokingAllowed = d['preferences']?['smokingAllowed'] ?? d['smokingAllowed'] ?? false;
        final bool acPreferred = d['preferences']?['acPreferred'] ?? d['acPreferred'] ?? true;
        final bool womenOnly = d['womenOnly'] ?? false;

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
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCardBg : AppColors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: widget.isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(widget.isDark ? 0.0 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
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

              SizedBox(height: 12.h),

              // Preferences row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (womenOnly)
                      _buildPrefChip('Women Only', Icons.woman_rounded, Colors.pink),
                    _buildPrefChip(
                      musicAllowed ? 'Music' : 'No Music',
                      musicAllowed ? Icons.music_note_rounded : Icons.music_off_rounded,
                      musicAllowed ? Colors.blue : Colors.grey,
                    ),
                    _buildPrefChip(
                      petsAllowed ? 'Pets' : 'No Pets',
                      petsAllowed ? Icons.pets_rounded : Icons.not_interested_rounded,
                      petsAllowed ? Colors.orange : Colors.grey,
                    ),
                    _buildPrefChip(
                      smokingAllowed ? 'Smoking' : 'No Smoking',
                      smokingAllowed ? Icons.smoking_rooms_rounded : Icons.smoke_free_rounded,
                      smokingAllowed ? Colors.red : Colors.grey,
                    ),
                    _buildPrefChip(
                      acPreferred ? 'AC' : 'No AC',
                      acPreferred ? Icons.ac_unit_rounded : Icons.toys_rounded,
                      acPreferred ? Colors.cyan : Colors.grey,
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

  Widget _buildPrefChip(String label, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

      String riderName = user?.displayName ?? '';
      if (riderName.isEmpty) {
        // Try email prefix as fallback
        riderName = user?.email?.split('@').first ?? 'Rider';
      }
      final bookingId =
      DateTime.now().millisecondsSinceEpoch.toString();


      final booking = BookingModel(
        bookingId: bookingId,
        rideId: widget.rideId,
        riderUid: user?.uid ?? '',
        riderName: riderName,          // ✅ Never empty now
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