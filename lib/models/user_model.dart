import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String profilePic;
  final double rating;
  final int totalRides;
  final bool isVerified;
  final bool isBlocked;
  final String fcmToken;
  final double totalMoneySaved;
  final double totalCo2Saved;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.profilePic = '',
    this.rating = 5.0,
    this.totalRides = 0,
    this.isVerified = false,
    this.isBlocked = false,
    this.fcmToken = '',
    this.totalMoneySaved = 0.0,
    this.totalCo2Saved = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'profilePic': profilePic,
      'rating': rating,
      'totalRides': totalRides,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'fcmToken': fcmToken,
      'totalMoneySaved': totalMoneySaved,
      'totalCo2Saved': totalCo2Saved,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Server time
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      fcmToken: map['fcmToken'] ?? '',
      totalMoneySaved: (map['totalMoneySaved'] ?? 0.0).toDouble(),
      totalCo2Saved: (map['totalCo2Saved'] ?? 0.0).toDouble(),
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
  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? profilePic,
    double? rating,
    int? totalRides,
    bool? isVerified,
    bool? isBlocked,
    String? fcmToken,
    double? totalMoneySaved,
    double? totalCo2Saved,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      fcmToken: fcmToken ?? this.fcmToken,
      totalMoneySaved: totalMoneySaved ?? this.totalMoneySaved,
      totalCo2Saved: totalCo2Saved ?? this.totalCo2Saved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}