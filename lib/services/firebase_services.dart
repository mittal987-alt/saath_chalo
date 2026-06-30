import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/ride_alert_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User
  User? get currentUser => _auth.currentUser;

  // ==================
  // USER METHODS
  // ==================

  // Save user to Firestore
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user from Firestore
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ==================
  // RIDE METHODS
  // ==================

  // Offer a ride
  Future<void> offerRide(RideModel ride) async {
    await _db.collection('rides').doc(ride.rideId).set(ride.toMap());
    
    // Check for ride alerts that match this new ride
    _checkForMatchingAlerts(ride);
  }

  Future<void> _checkForMatchingAlerts(RideModel ride) async {
    // Basic matching logic: same from and to, and rideDate within 1 day
    final alerts = await _db
        .collection('ride_alerts')
        .where('from', isEqualTo: ride.from)
        .where('to', isEqualTo: ride.to)
        .get();

    for (var doc in alerts.docs) {
      final alert = RideAlertModel.fromMap(doc.data());
      
      // Don't notify the driver themselves
      if (alert.uid == ride.driverUid) continue;

      // Check date proximity (within 24 hours)
      final difference = ride.rideDate.difference(alert.rideDate).inHours.abs();
      if (difference <= 24) {
        await sendNotification(
          toUid: alert.uid,
          title: 'Ride Match Found! 🚗',
          body: '${ride.driverName} is driving from ${ride.from} to ${ride.to} on ${ride.rideTime}.',
          type: 'ride_alert_match',
          data: {'rideId': ride.rideId},
        );
      }
    }
  }

  // Create a ride alert
  Future<void> createRideAlert(RideAlertModel alert) async {
    await _db.collection('ride_alerts').doc(alert.id).set(alert.toMap());
  }

  // Get all active rides
  Stream<List<RideModel>> getActiveRides() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data()))
        .toList());
  }

  // Search rides by route
  Stream<List<RideModel>> searchRides(String from, String to) {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'active')
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data()))
        .toList());
  }

  // Get my offered rides
  Stream<List<RideModel>> getMyRides(String uid) {
    return _db
        .collection('rides')
        .where('driverUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data()))
        .toList());
  }
  // Get my notifications
  Stream<QuerySnapshot> getNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsRead(String uid) async {
    final batch = _db.batch();
    final query = await _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String docId) async {
    await _db.collection('notifications').doc(docId).delete();
  }

  // Send notification to a user
  Future<void> sendNotification({
    required String toUid,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    // Save notification to Firestore
    await _db.collection('notifications').add({
      'toUid': toUid,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    await _db.collection('rides').doc(rideId).update({'status': status});
  }

  // Book a seat (decrement available seats)
  Future<void> bookSeat(String rideId) async {
    await _db.collection('rides').doc(rideId).update({
      'availableSeats': FieldValue.increment(-1),
    });
  }

  // Get single ride details
  Future<RideModel?> getRide(String rideId) async {
    final doc = await _db.collection('rides').doc(rideId).get();
    if (doc.exists) {
      return RideModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Delete ride
  Future<void> deleteRide(String rideId) async {
    await _db.collection('rides').doc(rideId).delete();
  }

  // ==================
  // PAYMENT METHODS
  // ==================

  // Get my payment history
  Stream<QuerySnapshot> getPaymentHistory(String uid) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ==================
  // SAFETY & SETTINGS
  // ==================

  // Get safety settings
  Future<Map<String, dynamic>?> getSafetySettings(String uid) async {
    final doc = await _db.collection('users').doc(uid).collection('settings').doc('safety').get();
    return doc.data();
  }

  // Update safety settings
  Future<void> updateSafetySettings(String uid, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(uid).collection('settings').doc('safety').set(
      settings,
      SetOptions(merge: true),
    );
  }
}