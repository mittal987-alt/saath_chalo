import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../../l10n/app_localizations.dart';
import 'driver_requests_screen.dart';
import 'active_ride_screen.dart';

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 1;
  bool _womenOnly = false;
  bool _musicAllowed = true;
  bool _petsAllowed = false;
  bool _smokingAllowed = false;
  bool _acPreferred = true;
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDefaults();
  }

  void _loadUserDefaults() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await FirebaseService().getUser(uid);
      if (user != null && mounted) {
        setState(() {
          _musicAllowed = user.musicAllowed;
          _petsAllowed = user.petsAllowed;
          _smokingAllowed = user.smokingAllowed;
          _acPreferred = user.acPreferred;
        });
      }
    }
  }

  void _offerRide() async {
    final l10n = AppLocalizations.of(context);
    if (_fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _vehicleController.text.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.fillAllFields ?? 'Please fill all fields!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final rideId = DateTime.now().millisecondsSinceEpoch.toString();

      final ride = RideModel(
        rideId: rideId,
        driverUid: user?.uid ?? '',
        driverName: user?.displayName ?? 'User',
        driverPhone: user?.phoneNumber ?? '',
        vehicle: _vehicleController.text,
        from: _fromController.text,
        to: _toController.text,
        fromLat: 0.0,
        fromLng: 0.0,
        toLat: 0.0,
        toLng: 0.0,
        rideDate: _selectedDate,
        rideTime: _selectedTime.format(context),
        availableSeats: _seats,
        pricePerSeat: double.parse(_priceController.text),
        womenOnly: _womenOnly,
        musicAllowed: _musicAllowed,
        petsAllowed: _petsAllowed,
        smokingAllowed: _smokingAllowed,
        acPreferred: _acPreferred,
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
      );

      await FirebaseService().offerRide(ride);
      setState(() => _isLoading = false);

      HapticFeedback.heavyImpact();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
            contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  SizedBox(
                    height: 140.h,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 70.sp,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                Text(
                  l10n?.ridePublished ?? 'Ride Published! 🎉',
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n?.ridePublishedSubtitle ?? 'Your ride is now live on SaathChalo. Passengers can start requesting seats!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                      child: Text(l10n?.awesome ?? 'Awesome!', style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Widget _buildActiveRideBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getDriverActiveBookings(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final booking = BookingModel.fromMap(
            snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {});

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveRideScreen(
                booking: booking,
                isDriver: true,
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E8E3E), Color(0xFF0F9D58)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.radio_button_checked, color: Colors.white, size: 14.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Ride In Progress', style: TextStyle(fontSize: 11.sp, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                      Text('${booking.from} → ${booking.to}', style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110.h,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20.w, 0, 0, 16.h),
              title: Text(l10n?.offerRide ?? 'Offer a Ride', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF1A3C34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRequestsScreen()));
                },
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(child: Column(children: [
          _buildActiveRideBanner(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 40.h),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: '📍 ${l10n?.routeDetails ?? 'Route Details'}',
                    child: Column(
                      children: [
                        _buildLabel(l10n?.from ?? 'From'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _fromController,
                          decoration: InputDecoration(
                            hintText: l10n?.startingLocation ?? 'Starting location',
                            prefixIcon: Icon(Icons.circle,
                                color: AppColors.primary, size: 12.sp),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildLabel(l10n?.to ?? 'To'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _toController,
                          decoration: InputDecoration(
                            hintText: l10n?.destination ?? 'Destination',
                            prefixIcon: Icon(Icons.location_on,
                                color: AppColors.secondary, size: 20.sp),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSectionCard(
                    title: '🕐 ${l10n?.dateTime ?? 'Date & Time'}',
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      color: AppColors.primary, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() => _selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      color: AppColors.primary, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSectionCard(
                    title: '🚗 ${l10n?.vehiclePrice ?? 'Vehicle & Price'}',
                    child: Column(
                      children: [
                        _buildLabel(l10n?.vehicleDetails ?? 'Vehicle Details'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _vehicleController,
                          decoration: InputDecoration(
                            hintText: l10n?.vehicleHint ?? 'e.g. Swift Dzire • DL 4C 1234',
                            prefixIcon:
                                const Icon(Icons.directions_car_rounded),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.pricePerSeat ?? 'Price per Seat'),
                                  SizedBox(height: 8.h),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: l10n?.amountHint ?? '₹ Amount',
                                      prefixIcon: const Icon(
                                          Icons.currency_rupee_rounded),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.availableSeats ?? 'Available Seats'),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 10.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      color: AppColors.background,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (_seats > 1) {
                                              setState(() => _seats--);
                                            }
                                          },
                                          child: const Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors.primary),
                                        ),
                                        Text('$_seats',
                                            style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold)),
                                        GestureDetector(
                                          onTap: () {
                                            if (_seats < 4) {
                                              setState(() => _seats++);
                                            }
                                          },
                                          child: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSectionCard(
                    title: '⚙️ ${l10n?.preferences ?? 'Preferences'}',
                    child: Column(
                      children: [
                        _buildPreferenceToggle(
                          title: l10n?.womenOnlyRide ?? 'Women Only Ride 👩',
                          subtitle: l10n?.womenOnlySubtitle ?? 'Only women can request this ride',
                          value: _womenOnly,
                          onChanged: (val) => setState(() => _womenOnly = val),
                        ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n?.paymentMethodLabel ?? 'Payment Method 💰', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text(l10n?.paymentSubtitle ?? 'How passengers should pay', style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: DropdownButton<String>(
                                  value: _paymentMethod,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                  items: ['Cash', 'Online UPI', 'Both'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentMethod = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        _buildPreferenceToggle(
                          title: l10n?.musicAllowedLabel ?? 'Music Allowed 🎵',
                          subtitle: l10n?.musicSubtitle ?? 'Can passengers play music?',
                          value: _musicAllowed,
                          onChanged: (val) =>
                              setState(() => _musicAllowed = val),
                        ),
                        _buildPreferenceToggle(
                          title: l10n?.petsAllowedLabel ?? 'Pets Allowed 🐾',
                          subtitle: l10n?.petsSubtitle ?? 'Can passengers bring pets?',
                          value: _petsAllowed,
                          onChanged: (val) =>
                              setState(() => _petsAllowed = val),
                        ),
                        _buildPreferenceToggle(
                          title: l10n?.smokingAllowedLabel ?? 'Smoking Allowed 🚬',
                          subtitle: l10n?.smokingSubtitle ?? 'Is smoking allowed in the car?',
                          value: _smokingAllowed,
                          onChanged: (val) =>
                              setState(() => _smokingAllowed = val),
                        ),
                        _buildPreferenceToggle(
                          title: l10n?.acPreferredLabel ?? 'AC Preferred ❄️',
                          subtitle: l10n?.acSubtitle ?? 'Will the AC be switched on?',
                          value: _acPreferred,
                          onChanged: (val) =>
                              setState(() => _acPreferred = val),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoading
                              ? [AppColors.textHint, AppColors.textHint]
                              : AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(_isLoading ? 0 : 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _offerRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                        ),
                        icon: _isLoading
                            ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        label: Text(
                          _isLoading ? (l10n?.publishing ?? 'Publishing...') : (l10n?.publishRide ?? 'Publish Ride'),
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
          ),
          ])),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final isDark = false; // Will use Theme.of(context) in real use
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeTrackColor: AppColors.primary.withOpacity(0.2),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
