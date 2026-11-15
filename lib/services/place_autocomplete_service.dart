import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';

class PlaceSuggestion {
  final String mainText;
  final String secondaryText;
  final String fullAddress;
  final String? placeId;
  final double? latitude;
  final double? longitude;

  const PlaceSuggestion({
    required this.mainText,
    required this.secondaryText,
    required this.fullAddress,
    this.placeId,
    this.latitude,
    this.longitude,
  });
}

class PlaceAutocompleteService {
  static final PlaceAutocompleteService _instance =
      PlaceAutocompleteService._internal();
  factory PlaceAutocompleteService() => _instance;
  PlaceAutocompleteService._internal();

  /// Search places directly using Google Maps Places API (New)
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Direct call to Google Maps Places API (New)
    try {
      final googleUrl = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );
      final response = await http
          .post(
            googleUrl,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
            },
            body: jsonEncode({'input': cleanQuery}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        if (suggestions.isNotEmpty) {
          final results = <PlaceSuggestion>[];
          for (final item in suggestions) {
            final pred = item['placePrediction'] as Map<String, dynamic>?;
            if (pred == null) continue;

            final placeId = pred['placeId']?.toString();
            final fullText = pred['text']?['text']?.toString() ?? '';
            final structured =
                pred['structuredFormat'] as Map<String, dynamic>?;
            final mainText =
                structured?['mainText']?['text']?.toString() ?? fullText;
            final secondaryText =
                structured?['secondaryText']?['text']?.toString() ?? '';

            if (fullText.isNotEmpty) {
              results.add(
                PlaceSuggestion(
                  mainText: mainText.isNotEmpty ? mainText : fullText,
                  secondaryText: secondaryText,
                  fullAddress: fullText,
                  placeId: placeId,
                ),
              );
            }
          }

          if (results.isNotEmpty) {
            return results;
          }
        }
      }
    } catch (_) {}

    return [];
  }

  /// Fetch exact coordinates for a selected Google Place
  Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
              'X-Goog-FieldMask': 'id,location,formattedAddress',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        if (location != null) {
          final lat = (location['latitude'] as num?)?.toDouble();
          final lng = (location['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng};
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
