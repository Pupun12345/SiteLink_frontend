import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/maps_config.dart';

// ═══════════════════════════════════════════════════════════════════
//  GOOGLE PLACES API — location picker ki search ke liye
// ═══════════════════════════════════════════════════════════════════
// Hamara backend nahi, seedha Google ka Places API (legacy REST) —
// isliye alag file me, api_client.dart ke baseUrl services ke saath
// mix nahi karte. Autocomplete → user type karte hi suggestions;
// Details → suggestion tap karne par uska exact lat/lng.
class PlaceSuggestion {
  final String placeId;
  final String description;
  const PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String? formattedAddress;
  const PlaceDetails({required this.lat, required this.lng, this.formattedAddress});
}

class PlacesApiService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  /// Search-as-you-type suggestions. India tak restrict (app ka target market).
  Future<List<PlaceSuggestion>> autocomplete(String input,
      {String? sessionToken}) async {
    if (input.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('$_base/autocomplete/json').replace(
        queryParameters: {
          'input': input,
          'key': MapsConfig.apiKey,
          'components': 'country:in',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body);
      if (json['status'] != 'OK') {
        if (kDebugMode && json['status'] != 'ZERO_RESULTS') {
          print('[PlacesAPI] autocomplete status: ${json['status']} '
              '${json['error_message'] ?? ''}');
        }
        return [];
      }
      final predictions = json['predictions'] as List? ?? [];
      return predictions
          .map((p) => PlaceSuggestion(
                placeId: p['place_id']?.toString() ?? '',
                description: p['description']?.toString() ?? '',
              ))
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) print('[PlacesAPI] autocomplete error: $e');
      return [];
    }
  }

  /// Suggestion select hone par uska exact lat/lng.
  Future<PlaceDetails?> details(String placeId, {String? sessionToken}) async {
    try {
      final uri = Uri.parse('$_base/details/json').replace(
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry,formatted_address',
          'key': MapsConfig.apiKey,
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json['status'] != 'OK') return null;
      final loc = json['result']?['geometry']?['location'];
      if (loc == null) return null;
      return PlaceDetails(
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
        formattedAddress: json['result']?['formatted_address']?.toString(),
      );
    } catch (e) {
      if (kDebugMode) print('[PlacesAPI] details error: $e');
      return null;
    }
  }
}
