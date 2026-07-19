import 'package:geolocator/geolocator.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOCATION SERVICE — permission request + current position
// ═══════════════════════════════════════════════════════════════════
// Reusable: "Get Directions" jaise features ke liye. Permission na milne
// par bhi caller ko block nahi karta — bas position null aata hai, aur
// feature apne fixed-destination fallback pe chala jaata hai.
class LocationResult {
  final Position? position;
  final String? error; // user ko dikhane wala message (fail par)
  const LocationResult({this.position, this.error});

  bool get hasPosition => position != null;
}

class LocationService {
  /// Permission maango (na ho to) aur current position do.
  /// Location service off / permission denied / denied-forever — sabme
  /// graceful `LocationResult(error: ...)` aata hai, exception nahi.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
            error: 'Location service band hai. Settings me on karein.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission(); // ✅ permission dialog
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
            error: 'Location permission allow nahi ki gayi.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
            error:
                'Location permission block hai. App Settings me jaake allow karein.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LocationResult(position: position);
    } catch (e) {
      return LocationResult(error: 'Location nahi mil paayi: $e');
    }
  }

  /// App ki location permission settings screen kholo (denied-forever case).
  static Future<void> openAppSettings() => Geolocator.openAppSettings();
}
