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
      'createdAt': createdAt.toIso8601String(),
    };
  }

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
      rideDate: DateTime.parse(
          map['rideDate'] ?? DateTime.now().toIso8601String()),
      rideTime: map['rideTime'] ?? '',
      availableSeats: map['availableSeats'] ?? 1,
      pricePerSeat: (map['pricePerSeat'] ?? 0.0).toDouble(),
      womenOnly: map['womenOnly'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}