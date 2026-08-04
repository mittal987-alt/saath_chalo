import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/ride_alert_model.dart';
import '../models/booking_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Current User
  User? get currentUser => _auth.currentUser;

  // ==================
  // USER METHODS
  // ==================

  Future<String?> uploadProfilePic(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_pics').child('$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ==================
  // RIDE METHODS
  // ==================

  Future<void> offerRide(RideModel ride) async {
    await _db.collection('rides').doc(ride.rideId).set(ride.toMap());
    _checkForMatchingAlerts(ride);
  }

  Future<void> _checkForMatchingAlerts(RideModel ride) async {
    try {
      final alerts = await _db
          .collection('ride_alerts')
          .where('from', isEqualTo: ride.from)
          .where('to', isEqualTo: ride.to)
          .get();

      for (var doc in alerts.docs) {
        final alert = RideAlertModel.fromMap(doc.data());
        if (alert.uid == ride.driverUid) continue;
        final difference =
        ride.rideDate.difference(alert.rideDate).inHours.abs();
        if (difference <= 24) {
          await sendNotification(
            toUid: alert.uid,
            title: 'Ride Match Found! 🚗',
            body:
            '${ride.driverName} is driving from ${ride.from} to ${ride.to} on ${ride.rideTime}.',
            type: 'ride_alert_match',
            data: {'rideId': ride.rideId},
          );
        }
      }
    } catch (e) {
      // Silently fail if no alerts collection yet
    }
  }

  Future<void> createRideAlert(RideAlertModel alert) async {
    await _db.collection('ride_alerts').doc(alert.id).set(alert.toMap());
  }

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

  Future<RideModel?> getRide(String rideId) async {
    final doc = await _db.collection('rides').doc(rideId).get();
    if (doc.exists) return RideModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> deleteRide(String rideId) async {
    await _db.collection('rides').doc(rideId).delete();
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    await _db.collection('rides').doc(rideId).update({'status': status});
  }

  Future<void> updateWalletBalance(String uid, double amountToAdd) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final currentBalance = (doc.data()?['walletBalance'] ?? 0.0).toDouble();
      await _db.collection('users').doc(uid).update({
        'walletBalance': currentBalance + amountToAdd,
      });
    }
  }

  // ==================
  // BOOKING METHODS
  // ==================

  Future<String> createBookingRequest(BookingModel booking) async {
    await _db
        .collection('bookings')
        .doc(booking.bookingId)
        .set(booking.toMap());

    await sendNotification(
      toUid: booking.driverUid,
      title: 'New Ride Request! 🚗',
      body:
      '${booking.riderName.isEmpty ? 'Someone' : booking.riderName} wants ${booking.seatsBooked} seat(s) for ${booking.from} → ${booking.to}',
      type: 'ride_request',
      data: {'bookingId': booking.bookingId},
    );

    return booking.bookingId;
  }

  // ✅ Single getBookingsForRide — handles both 'accepted' & 'confirmed'
  Stream<List<BookingModel>> getBookingsForRide(
      String rideId, {
        required List<String> statuses,
      }) {
    // ✅ Auto-include 'accepted' when 'confirmed' requested
    // so old & new bookings both show
    List<String> finalStatuses = List.from(statuses);
    if (finalStatuses.contains('confirmed') &&
        !finalStatuses.contains('accepted')) {
      finalStatuses.add('accepted');
    }
    if (finalStatuses.contains('accepted') &&
        !finalStatuses.contains('confirmed')) {
      finalStatuses.add('confirmed');
    }

    return _db
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
        .where('status', whereIn: finalStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList());
  }

  Stream<List<BookingModel>> getDriverRequests(String driverUid) {
    return _db
        .collection('bookings')
        .where('driverUid', isEqualTo: driverUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList());
  }

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

  // ✅ Transaction-safe accept — decrements seats atomically
  Future<Map<String, dynamic>> acceptBookingRequest(
      String bookingId, String rideId, int seatsRequested) async {
    try {
      final result =
      await _db.runTransaction<Map<String, dynamic>>((transaction) async {
        final rideRef = _db.collection('rides').doc(rideId);
        final bookingRef = _db.collection('bookings').doc(bookingId);

        final rideSnap = await transaction.get(rideRef);
        await transaction.get(bookingRef);

        if (!rideSnap.exists) {
          return {'success': false, 'message': 'Ride not found!'};
        }

        final int currentSeats = rideSnap.data()!['availableSeats'] ?? 0;

        if (currentSeats < seatsRequested) {
          return {
            'success': false,
            'message': 'Only $currentSeats seat(s) left!'
          };
        }

        final int newSeats = currentSeats - seatsRequested;

        transaction.update(rideRef, {
          'availableSeats': newSeats,
          if (newSeats == 0) 'status': 'full',
        });

        transaction.update(bookingRef, {
          'status': 'accepted',
        });

        return {
          'success': true,
          'message': 'Booking accepted!',
          'remainingSeats': newSeats,
        };
      });

      if (result['success'] == true) {
        final bookingDoc =
        await _db.collection('bookings').doc(bookingId).get();
        if (bookingDoc.exists) {
          final booking = BookingModel.fromMap(bookingDoc.data()!);
          await sendNotification(
            toUid: booking.riderUid,
            title: 'Ride Accepted! ✅',
            body:
            '${booking.driverName} accepted your request for ${booking.from} → ${booking.to}!',
            type: 'ride_accepted',
            data: {'bookingId': bookingId},
          );
        }
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

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
        title: 'Ride Request Declined ❌',
        body:
        '${booking.driverName} could not accept your request for ${booking.from} → ${booking.to}',
        type: 'ride_rejected',
        data: {'bookingId': bookingId},
      );
    }
  }

  Future<void> markBookingPaid(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'paymentStatus': 'paid'});
  }

  Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

  Future<void> cancelBooking({
    required String bookingId,
    required String rideId,
    required int seatsToReturn,
    required bool wasAccepted,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('bookings').doc(bookingId), {
      'status': 'cancelled',
    });

    if (wasAccepted) {
      batch.update(_db.collection('rides').doc(rideId), {
        'availableSeats': FieldValue.increment(seatsToReturn),
        'status': 'active',
      });
    }

    await batch.commit();

    final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
    if (bookingDoc.exists) {
      final booking = BookingModel.fromMap(bookingDoc.data()!);
      await sendNotification(
        toUid: booking.driverUid,
        title: 'Ride Booking Cancelled ❌',
        body: '${booking.riderName} cancelled their booking for ${booking.from} → ${booking.to}',
        type: 'ride_cancelled',
        data: {'rideId': rideId},
      );
    }
  }

  Future<void> completeRide(String bookingId, String rideId) async {
    final batch = _db.batch();
    batch.update(_db.collection('bookings').doc(bookingId),
        {'status': 'ended'});
    batch.update(
        _db.collection('rides').doc(rideId), {'status': 'completed'});
    await batch.commit();
  }

  Stream<DocumentSnapshot> getRideStream(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots();
  }

  Stream<QuerySnapshot> getRiderActiveBooking(String riderUid) {
    return _db
        .collection('bookings')
        .where('riderUid', isEqualTo: riderUid)
        .where('status', whereIn: [
      'accepted',
      'confirmed',
      'en_route',
      'started',
    ])
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverActiveBookings(String driverUid) {
    return _db
        .collection('bookings')
        .where('driverUid', isEqualTo: driverUid)
        .where('status', whereIn: [
      'accepted',
      'confirmed',
      'en_route',
      'started',
    ])
        .snapshots();
  }

  // ✅ Transaction-safe seat booking
  Future<bool> bookSeat(String rideId, int seatsToBook) async {
    try {
      return await _db.runTransaction((transaction) async {
        final rideRef = _db.collection('rides').doc(rideId);
        final rideSnap = await transaction.get(rideRef);
        if (!rideSnap.exists) return false;
        final int currentSeats =
            rideSnap.data()?['availableSeats'] ?? 0;
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

  // ==================
  // NOTIFICATION METHODS
  // ==================

  Future<void> sendNotification({
    required String toUid,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'toUid': toUid,
      'title': title,
      'body': body,
      'type': type ?? 'general',
      'data': data ?? {},
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationRead(String docId) async {
    await _db
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

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

  Future<void> deleteNotification(String docId) async {
    await _db.collection('notifications').doc(docId).delete();
  }

  // ==================
  // PAYMENT METHODS
  // ==================

  Stream<QuerySnapshot> getPaymentHistory(String uid) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ==================
  // SAFETY METHODS
  // ==================

  Future<void> triggerSOS({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final user = await getUser(uid);
    final settings = await getSafetySettings(uid);
    final contacts =
        settings?['emergencyContacts'] as List<dynamic>? ?? [];

    final sosId = DateTime.now().millisecondsSinceEpoch.toString();

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

    await sendNotification(
      toUid: 'admin_panel',
      title: '🆘 EMERGENCY SOS: ${user?.name}',
      body:
      'User is in danger at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}. Ride: $rideId',
      type: 'sos_alert',
      data: {'sosId': sosId, 'lat': lat, 'lng': lng},
    );

    for (var contact in contacts) {
      final phone = contact['phone']?.toString();
      if (phone != null) {
        final contactUserQuery = await _db
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (contactUserQuery.docs.isNotEmpty) {
          final contactUid = contactUserQuery.docs.first.id;
          await sendNotification(
            toUid: contactUid,
            title: '🆘 EMERGENCY: ${user?.name} needs help!',
            body:
            '${user?.name} triggered an SOS during their ride. View live location.',
            type: 'sos_contact_alert',
            data: {
              'sosId': sosId,
              'victimUid': uid,
              'lat': lat,
              'lng': lng
            },
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> getSafetySettings(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('safety')
        .get();
    return doc.data();
  }

  Future<void> updateSafetySettings(
      String uid, Map<String, dynamic> settings) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('safety')
        .set(settings, SetOptions(merge: true));
  }

  // ==================
  // REPORTING METHODS
  // ==================

  Future<void> submitReport(ReportModel report) async {
    await _db.collection('reports').doc(report.reportId).set(report.toMap());

    // Notify admin
    await sendNotification(
      toUid: 'admin_panel',
      title: 'New Report Submitted ⚠️',
      body: 'A new ${report.type} report has been filed by ${report.reporterName}.',
      type: 'admin_report',
      data: {'reportId': report.reportId},
    );
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String reporterId,
  }) async {
    await _db.collection('reports').doc(reportId).update({'status': status});

    await sendNotification(
      toUid: reporterId,
      title: 'Report Update 📋',
      body: 'Your report status has been updated to: $status.',
      type: 'report_update',
      data: {'reportId': reportId, 'status': status},
    );
  }

  // ==================
  // REVIEW METHODS
  // ==================

  Stream<List<ReviewModel>> getFlaggedReviews() {
    return _db
        .collection('reviews')
        .where('status', isEqualTo: 'flagged')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data()))
        .toList());
  }

  Future<void> updateReviewStatus(
    String reviewId,
    String status, {
    String? note,
    String? reviewerId,
  }) async {
    await _db.collection('reviews').doc(reviewId).update({
      'status': status,
      if (note != null) 'moderationNote': note,
    });

    if (reviewerId != null) {
      await sendNotification(
        toUid: reviewerId,
        title: status == 'approved' ? 'Review Approved ✅' : 'Review Rejected ❌',
        body: status == 'approved'
            ? 'Your review has been approved and is now public.'
            : 'Your review was rejected for violating our community guidelines.',
        type: 'review_moderation',
        data: {'reviewId': reviewId, 'status': status},
      );
    }
  }

  // ==================
  // PAYMENT METHODS
  // ==================

  Stream<QuerySnapshot> getPaymentHistory(String uid) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ==================
  // SAFETY SETTINGS
  // ==================

  Future<Map<String, dynamic>?> getSafetySettings(String uid) async {
    final doc = await _db.collection('users').doc(uid).collection('settings').doc('safety').get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> updateSafetySettings(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).collection('settings').doc('safety').set(data, SetOptions(merge: true));
  }
}