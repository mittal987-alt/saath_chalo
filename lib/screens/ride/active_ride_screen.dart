import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/ride_status.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_services.dart';
import '../../services/location_services.dart';
import '../payment/payment_screen.dart';
import 'ride_sharing_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isDriver;

  const ActiveRideScreen({
    super.key,
    required this.booking,
    required this.isDriver,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _currentStatus = '';
  double _driverLat = 0;
  double _driverLng = 0;
  double _driverSpeed = 0;
  String _eta = '';
  bool _isUpdatingStatus = false;
  Position? _myPosition;

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status;
    _initLocation();
    // Driver starts sharing location automatically
    if (widget.isDriver) {
      _locationService.startSharingLocation(
          widget.booking.rideId, true);
    }
  }

  Future<void> _initLocation() async {
    _myPosition = await LocationService.getCurrentPosition();
    if (_myPosition != null && mounted) {
      setState(() {});
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                _myPosition!.latitude, _myPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  // Called whenever driver location updates in Firestore
  void _onDriverLocationUpdated(Map<String, dynamic> loc) {
    final lat = (loc['lat'] ?? 0).toDouble();
    final lng = (loc['lng'] ?? 0).toDouble();
    final speed = (loc['speed'] ?? 0).toDouble();

    setState(() {
      _driverLat = lat;
      _driverLng = lng;
      _driverSpeed = speed;
    });

    // Update driver marker
    _updateMarker(
      'driver',
      lat,
      lng,
      widget.isDriver ? 'You (Driver)' : 'Your Driver',
      BitmapDescriptor.hueBlue,
    );

    // Calculate ETA for rider
    if (!widget.isDriver && _myPosition != null) {
      final distance = Geolocator.distanceBetween(
        lat, lng,
        _myPosition!.latitude, _myPosition!.longitude,
      );
      setState(() {
        _eta = LocationService.getETA(distance, speed);
      });
    }

    // Move camera to driver location
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  void _updateMarker(String id, double lat, double lng,
      String title, double hue) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ));
    });
  }

  // Driver actions
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);

    await FirebaseService()
        .updateBookingStatus(widget.booking.bookingId, newStatus);

    // Notify rider of status change
    await FirebaseService().sendNotification(
      toUid: widget.isDriver
          ? widget.booking.riderUid
          : widget.booking.driverUid,
      title: _getNotificationTitle(newStatus),
      body: _getNotificationBody(newStatus),
      data: {
        'type': 'ride_status',
        'bookingId': widget.booking.bookingId,
        'status': newStatus,
      },
    );

    setState(() {
      _currentStatus = newStatus;
      _isUpdatingStatus = false;
    });

    // If ride ended — stop location sharing
    if (newStatus == RideStatus.ended) {
      await _locationService.stopSharingLocation();

      if (mounted) {
        if (widget.isDriver) {
          // Complete the ride in Firestore
          await FirebaseService().completeRide(
            widget.booking.bookingId,
            widget.booking.rideId,
          );
          // Driver goes back
          Navigator.pop(context);
        } else {
          // Rider goes to payment
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                rideId: widget.booking.rideId,
                driverName: widget.booking.driverName,
                from: widget.booking.from,
                to: widget.booking.to,
                amount: widget.booking.totalPrice,
                seats: widget.booking.seatsBooked,
                pricePerSeat: widget.booking.pricePerSeat,
              ),
            ),
          );
        }
      }
    }
  }

  String _getNotificationTitle(String status) {
    switch (status) {
      case RideStatus.enRoute:
        return 'Driver is on the way! 🚗';
      case RideStatus.started:
        return 'Ride Started! 🟢';
      case RideStatus.ended:
        return 'Ride Completed! ✅';
      default:
        return 'Ride Update';
    }
  }

  String _getNotificationBody(String status) {
    switch (status) {
      case RideStatus.enRoute:
        return '${widget.booking.driverName} is heading to the pickup point!';
      case RideStatus.started:
        return 'Your ride from ${widget.booking.from} has started. Enjoy!';
      case RideStatus.ended:
        return 'You have arrived at ${widget.booking.to}. Please rate your ride!';
      default:
        return 'Your ride status has been updated.';
    }
  }

  void _sendSOS() async {
    final settings = await FirebaseService().getSafetySettings(FirebaseAuth.instance.currentUser?.uid ?? '');
    final isHindi = settings?['isHindi'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded,
                color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            Text(isHindi ? 'आपातकालीन SOS!' : 'Emergency SOS!'),
          ],
        ),
        content: Text(isHindi 
            ? 'क्या आप सुनिश्चित हैं कि आप अपने संपर्कों को आपातकालीन अलर्ट भेजना चाहते हैं?' 
            : 'Send emergency alert with your live location to your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (_myPosition != null) {
                // 1. Trigger Firestore SOS logic
                await FirebaseService().triggerSOS(
                  rideId: widget.booking.rideId,
                  lat: _myPosition!.latitude,
                  lng: _myPosition!.longitude,
                );

                // 2. Local Actions (Calling/Messaging)
                if (settings != null) {
                  // Auto-call emergency services
                  if (settings['sosAutoCall'] == true) {
                    final Uri telUri = Uri(scheme: 'tel', path: '112');
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  }

                  // Auto-message contacts
                  if (settings['sosAutoMessage'] == true) {
                    final contacts = settings['emergencyContacts'] as List<dynamic>? ?? [];
                    for (var contact in contacts) {
                      final phone = contact['phone'];
                      if (phone != null) {
                        final String message = isHindi 
                            ? 'आपातकालीन! मुझे मदद की ज़रूरत है। मेरी लाइव लोकेशन: https://www.google.com/maps/search/?api=1&query=${_myPosition!.latitude},${_myPosition!.longitude}'
                            : 'EMERGENCY! I need help. My live location: https://www.google.com/maps/search/?api=1&query=${_myPosition!.latitude},${_myPosition!.longitude}';
                        
                        final Uri smsUri = Uri(
                          scheme: 'sms',
                          path: phone,
                          queryParameters: {'body': message},
                        );
                        if (await canLaunchUrl(smsUri)) {
                          await launchUrl(smsUri);
                        }
                      }
                    }
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindi ? '🆘 SOS अलर्ट भेज दिया गया है!' : '🆘 SOS Alert Sent!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(isHindi ? 'SOS भेजें' : 'Send SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: _db
                .collection('rides')
                .doc(widget.booking.rideId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasData && snap.data!.exists) {
                final rideData = snap.data!.data() as Map<String, dynamic>?;
                final loc = rideData?['driverLocation'] as Map<String, dynamic>?;
                if (loc != null) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    _onDriverLocationUpdated(loc);
                  });
                }
              }

              return GoogleMap(
                onMapCreated: (c) {
                  _mapController = c;
                  if (_myPosition != null) {
                    c.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(_myPosition!.latitude,
                              _myPosition!.longitude),
                          zoom: 15,
                        ),
                      ),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _myPosition != null
                      ? LatLng(_myPosition!.latitude,
                      _myPosition!.longitude)
                      : _defaultLocation,
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              );
            },
          ),

          // ── Top AppBar ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    // Back
                    _mapButton(Icons.arrow_back_rounded, () {
                      Navigator.pop(context);
                    }),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _statusColor(_currentStatus),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        RideStatus.getLabel(_currentStatus),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // SOS
                    _mapButton(Icons.sos_rounded, _sendSOS,
                        color: AppColors.error),
                  ],
                ),
              ),
            ),
          ),

          // ── ETA for rider ──────────────────────────
          if (!widget.isDriver && _eta.isNotEmpty)
            Positioned(
              top: 100.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_rounded,
                        color: AppColors.primary, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      _eta,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_driverSpeed > 0) ...[
                      SizedBox(width: 12.w),
                      Text(
                        '${_driverSpeed.toStringAsFixed(0)} km/h',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── Zoom Controls ──────────────────────────
          Positioned(
            right: 16.w,
            bottom: 280.h,
            child: Column(
              children: [
                _mapButton(Icons.sos_rounded, () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final uri = Uri(scheme: 'tel', path: '112');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    messenger.showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
                  }
                }, color: AppColors.error),
                SizedBox(height: 8.h),
                _mapButton(Icons.add, () {
                  _mapController?.animateCamera(
                      CameraUpdate.zoomIn());
                }),
                SizedBox(height: 8.h),
                _mapButton(Icons.remove, () {
                  _mapController?.animateCamera(
                      CameraUpdate.zoomOut());
                }),
                SizedBox(height: 8.h),
                _mapButton(Icons.my_location_rounded, () {
                  if (_myPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(LatLng(
                          _myPosition!.latitude,
                          _myPosition!.longitude)),
                    );
                  }
                }),
              ],
            ),
          ),

          // ── Bottom Control Panel ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 32.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28.r),
                  topRight: Radius.circular(28.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40.w, height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Person Info Card ────────────────────
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50.w, height: 50.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                              ),
                              child: Icon(
                                widget.isDriver ? Icons.person_rounded : Icons.directions_car_rounded,
                                color: AppColors.primary, size: 26.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.isDriver ? widget.booking.riderName : widget.booking.driverName,
                                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      ),
                                      SizedBox(width: 6.w),
                                      if (!widget.isDriver && widget.booking.driverRating > 0) ...[
                                        Icon(Icons.star_rounded, color: Colors.amber, size: 14.sp),
                                        Text(
                                          widget.booking.driverRating.toStringAsFixed(1),
                                          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    widget.isDriver ? '${widget.booking.seatsBooked} seat${widget.booking.seatsBooked > 1 ? "s" : ""} booked' : widget.booking.vehicle,
                                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                                  ),
                                  if (!widget.isDriver && widget.booking.driverPhone.isNotEmpty)
                                    Text(
                                      widget.booking.driverPhone,
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    ),
                                  if (widget.isDriver && widget.booking.riderPhone.isNotEmpty)
                                    Text(
                                      widget.booking.riderPhone,
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                            // Quick action buttons
                            Column(
                              children: [
                                _actionButton(
                                  icon: Icons.call_rounded,
                                  color: AppColors.success,
                                  onTap: () async {
                                    final phone = widget.isDriver ? widget.booking.riderPhone : widget.booking.driverPhone;
                                    if (phone.isNotEmpty) {
                                      final uri = Uri(scheme: 'tel', path: phone);
                                      if (await canLaunchUrl(uri)) launchUrl(uri);
                                    }
                                  },
                                ),
                                SizedBox(height: 8.h),
                                _actionButton(
                                  icon: Icons.chat_bubble_rounded,
                                  color: AppColors.primary,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => RideSharingScreen(booking: widget.booking, isDriver: widget.isDriver),
                                  )),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Route summary
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                  Container(width: 1.5, height: 18.h, color: AppColors.border),
                                  Icon(Icons.location_on_rounded, color: AppColors.error, size: 12.sp),
                                ],
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.booking.from, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    SizedBox(height: 10.h),
                                    Text(widget.booking.to, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${widget.booking.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  Text('${widget.booking.seatsBooked} seat${widget.booking.seatsBooked > 1 ? "s" : ""}', style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // ── Driver Action Buttons ──────────────
                  if (widget.isDriver) ...[
                    if (_currentStatus == RideStatus.accepted || _currentStatus == RideStatus.confirmed)
                      _actionBar(Icons.directions_car_rounded, "I'm Heading to Pickup Point", AppColors.secondary, () => _updateStatus(RideStatus.enRoute)),

                    if (_currentStatus == RideStatus.enRoute)
                      _actionBar(Icons.play_arrow_rounded, 'Start Ride', AppColors.success, _showOtpDialog),

                    if (_currentStatus == RideStatus.started)
                      _actionBar(Icons.stop_rounded, 'End Ride', AppColors.error, _showEndRideConfirmation),
                      
                    if (widget.booking.paymentMethod == 'Cash' && widget.booking.paymentStatus == 'unpaid' && (_currentStatus == RideStatus.started || _currentStatus == RideStatus.ended))
                      _actionBar(Icons.payments_rounded, 'Mark as Paid (Cash)', AppColors.primary, () async {
                         final messenger = ScaffoldMessenger.of(context);
                         await FirebaseService().markBookingPaid(widget.booking.bookingId);
                         messenger.showSnackBar(const SnackBar(content: Text('Payment marked as paid!'), backgroundColor: AppColors.success));
                      }),
                  ],

                  // ── Rider Status Display ───────────────
                  if (!widget.isDriver) ...[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: _statusColor(_currentStatus).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _statusColor(_currentStatus).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_statusIcon(_currentStatus), color: _statusColor(_currentStatus), size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                RideStatus.getLabel(_currentStatus),
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: _statusColor(_currentStatus)),
                              ),
                            ],
                          ),
                          if (_currentStatus == RideStatus.enRoute || _currentStatus == RideStatus.confirmed || _currentStatus == RideStatus.accepted) ...[
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                children: [
                                  Text('Your Ride OTP', style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  Text(widget.booking.otp, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.textPrimary)),
                                  Text('Share this with the driver to start the ride', style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w, height: 38.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
    );
  }

  Widget _actionBar(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton.icon(
          onPressed: _isUpdatingStatus ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          icon: Icon(icon, color: Colors.white, size: 18.sp),
          label: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp)),
        ),
      ),
    );
  }

  void _showOtpDialog() {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Enter Passenger OTP'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: '4-digit OTP'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (otpController.text == widget.booking.otp) {
                Navigator.pop(context);
                _updateStatus(RideStatus.started);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP!'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Verify & Start'),
          ),
        ],
      ),
    );
  }

  void _showEndRideConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: const Text('End Ride?'),
        content: Text(
          'Are you sure you want to end the ride to ${widget.booking.to}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(RideStatus.ended);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Yes, End Ride'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case RideStatus.accepted:
      case RideStatus.confirmed:
        return AppColors.primary;
      case RideStatus.enRoute:
        return AppColors.secondary;
      case RideStatus.started:
        return AppColors.success;
      case RideStatus.ended:
        return AppColors.textSecondary;
      default:
        return AppColors.textHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case RideStatus.accepted:
      case RideStatus.confirmed:
        return Icons.check_circle_rounded;
      case RideStatus.enRoute:
        return Icons.directions_car_rounded;
      case RideStatus.started:
        return Icons.play_circle_rounded;
      case RideStatus.ended:
        return Icons.flag_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _mapButton(IconData icon, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            color: color ?? AppColors.primary, size: 20.sp),
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopSharingLocation();
    _mapController?.dispose();
    super.dispose();
  }
}