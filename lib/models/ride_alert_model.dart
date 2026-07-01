import 'package:cloud_firestore/cloud_firestore.dart';

class RideAlertModel {
  final String id;
  final String uid;
  final String from;
  final String to;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime rideDate;
  final bool isActive;
  final DateTime createdAt;

  RideAlertModel({
    required this.id,
    required this.uid,
    required this.from,
    required this.to,
    this.fromLat = 0.0,
    this.fromLng = 0.0,
    this.toLat = 0.0,
    this.toLng = 0.0,
    required this.rideDate,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'from': from,
      'to': to,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'rideDate': rideDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Server time
    };
  }

  factory RideAlertModel.fromMap(Map<String, dynamic> map) {
    return RideAlertModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      fromLat: (map['fromLat'] ?? 0.0).toDouble(),
      fromLng: (map['fromLng'] ?? 0.0).toDouble(),
      toLat: (map['toLat'] ?? 0.0).toDouble(),
      toLng: (map['toLng'] ?? 0.0).toDouble(),
      rideDate: _parseDate(map['rideDate']),   // ✅ Safe parse
      isActive: map['isActive'] ?? true,
      createdAt: _parseDate(map['createdAt']), // ✅ Safe parse
    );
  }

  // ✅ Handles Timestamp, String & null safely
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
  RideAlertModel copyWith({
    String? id,
    String? uid,
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    DateTime? rideDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RideAlertModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      from: from ?? this.from,
      to: to ?? this.to,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      rideDate: rideDate ?? this.rideDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ✅ Display helpers
  bool get isToday {
    final now = DateTime.now();
    return rideDate.year == now.year &&
        rideDate.month == now.month &&
        rideDate.day == now.day;
  }

  bool get isExpired => rideDate.isBefore(DateTime.now());

  bool get canNotify => isActive && !isExpired;

  String get statusLabel =>
      !isActive ? 'Disabled' : (isExpired ? 'Expired' : 'Active');

  String get routeLabel => '$from → $to';

  String get rideDateFormatted =>
      '${rideDate.day}/${rideDate.month}/${rideDate.year}';
}