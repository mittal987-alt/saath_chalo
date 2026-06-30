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
      'createdAt': createdAt.toIso8601String(),
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
      rideDate: DateTime.parse(map['rideDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
