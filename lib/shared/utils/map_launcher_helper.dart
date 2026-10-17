import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_toast.dart';

class MapLauncherHelper {
  MapLauncherHelper._();

  /// Launch Google Maps with turn-by-turn driving directions to destination
  static Future<void> openGoogleMaps(
    BuildContext context, {
    required String destinationAddress,
    String? destinationTitle,
  }) async {
    final encodedQuery = Uri.encodeComponent(destinationAddress);

    final List<Uri> urisToTry = [
      Uri.parse('google.navigation:q=$encodedQuery&mode=d'),
      Uri.parse('geo:0,0?q=$encodedQuery'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedQuery&travelmode=driving'),
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
        final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedQuery');
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Please restart the app (`R` in terminal) to load Google Maps plugin.');
        }
        return;
      }
    }

    if (!launched && context.mounted) {
      AppToast.error(context, 'Could not open Google Maps. Please restart the app with `R`.');
    }
  }

  /// Launch Waze Navigation
  static Future<void> openWaze(
    BuildContext context, {
    required String destinationAddress,
  }) async {
    final encodedQuery = Uri.encodeComponent(destinationAddress);
    final wazeUri = Uri.parse('https://waze.com/ul?q=$encodedQuery&navigate=yes');

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
