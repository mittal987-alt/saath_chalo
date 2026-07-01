class RideStatus {
  // Ride statuses
  static const String active = 'active';
  static const String full = 'full';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';

  // Booking statuses
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String enRoute = 'en_route';
  static const String started = 'started';
  static const String ended = 'ended';
  static const String rejected = 'rejected';

  // Human readable labels
  static String getLabel(String status) {
    switch (status) {
      case pending: return 'Waiting for Driver';
      case confirmed: return 'Booking Confirmed ✅';
      case enRoute: return 'Driver Coming 🚗';
      case started: return 'Ride Started 🟢';
      case ended: return 'Ride Completed ✅';
      case rejected: return 'Request Declined ❌';
      default: return status;
    }
  }

  static String getDriverLabel(String status) {
    switch (status) {
      case confirmed: return 'Go to Pickup Point';
      case enRoute: return 'Heading to Rider';
      case started: return 'Ride in Progress';
      case ended: return 'Ride Completed';
      default: return status;
    }
  }
}