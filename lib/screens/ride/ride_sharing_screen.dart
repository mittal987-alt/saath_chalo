import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../services/navigation_service.dart';

class RideSharingScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isDriver;

  const RideSharingScreen({
    super.key,
    required this.booking,
    required this.isDriver,
  });

  @override
  State<RideSharingScreen> createState() => _RideSharingScreenState();
}

class _RideSharingScreenState extends State<RideSharingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  double _driverLat = 0;
  double _driverLng = 0;
  double _driverSpeed = 0;
  String _eta = 'Calculating...';
  Position? _myPosition;
  bool _mapReady = false;

  static const LatLng _defaultLoc = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _myPosition = pos);
    } catch (_) {}
  }

  void _onDriverLocationUpdate(Map<String, dynamic> loc) {
    final lat = (loc['lat'] ?? 0).toDouble();
    final lng = (loc['lng'] ?? 0).toDouble();
    final speed = (loc['speed'] ?? 0).toDouble();

    setState(() {
      _driverLat = lat;
      _driverLng = lng;
      _driverSpeed = speed;
    });

    // Update driver marker
    _updateMarker('driver', lat, lng,
        widget.isDriver ? 'You (Driver)' : 'Your Driver',
        BitmapDescriptor.hueBlue);

    // ETA calculation
    if (_myPosition != null && !widget.isDriver) {
      final dist = Geolocator.distanceBetween(
        lat, lng,
        _myPosition!.latitude,
        _myPosition!.longitude,
      );
      final kmh = speed < 5 ? 30.0 : speed;
      final mins = ((dist / 1000) / kmh * 60).round();
      setState(() {
        _eta = mins <= 0
            ? 'Arriving now!'
            : '$mins min${mins > 1 ? 's' : ''} away';
      });
    }

    if (_mapReady) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
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

  // ✅ Share ride details
  void _shareRideDetails() {
    final driverName = widget.booking.driverName.isEmpty
        ? 'Your Driver'
        : widget.booking.driverName;
    final riderName = widget.booking.riderName.isEmpty
        ? 'Rider'
        : widget.booking.riderName;

    final locationLink = _driverLat != 0
        ? 'https://www.google.com/maps?q=$_driverLat,$_driverLng'
        : 'Location not available yet';

    final message = '''
🚗 *SaathChalo Ride Tracking*

${widget.isDriver ? '👤 Rider' : '🚗 Driver'}: ${widget.isDriver ? riderName : driverName}
📍 From: ${widget.booking.from}
🏁 To: ${widget.booking.to}
💺 Seats: ${widget.booking.seatsBooked}
💰 Fare: ₹${widget.booking.totalPrice.toStringAsFixed(0)}

${widget.isDriver ? '' : '📞 Driver Phone: ${widget.booking.riderPhone.isEmpty ? 'Not available' : widget.booking.riderPhone}'}
🗺️ Live Location: $locationLink
⏱️ ETA: $_eta

Powered by SaathChalo App 🇮🇳
''';

    Share.share(message, subject: 'SaathChalo Ride Tracking');
  }

  // ✅ Navigate to pickup/destination
  Future<void> _startNavigation() async {
    if (widget.isDriver) {
      // Driver navigates to rider's last known location
      if (_myPosition != null) {
        await NavigationService.navigateTo(
          destLat: _myPosition!.latitude,
          destLng: _myPosition!.longitude,
          label: 'Pickup Point',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rider location not available yet!')),
        );
      }
    } else {
      // Rider navigates to destination
      await NavigationService.navigateTo(
        destLat: _driverLat != 0 ? _driverLat : _defaultLoc.latitude,
        destLng: _driverLng != 0 ? _driverLng : _defaultLoc.longitude,
        label: widget.booking.to,
      );
    }
  }

  void _callOtherPerson() {
    final phone = widget.isDriver
        ? widget.booking.riderPhone
        : widget.booking.riderPhone;
    if (phone.isNotEmpty) {
      NavigationService.callPhone(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Phone number not available!')),
      );
    }
  }

  void _whatsAppOtherPerson() {
    final phone = widget.isDriver
        ? widget.booking.riderPhone
        : widget.booking.riderPhone;
    if (phone.isNotEmpty) {
      NavigationService.openWhatsApp(
        phone,
        message:
        'Hi! I am your ${widget.isDriver ? 'driver' : 'rider'} for the SaathChalo ride from ${widget.booking.from} to ${widget.booking.to}.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.booking.rideId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.exists) {
            final data = snap.data!.data() as Map<String, dynamic>?;
            final loc = data?['driverLocation'] as Map<String, dynamic>?;
            if (loc != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onDriverLocationUpdate(loc);
              });
            }
          }

          return Stack(
            children: [
              // ── Map ──────────────────────────────────
              GoogleMap(
                onMapCreated: (c) {
                  _mapController = c;
                  _mapReady = true;
                  if (_myPosition != null) {
                    c.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                            _myPosition!.latitude,
                            _myPosition!.longitude,
                          ),
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
                      : _defaultLoc,
                  zoom: 14,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // ── Top AppBar ────────────────────────────
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
                        _iconBtn(Icons.arrow_back_rounded,
                                () => Navigator.pop(context)),
                        const Spacer(),
                        // ETA chip
                        if (!widget.isDriver && _eta.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                              BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_rounded,
                                    color: AppColors.white,
                                    size: 14.sp),
                                SizedBox(width: 6.w),
                                Text(
                                  _eta,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        _iconBtn(
                            Icons.share_rounded, _shareRideDetails,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Speed indicator (driver only) ────────
              if (widget.isDriver && _driverSpeed > 0)
                Positioned(
                  top: 100.h,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _driverSpeed.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text('km/h',
                            style: TextStyle(
                                fontSize: 9.sp,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),

              // ── Zoom controls ─────────────────────────
              Positioned(
                right: 16.w,
                bottom: 300.h,
                child: Column(
                  children: [
                    _iconBtn(Icons.add, () {
                      _mapController
                          ?.animateCamera(CameraUpdate.zoomIn());
                    }),
                    SizedBox(height: 8.h),
                    _iconBtn(Icons.remove, () {
                      _mapController
                          ?.animateCamera(CameraUpdate.zoomOut());
                    }),
                    SizedBox(height: 8.h),
                    _iconBtn(Icons.my_location_rounded, () {
                      if (_myPosition != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(LatLng(
                            _myPosition!.latitude,
                            _myPosition!.longitude,
                          )),
                        );
                      }
                    }),
                  ],
                ),
              ),

              // ── Bottom Panel ──────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                            BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── Person Info Row ───────────────
                      _buildPersonInfo(),

                      SizedBox(height: 16.h),

                      // ── Ride Info ─────────────────────
                      _buildRideInfo(),

                      SizedBox(height: 16.h),

                      // ── Action Buttons ────────────────
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonInfo() {
    final name = widget.isDriver
        ? (widget.booking.riderName.isEmpty
        ? 'Rider'
        : widget.booking.riderName)
        : (widget.booking.driverName.isEmpty
        ? 'Driver'
        : widget.booking.driverName);

    final phone = widget.isDriver
        ? widget.booking.riderPhone
        : widget.booking.riderPhone;

    return Row(
      children: [
        CircleAvatar(
          radius: 26.r,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            widget.isDriver
                ? Icons.person_rounded
                : Icons.directions_car_rounded,
            color: AppColors.primary,
            size: 28.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (phone.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 12.sp,
                        color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      phone,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // ✅ Call button
        GestureDetector(
          onTap: _callOtherPerson,
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.call_rounded,
                color: AppColors.success, size: 22.sp),
          ),
        ),
        SizedBox(width: 8.w),
        // ✅ WhatsApp button
        GestureDetector(
          onTap: _whatsAppOtherPerson,
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_rounded,
                color: const Color(0xFF25D366), size: 22.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildRideInfo() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle,
                  color: AppColors.primary, size: 10.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  widget.booking.from,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Row(
              children: [
                Container(
                    width: 2,
                    height: 16.h,
                    color: AppColors.border),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.location_on,
                  color: AppColors.secondary, size: 14.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.booking.to,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(
                '₹${widget.booking.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ✅ Navigate Button
        ElevatedButton.icon(
          onPressed: _startNavigation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
          icon: const Icon(Icons.navigation_rounded),
          label: Text(
            widget.isDriver
                ? 'Navigate to Pickup Point 📍'
                : 'Navigate to Destination 🏁',
            style: TextStyle(
                fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
        ),

        SizedBox(height: 10.h),

        Row(
          children: [
            // ✅ Share button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareRideDetails,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 46.h),
                  side: const BorderSide(
                      color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12.r)),
                ),
                icon: Icon(Icons.share_rounded,
                    color: AppColors.primary, size: 18.sp),
                label: Text('Share',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.sp)),
              ),
            ),

            SizedBox(width: 10.w),

            // ✅ Copy link button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final locationLink = _driverLat != 0
                      ? 'https://www.google.com/maps?q=$_driverLat,$_driverLng'
                      : 'Location updating...';
                  Clipboard.setData(
                      ClipboardData(text: locationLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location link copied!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 46.h),
                  side: const BorderSide(
                      color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12.r)),
                ),
                icon: Icon(Icons.copy_rounded,
                    color: AppColors.secondary, size: 18.sp),
                label: Text('Copy Link',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13.sp)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
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
              color: Colors.black.withOpacity(0.15),
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
    _mapController?.dispose();
    super.dispose();
  }
}