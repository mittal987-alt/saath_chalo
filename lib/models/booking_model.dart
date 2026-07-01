class BookingModel {
  final String bookingId;
  final String rideId;
  final String riderUid;
  final String riderName;
  final String riderPhone;
  final String driverUid;
  final String driverName;
  final String from;
  final String to;
  final DateTime rideDate;
  final String rideTime;
  final int seatsBooked;
  final double totalPrice;
  final double pricePerSeat;
  final String status; // pending, confirmed, cancelled, completed
  final String paymentStatus; // unpaid, paid
  final String paymentMethod; // Razorpay, Cash
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.rideId,
    required this.riderUid,
    required this.riderName,
    required this.riderPhone,
    required this.driverUid,
    required this.driverName,
    required this.from,
    required this.to,
    required this.rideDate,
    required this.rideTime,
    required this.seatsBooked,
    required this.totalPrice,
    required this.pricePerSeat,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    required this.paymentMethod,
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
      'createdAt': createdAt.toIso8601String(),
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
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      rideDate: DateTime.parse(map['rideDate'] ?? DateTime.now().toIso8601String()),
      rideTime: map['rideTime'] ?? '',
      seatsBooked: map['seatsBooked'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      pricePerSeat: (map['pricePerSeat'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
