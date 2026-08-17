import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Start sharing location for a ride
  Future<void> startSharingLocation(String rideId, bool isDriver) async {
    await stopSharingLocation(); // Stop any existing stream

    // Check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Update every 5 seconds OR every 10 meters — whichever comes first
    // This gives smooth tracking without battery drain
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position position) {
      _uploadLocation(rideId, position, isDriver);
    });

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _uploadLocation(rideId, currentPosition, isDriver);
    } catch (_) {}
  }

  Map<String, dynamic> buildLocationPayload(Position position, {required bool isDriver}) {
    final speedKmh = (position.speed * 3.6).roundToDouble();
    final locationData = {
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': position.heading,
      'speed': speedKmh < 0 ? 0.0 : speedKmh,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return {
      'driverLocation': locationData,
      'tracking': {
        'isActive': true,
        'isDriver': isDriver,
        'updatedBy': _uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'lastUpdatedBy': _uid,
    };
  }

  void _uploadLocation(String rideId, Position position, bool isDriver) {
    // Write directly to ride doc — no extra collection needed
    // This fires Firestore listeners on rider's screen instantly
    _db.collection('rides').doc(rideId).set(
      buildLocationPayload(position, isDriver: isDriver),
      SetOptions(merge: true),
    );
  }

  // Stop sharing
  Future<void> stopSharingLocation() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  // One-time current location fetch
  static Future<Position?> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate ETA string given distance in meters
  static String getETA(double distanceMeters, double speedKmh) {
    if (speedKmh < 1) speedKmh = 30; // assume 30kmh if stopped
    final double hours = (distanceMeters / 1000) / speedKmh;
    final int minutes = (hours * 60).round();
    if (minutes < 1) return 'Arriving now';
    if (minutes == 1) return '1 min away';
    return '$minutes mins away';
  }

  bool get isSharing => _positionStream != null;

  void dispose() {
    _positionStream?.cancel();
  }
}