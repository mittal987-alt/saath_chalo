import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';
import '../rating/rating_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String rideId;
  final bool isDriver;

  const LiveTrackingScreen({
    super.key,
    required this.rideId,
    this.isDriver = false,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Position? _currentPosition;
  bool _isSharing = false;
  String _rideStatus = 'Waiting';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToRideUpdates();
  }

  // Get current location once
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() => _currentPosition = position);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );

    _updateMarker('me', position.latitude, position.longitude,
        widget.isDriver ? 'You (Driver)' : 'You (Rider)',
        widget.isDriver ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueGreen);
  }

  // Start sharing live location
  void _startSharing() {
    setState(() => _isSharing = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() => _currentPosition = position);

      // Update marker on map
      _updateMarker('me', position.latitude, position.longitude,
          widget.isDriver ? 'Driver (You)' : 'Rider (You)',
          widget.isDriver
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueGreen);

      // Move camera
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude)),
      );

      // Save to Firestore
      _db
          .collection('rides')
          .doc(widget.rideId)
          .collection('locations')
          .doc(_uid)
          .set({
        'uid': _uid,
        'lat': position.latitude,
        'lng': position.longitude,
        'isDriver': widget.isDriver,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Stop sharing location
  void _stopSharing() {
    _positionStream?.cancel();
    setState(() => _isSharing = false);

    // Remove from Firestore
    _db
        .collection('rides')
        .doc(widget.rideId)
        .collection('locations')
        .doc(_uid)
        .delete();
  }

  // Listen to other people's location in same ride
  void _listenToRideUpdates() {
    _db
        .collection('rides')
        .doc(widget.rideId)
        .collection('locations')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['uid'] != _uid) {
          _updateMarker(
            data['uid'],
            data['lat'],
            data['lng'],
            data['isDriver'] ? 'Driver' : 'Rider',
            data['isDriver']
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueOrange,
          );
        }
      }
    });
  }

  void _updateMarker(String id, double lat, double lng, String title,
      double hue) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    });
  }

  // SOS Alert
  void _sendSOS() async {
    final settings = await FirebaseService().getSafetySettings(_uid);
    final isHindi = settings?['isHindi'] ?? false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 8.w),
            Text(isHindi ? 'आपातकालीन SOS!' : 'Emergency SOS!'),
          ],
        ),
        content: Text(isHindi 
            ? 'क्या आप सुनिश्चित हैं कि आप अपने संपर्कों को आपातकालीन अलर्ट भेजना चाहते हैं?' 
            : 'Are you sure you want to send an emergency alert to your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (_currentPosition != null) {
                // 1. Trigger Firestore SOS logic
                await FirebaseService().triggerSOS(
                  rideId: widget.rideId,
                  lat: _currentPosition!.latitude,
                  lng: _currentPosition!.longitude,
                );

                // 2. Local Actions (Calling/Messaging)
                if (settings != null) {
                  // Auto-call emergency services if enabled
                  if (settings['sosAutoCall'] == true) {
                    final Uri telUri = Uri(scheme: 'tel', path: '112');
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  }

                  // Auto-message contacts if enabled
                  if (settings['sosAutoMessage'] == true) {
                    final contacts = settings['emergencyContacts'] as List<dynamic>? ?? [];
                    for (var contact in contacts) {
                      final phone = contact['phone'];
                      if (phone != null) {
                        final String message = isHindi 
                            ? 'आपातकालीन! मुझे मदद की ज़रूरत है। मेरी लाइव लोकेशन: https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}'
                            : 'EMERGENCY! I need help. My live location: https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
                        
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
                      content: Text(isHindi ? '🆘 SOS अलर्ट आपके संपर्कों को भेज दिया गया है!' : '🆘 SOS Alert Sent to your contacts!'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isHindi ? 'SOS भेजें' : 'Send SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Drive Mode 🚗' : 'Track Ride 📍'),
        backgroundColor:
        widget.isDriver ? AppColors.secondary : AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // SOS Button
          IconButton(
            onPressed: _sendSOS,
            icon: const Icon(Icons.sos_rounded, color: Colors.red),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 15,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Status Bar
          Positioned(
            top: 16.h,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: _isSharing
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isSharing
                            ? 'Live Sharing ON'
                            : 'Live Sharing OFF',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _isSharing
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _rideStatus,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Card
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
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Ride Info
                  Row(
                    children: [
                      _buildInfoChip(
                          Icons.directions_car_rounded,
                          widget.isDriver ? 'Driver' : 'Rider',
                          widget.isDriver
                              ? AppColors.secondary
                              : AppColors.primary),
                      SizedBox(width: 12.w),
                      _buildInfoChip(
                          Icons.shield_rounded, 'Safe Ride', AppColors.success),
                      SizedBox(width: 12.w),
                      _buildInfoChip(Icons.people_rounded, '2 People',
                          AppColors.info),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Location Info
                  if (_currentPosition != null)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 16.h),

                  // Share / Stop Button
                  ElevatedButton.icon(
                    onPressed: _isSharing ? _stopSharing : _startSharing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSharing
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    icon: Icon(
                      _isSharing
                          ? Icons.location_off_rounded
                          : Icons.location_on_rounded,
                    ),
                    label: Text(
                      _isSharing
                          ? 'Stop Sharing Location'
                          : 'Start Sharing Location',
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // End Ride Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      _stopSharing();
                      
                      if (!widget.isDriver) {
                        // If rider, prompt for rating
                        final ride = await FirebaseService().getRide(widget.rideId);
                        if (ride != null && context.mounted) {
                          Navigator.pushReplacement(
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
                          return;
                        }
                      } else {
                        // If driver, mark ride as completed
                        await FirebaseService().updateRideStatus(widget.rideId, 'completed');
                      }
                      
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.h),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.stop_circle_rounded,
                        color: AppColors.error),
                    label: Text(widget.isDriver ? 'End & Complete Ride' : 'End Ride',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}