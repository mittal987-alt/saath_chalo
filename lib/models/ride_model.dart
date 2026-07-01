import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String rideId;
  final String driverUid;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String vehicle;
  final String from;
  final String to;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime rideDate;
  final String rideTime;
  final int availableSeats;
  final double pricePerSeat;
  final bool womenOnly;
  final String status;
  final DateTime createdAt;

  RideModel({
    required this.rideId,
    required this.driverUid,
    required this.driverName,
    required this.driverPhone,
    this.driverRating = 5.0,
    required this.vehicle,
    required this.from,
    required this.to,
    this.fromLat = 0.0,
    this.fromLng = 0.0,
    this.toLat = 0.0,
    this.toLng = 0.0,
    required this.rideDate,
    required this.rideTime,
    required this.availableSeats,
    required this.pricePerSeat,
    this.womenOnly = false,
    this.status = 'active',
    required this.createdAt,
  });

  // ✅ Save to Firestore using serverTimestamp
  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'driverUid': driverUid,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverRating': driverRating,
      'vehicle': vehicle,
      'from': from,
      'to': to,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'rideDate': rideDate.toIso8601String(),
      'rideTime': rideTime,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'womenOnly': womenOnly,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Always server time
    };
  }

  // ✅ Read from Firestore — handles Timestamp, String & null
  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      rideId: map['rideId'] ?? '',
      driverUid: map['driverUid'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      driverRating: (map['driverRating'] ?? 5.0).toDouble(),
      vehicle: map['vehicle'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      fromLat: (map['fromLat'] ?? 0.0).toDouble(),
      fromLng: (map['fromLng'] ?? 0.0).toDouble(),
      toLat: (map['toLat'] ?? 0.0).toDouble(),
      toLng: (map['toLng'] ?? 0.0).toDouble(),
      rideDate: _parseDate(map['rideDate']),
      rideTime: map['rideTime'] ?? '',
      availableSeats: map['availableSeats'] ?? 1,
      pricePerSeat: (map['pricePerSeat'] ?? 0.0).toDouble(),
      womenOnly: map['womenOnly'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: _parseDate(map['createdAt']),
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

  // ✅ Copy with updated fields
  RideModel copyWith({
    String? rideId,
    String? driverUid,
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? vehicle,
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    DateTime? rideDate,
    String? rideTime,
    int? availableSeats,
    double? pricePerSeat,
    bool? womenOnly,
    String? status,
    DateTime? createdAt,
  }) {
    return RideModel(
      rideId: rideId ?? this.rideId,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      vehicle: vehicle ?? this.vehicle,
      from: from ?? this.from,
      to: to ?? this.to,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      rideDate: rideDate ?? this.rideDate,
      rideTime: rideTime ?? this.rideTime,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      womenOnly: womenOnly ?? this.womenOnly,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}