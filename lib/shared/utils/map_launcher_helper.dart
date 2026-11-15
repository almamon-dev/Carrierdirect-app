import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_toast.dart';

class MapLauncherHelper {
  MapLauncherHelper._();

  /// Launch Google Maps navigation
  static Future<bool> launchMapsNavigation(
    BuildContext context, {
    required String destinationAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationTitle,
    bool showToastOnError = true,
  }) => openGoogleMaps(
    context,
    destinationAddress: destinationAddress,
    latitude: destinationLat,
    longitude: destinationLng,
    destinationTitle: destinationTitle,
    showToastOnError: showToastOnError,
  );

  /// Launch Google Maps with turn-by-turn driving directions to destination
  static Future<bool> openGoogleMaps(
    BuildContext context, {
    required String destinationAddress,
    double? latitude,
    double? longitude,
    String? destinationTitle,
    bool showToastOnError = true,
  }) async {
    final String encodedQuery = (latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0)
        ? '$latitude,$longitude'
        : Uri.encodeComponent(destinationAddress);

    final List<Uri> urisToTry = [
      Uri.parse('google.navigation:q=$encodedQuery&mode=d'),
      Uri.parse('geo:0,0?q=$encodedQuery'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedQuery&travelmode=driving',
      ),
    ];

    bool launched = false;

    for (final uri in urisToTry) {
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) break;
        }
      } catch (_) {
        // Try next fallback URI
      }
    }

    if (!launched) {
      // Direct launch fallback without canLaunchUrl check
      try {
        final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedQuery',
        );
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (showToastOnError && context.mounted) {
          AppToast.error(
            context,
            'Please restart the app (`R` in terminal) to load Google Maps plugin.',
          );
        }
        return false;
      }
    }

    if (!launched && showToastOnError && context.mounted) {
      AppToast.error(
        context,
        'Could not open Google Maps. Please restart the app with `R`.',
      );
    }
    return launched;
  }

  /// Launch Waze Navigation
  static Future<void> openWaze(
    BuildContext context, {
    required String destinationAddress,
  }) async {
    final encodedQuery = Uri.encodeComponent(destinationAddress);
    final wazeUri = Uri.parse(
      'https://waze.com/ul?q=$encodedQuery&navigate=yes',
    );

    try {
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          await openGoogleMaps(context, destinationAddress: destinationAddress);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await openGoogleMaps(context, destinationAddress: destinationAddress);
      }
    }
  }
}
