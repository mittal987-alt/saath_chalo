import 'package:flutter_test/flutter_test.dart';
import 'package:saathchalo/services/ai_assistant_service.dart';

void main() {
  test('buildContextSummary includes user metrics and ride details', () {
    final summary = AIAssistantService.buildContextSummary(
      user: {
        'name': 'Ava',
        'totalRides': 8,
        'totalMoneySaved': 1200.0,
        'totalCo2Saved': 4.5,
        'rating': 4.8,
        'walletBalance': 250.0,
      },
      bookings: [
        {
          'from': 'Noida',
          'to': 'Gurgaon',
          'status': 'completed',
          'totalPrice': 180.0,
          'rideTime': '08:30',
          'rideDate': '2026-08-06',
        },
      ],
      offeredRides: [
        {
          'from': 'Delhi',
          'to': 'Agra',
          'status': 'active',
          'pricePerSeat': 350.0,
          'rideDate': '2026-08-10',
          'rideTime': '06:00',
          'availableSeats': 2,
        },
      ],
      reviews: [
        {'rating': 5.0, 'comment': 'Great ride'},
      ],
    );

    expect(summary, contains('Ava'));
    expect(summary, contains('8 rides'));
    expect(summary, contains('₹1200'));
    expect(summary, contains('Noida'));
    expect(summary, contains('Delhi'));
    expect(summary, contains('₹350'));
  });
}
