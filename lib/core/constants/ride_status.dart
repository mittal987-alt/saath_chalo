import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class RideStatus {
  // Ride statuses
  static const String active = 'active';
  static const String full = 'full';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';

  // Booking statuses
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String confirmed = 'confirmed';
  static const String enRoute = 'en_route';
  static const String started = 'started';
  static const String ended = 'ended';
  static const String rejected = 'rejected';

  // Human readable labels
  static String getLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case pending: return l10n?.pending ?? 'Waiting for Driver';
      case accepted:
      case confirmed: return l10n?.confirmed ?? 'Booking Confirmed ✅';
      case enRoute: return l10n?.trackMyRide ?? 'Driver Coming 🚗';
      case started: return l10n?.started ?? 'Ride Started 🟢';
      case ended: return l10n?.ended ?? 'Ride Completed ✅';
      case rejected: return l10n?.decline ?? 'Request Declined ❌';
      default: return status;
    }
  }

  static String getDriverLabel(BuildContext context, String status) {
    // Note: We might need more specific driver-side keys in ARB later
    switch (status) {
      case accepted:
      case confirmed: return 'Go to Pickup Point';
      case enRoute: return 'Heading to Rider';
      case started: return 'Ride in Progress';
      case ended: return 'Ride Completed';
      default: return status;
    }
  }
}
