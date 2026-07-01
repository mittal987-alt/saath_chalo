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
  }

  void _uploadLocation(
      String rideId, Position position, bool isDriver) {
    // Write directly to ride doc — no extra collection needed
    // This fires Firestore listeners on rider's screen instantly
    _db.collection('rides').doc(rideId).update({
      'driverLocation': {
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'speed': (position.speed * 3.6).roundToDouble(), // m/s → km/h
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
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