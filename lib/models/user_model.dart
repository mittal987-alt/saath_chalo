import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String bio;
  final String profilePic;
  final double rating;
  final int totalRides;
  final bool isVerified;
  final bool isBlocked;
  final bool isDriverVerified;
  final String drivingLicenseNumber;
  final String rcNumber;
  final String insuranceDetails;
  final String drivingLicenseUrl;
  final String rcUrl;
  final String insuranceUrl;
  final String fcmToken;
  final double walletBalance;
  final double totalMoneySaved;
  final double totalCo2Saved;
  final bool musicAllowed;
  final bool petsAllowed;
  final bool smokingAllowed;
  final bool acPreferred;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.bio = '',
    this.profilePic = '',
    this.rating = 5.0,
    this.totalRides = 0,
    this.isVerified = false,
    this.isBlocked = false,
    this.isDriverVerified = false,
    this.drivingLicenseNumber = '',
    this.rcNumber = '',
    this.insuranceDetails = '',
    this.drivingLicenseUrl = '',
    this.rcUrl = '',
    this.insuranceUrl = '',
    this.fcmToken = '',
    this.walletBalance = 0.0,
    this.totalMoneySaved = 0.0,
    this.totalCo2Saved = 0.0,
    this.musicAllowed = true,
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.acPreferred = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'bio': bio,
      'profilePic': profilePic,
      'rating': rating,
      'totalRides': totalRides,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'isDriverVerified': isDriverVerified,
      'drivingLicenseNumber': drivingLicenseNumber,
      'rcNumber': rcNumber,
      'insuranceDetails': insuranceDetails,
      'drivingLicenseUrl': drivingLicenseUrl,
      'rcUrl': rcUrl,
      'insuranceUrl': insuranceUrl,
      'fcmToken': fcmToken,
      'walletBalance': walletBalance,
      'totalMoneySaved': totalMoneySaved,
      'totalCo2Saved': totalCo2Saved,
      'preferences': {
        'musicAllowed': musicAllowed,
        'petsAllowed': petsAllowed,
        'smokingAllowed': smokingAllowed,
        'acPreferred': acPreferred,
      },
      'createdAt': FieldValue.serverTimestamp(), // ✅ Server time
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final prefs = map['preferences'] as Map<String, dynamic>?;
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      profilePic: map['profilePic'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      isDriverVerified: map['isDriverVerified'] ?? false,
      drivingLicenseNumber: map['drivingLicenseNumber'] ?? '',
      rcNumber: map['rcNumber'] ?? '',
      insuranceDetails: map['insuranceDetails'] ?? '',
      drivingLicenseUrl: map['drivingLicenseUrl'] ?? '',
      rcUrl: map['rcUrl'] ?? '',
      insuranceUrl: map['insuranceUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      totalMoneySaved: (map['totalMoneySaved'] ?? 0.0).toDouble(),
      totalCo2Saved: (map['totalCo2Saved'] ?? 0.0).toDouble(),
      musicAllowed: prefs?['musicAllowed'] ?? true,
      petsAllowed: prefs?['petsAllowed'] ?? false,
      smokingAllowed: prefs?['smokingAllowed'] ?? false,
      acPreferred: prefs?['acPreferred'] ?? true,
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
    String? bio,
    String? profilePic,
    double? rating,
    int? totalRides,
    bool? isVerified,
    bool? isBlocked,
    bool? isDriverVerified,
    String? drivingLicenseNumber,
    String? rcNumber,
    String? insuranceDetails,
    String? drivingLicenseUrl,
    String? rcUrl,
    String? insuranceUrl,
    String? fcmToken,
    double? walletBalance,
    double? totalMoneySaved,
    double? totalCo2Saved,
    bool? musicAllowed,
    bool? petsAllowed,
    bool? smokingAllowed,
    bool? acPreferred,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isDriverVerified: isDriverVerified ?? this.isDriverVerified,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      rcNumber: rcNumber ?? this.rcNumber,
      insuranceDetails: insuranceDetails ?? this.insuranceDetails,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      rcUrl: rcUrl ?? this.rcUrl,
      insuranceUrl: insuranceUrl ?? this.insuranceUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      walletBalance: walletBalance ?? this.walletBalance,
      totalMoneySaved: totalMoneySaved ?? this.totalMoneySaved,
      totalCo2Saved: totalCo2Saved ?? this.totalCo2Saved,
      musicAllowed: musicAllowed ?? this.musicAllowed,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      acPreferred: acPreferred ?? this.acPreferred,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}