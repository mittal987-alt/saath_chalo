import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class NavigationService {
  // ✅ Open Google Maps Navigation to a destination
  static Future<void> navigateTo({
    required double destLat,
    required double destLng,
    String? label,
  }) async {
    final url =
        'google.navigation:q=$destLat,$destLng&mode=d';
    final fallbackUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';

    final uri = Uri.parse(url);
    final fallback = Uri.parse(fallbackUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(fallback,
          mode: LaunchMode.externalApplication);
    }
  }

  // ✅ Open Google Maps showing a location
  static Future<void> showOnMap({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final url = label != null
        ? 'geo:$lat,$lng?q=$lat,$lng($label)'
        : 'geo:$lat,$lng?q=$lat,$lng';
    final fallback =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    final uri = Uri.parse(url);
    final fallback2 = Uri.parse(fallback);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(fallback2,
          mode: LaunchMode.externalApplication);
    }
  }

  // ✅ Call a phone number
  static Future<void> callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ✅ Open WhatsApp
  static Future<void> openWhatsApp(String phone,
      {String? message}) async {
    final msg = Uri.encodeComponent(message ?? '');
    final url = 'https://wa.me/91$phone?text=$msg';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ✅ Get distance string
  static String getDistanceString(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}