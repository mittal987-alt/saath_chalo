import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String rideId;
  final String riderUid;
  final String riderName;
  final String riderPhone;
  final String driverUid;
  final String driverName;
  final String driverPhone;
  final String vehicle;
  final double driverRating;
  final String from;
  final String to;
  final DateTime rideDate;
  final String rideTime;
  final int seatsBooked;
  final double totalPrice;
  final double pricePerSeat;
  final String status; // pending, confirmed, en_route, started, ended, cancelled
  final String paymentStatus; // unpaid, paid
  final String paymentMethod; // Razorpay, Cash
  final String otp;
  final DateTime createdAt;

  // Convenience getter so existing code using totalAmount still works
  double get totalAmount => totalPrice;

  BookingModel({
    required this.bookingId,
    required this.rideId,
    required this.riderUid,
    required this.riderName,
    required this.riderPhone,
    required this.driverUid,
    required this.driverName,
    this.driverPhone = '',
    this.vehicle = '',
    this.driverRating = 5.0,
    required this.from,
    required this.to,
    required this.rideDate,
    required this.rideTime,
    required this.seatsBooked,
    required this.totalPrice,
    required this.pricePerSeat,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'Cash',
    this.otp = '0000',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'rideId': rideId,
      'riderUid': riderUid,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'driverUid': driverUid,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicle': vehicle,
      'driverRating': driverRating,
      'from': from,
      'to': to,
      'rideDate': rideDate.toIso8601String(),
      'rideTime': rideTime,
      'seatsBooked': seatsBooked,
      'totalPrice': totalPrice,
      'pricePerSeat': pricePerSeat,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Always server time
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map['bookingId'] ?? '',
      rideId: map['rideId'] ?? '',
      riderUid: map['riderUid'] ?? '',
      riderName: map['riderName'] ?? '',
      riderPhone: map['riderPhone'] ?? '',
      driverUid: map['driverUid'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      vehicle: map['vehicle'] ?? '',
      driverRating: (map['driverRating'] ?? 5.0).toDouble(),
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      rideDate: _parseDate(map['rideDate']),       // ✅ Safe parse
      rideTime: map['rideTime'] ?? '',
      seatsBooked: map['seatsBooked'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      pricePerSeat: (map['pricePerSeat'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      otp: map['otp'] ?? '0000',
      createdAt: _parseDate(map['createdAt']),     // ✅ Safe parse
    );
  }

  // ✅ Handles Timestamp (Firestore), String (old data), null
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // ✅ Easy copy with changes
  BookingModel copyWith({
    String? bookingId,
    String? rideId,
    String? riderUid,
    String? riderName,
    String? riderPhone,
    String? driverUid,
    String? driverName,
    String? driverPhone,
    String? vehicle,
    double? driverRating,
    String? from,
    String? to,
    DateTime? rideDate,
    String? rideTime,
    int? seatsBooked,
    double? totalPrice,
    double? pricePerSeat,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? otp,
    DateTime? createdAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      rideId: rideId ?? this.rideId,
      riderUid: riderUid ?? this.riderUid,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicle: vehicle ?? this.vehicle,
      driverRating: driverRating ?? this.driverRating,
      from: from ?? this.from,
      to: to ?? this.to,
      rideDate: rideDate ?? this.rideDate,
      rideTime: rideTime ?? this.rideTime,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalPrice: totalPrice ?? this.totalPrice,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      otp: otp ?? this.otp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}