import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/ride_alert_model.dart';
import '../models/booking_model.dart';
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User
  User? get currentUser => _auth.currentUser;

  // ==================
  // USER METHODS
  // ==================


// ... inside FirebaseService class, add these methods:

// ==================
// BOOKING METHODS
// ==================

// Create a booking request (rider requests a ride - status: pending)
  Future<String> createBookingRequest(BookingModel booking) async {
    // ✅ Use set with merge to avoid overwriting
    await _db
        .collection('bookings')
        .doc(booking.bookingId)
        .set(booking.toMap());

    print('DEBUG: Booking saved with ID ${booking.bookingId}');
    print('DEBUG: riderUid = ${booking.riderUid}');

    // Notify driver
    await sendNotification(
      toUid: booking.driverUid,
      title: 'New Ride Request! 🚗',
      body: '${booking.riderName} wants ${booking.seatsBooked} seat(s)',
      data: {'type': 'ride_request', 'bookingId': booking.bookingId},
    );

    return booking.bookingId;
  }

// Get pending requests for a driver (for their offered rides)
  Stream<List<BookingModel>> getDriverRequests(String driverUid) {
    return _db
        .collection('bookings')
        .where('driverUid', isEqualTo: driverUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList());
  }

// Get my bookings (as a rider)
  Stream<List<BookingModel>> getMyBookings(String riderUid) {
    return _db
        .collection('bookings')
        .where('riderUid', isEqualTo: riderUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList());
  }

// ACCEPT booking — Transaction-safe seat decrement
// Returns true if successful, false if not enough seats left
  Future<Map<String, dynamic>> acceptBookingRequest(
      String bookingId, String rideId, int seatsRequested) async {
    try {
      final result = await _db.runTransaction<Map<String, dynamic>>(
            (transaction) async {
          final rideRef = _db.collection('rides').doc(rideId);
          final bookingRef = _db.collection('bookings').doc(bookingId);

          final rideSnap = await transaction.get(rideRef);
          final bookingSnap = await transaction.get(bookingRef);

          if (!rideSnap.exists) {
            return {'success': false, 'message': 'Ride not found!'};
          }

          final int currentSeats =
              rideSnap.data()!['availableSeats'] ?? 0;

          if (currentSeats < seatsRequested) {
            return {
              'success': false,
              'message': 'Only $currentSeats seat(s) left!'
            };
          }

          final int newSeats = currentSeats - seatsRequested;

          // ✅ Update ride seats
          transaction.update(rideRef, {
            'availableSeats': newSeats,
            if (newSeats == 0) 'status': 'full',
          });

          // ✅ Update booking to confirmed
          transaction.update(bookingRef, {
            'status': 'confirmed', // ✅ Must be 'confirmed'
          });

          return {
            'success': true,
            'message': 'Booking accepted!',
            'remainingSeats': newSeats,
          };
        },
      );

      if (result['success'] == true) {
        final bookingDoc =
        await _db.collection('bookings').doc(bookingId).get();
        if (bookingDoc.exists) {
          final booking =
          BookingModel.fromMap(bookingDoc.data()!);
          await sendNotification(
            toUid: booking.riderUid,
            title: 'Ride Accepted! ✅',
            body: '${booking.driverName} accepted your request!',
            data: {
              'type': 'ride_accepted',
              'bookingId': bookingId
            },
          );
        }
      }

      return result;
    } catch (e) {
      print('DEBUG: Accept error = $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  // REJECT booking
  Future<void> rejectBookingRequest(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'rejected'});

    final bookingDoc =
    await _db.collection('bookings').doc(bookingId).get();
    if (bookingDoc.exists) {
      final booking = BookingModel.fromMap(bookingDoc.data()!);
      await sendNotification(
        toUid: booking.riderUid,
        title: 'Ride Request Declined',
        body:
        '${booking.driverName} could not accept your request for ${booking.from} → ${booking.to}',
        data: {'type': 'ride_rejected', 'bookingId': bookingId},
      );
    }
  }

// Mark booking as paid
  Future<void> markBookingPaid(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'paymentStatus': 'paid'});
  }

// Get a single ride's live data (for real seat count)
  Stream<DocumentSnapshot> getRideStream(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots();
  }

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
  // Update booking/ride status
  Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

// Get active booking for a rider (their current ride)
  Stream<QuerySnapshot> getRiderActiveBooking(String riderUid) {
    return _db
        .collection('bookings')
        .where('riderUid', isEqualTo: riderUid)
        .where('status', whereIn: [
      'confirmed',
      'en_route',
      'started',
    ])
        .limit(1)
        .snapshots();
  }

// Get active booking for a driver (their current ride)
  Stream<QuerySnapshot> getDriverActiveBookings(String driverUid) {
    return _db
        .collection('bookings')
        .where('driverUid', isEqualTo: driverUid)
        .where('status', whereIn: [
      'confirmed',
      'en_route',
      'started',
    ])
        .snapshots();
  }

// Complete ride — update booking + ride status
  Future<void> completeRide(
      String bookingId, String rideId) async {
    final batch = _db.batch();

    batch.update(
      _db.collection('bookings').doc(bookingId),
      {'status': 'ended'},
    );

    batch.update(
      _db.collection('rides').doc(rideId),
      {'status': 'completed'},
    );

    await batch.commit();
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

  // Get bookings for a specific ride
  Stream<List<BookingModel>> getBookingsForRide(String rideId, {List<String>? statuses}) {
    var query = _db.collection('bookings').where('rideId', isEqualTo: rideId);
    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Book a seat (decrement available seats) - Transaction-safe
  Future<bool> bookSeat(String rideId, int seatsToBook) async {
    try {
      return await _db.runTransaction((transaction) async {
        final rideRef = _db.collection('rides').doc(rideId);
        final rideSnap = await transaction.get(rideRef);

        if (!rideSnap.exists) return false;

        final int currentSeats = rideSnap.data()?['availableSeats'] ?? 0;
        if (currentSeats < seatsToBook) return false;

        transaction.update(rideRef, {
          'availableSeats': currentSeats - seatsToBook,
          if (currentSeats - seatsToBook == 0) 'status': 'full',
        });
        return true;
      });
    } catch (e) {
      return false;
    }
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

  // Trigger Emergency SOS
  Future<void> triggerSOS({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final user = await getUser(uid);
    final settings = await getSafetySettings(uid);
    final contacts = settings?['emergencyContacts'] as List<dynamic>? ?? [];

    final sosId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Save SOS record to Firestore
    await _db.collection('sos_alerts').doc(sosId).set({
      'sosId': sosId,
      'uid': uid,
      'userName': user?.name ?? 'Unknown',
      'userPhone': user?.phone ?? '',
      'rideId': rideId,
      'location': GeoPoint(lat, lng),
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
      'emergencyContacts': contacts,
    });

    // 2. Notify Authorities (Mocked as a global notification)
    await sendNotification(
      toUid: 'admin_panel', // Mock admin ID
      title: '🆘 EMERGENCY SOS: ${user?.name}',
      body: 'User is in danger at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}. Ride ID: $rideId',
      type: 'sos_alert',
      data: {'sosId': sosId, 'lat': lat, 'lng': lng},
    );

    // 3. Try to notify contacts if they are registered users
    for (var contact in contacts) {
      final phone = contact['phone']?.toString();
      if (phone != null) {
        // Search for user with this phone number
        final contactUserQuery = await _db.collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (contactUserQuery.docs.isNotEmpty) {
          final contactUid = contactUserQuery.docs.first.id;
          await sendNotification(
            toUid: contactUid,
            title: '🆘 EMERGENCY: ${user?.name} needs help!',
            body: '${user?.name} triggered an SOS during their ride. View live location.',
            type: 'sos_contact_alert',
            data: {'sosId': sosId, 'victimUid': uid, 'lat': lat, 'lng': lng},
          );
        }
      }
    }
  }

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