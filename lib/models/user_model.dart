class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String profilePic;
  final double rating;
  final int totalRides;
  final bool isVerified;
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
      'createdAt': createdAt.toIso8601String(),
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
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}