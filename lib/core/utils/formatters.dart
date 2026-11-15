class Formatters {
  Formatters._();

  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String formatCompactDuration(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final raw = text.trim();

    if (RegExp(r'^\d+[dhm](\s+\d+[hm])?(\s+\d+m)?$').hasMatch(raw)) {
      return raw;
    }

    final dayMatch = RegExp(r'(\d+)\s*(?:days?|d)\b', caseSensitive: false).firstMatch(raw);
    final hourMatch = RegExp(r'(\d+)\s*(?:hours?|hrs?|h)\b', caseSensitive: false).firstMatch(raw);
    final minMatch = RegExp(r'(\d+)\s*(?:minutes?|mins?|m)\b', caseSensitive: false).firstMatch(raw);
    final secMatch = RegExp(r'(\d+)\s*(?:seconds?|secs?|s)\b', caseSensitive: false).firstMatch(raw);

    final days = dayMatch != null ? int.tryParse(dayMatch.group(1)!) : null;
    final hours = hourMatch != null ? int.tryParse(hourMatch.group(1)!) : null;
    final mins = minMatch != null ? int.tryParse(minMatch.group(1)!) : null;
    final secs = secMatch != null ? int.tryParse(secMatch.group(1)!) : null;

    if (days != null || hours != null || mins != null || secs != null) {
      final parts = <String>[];
      if (days != null && days > 0) parts.add('${days}d');
      if (hours != null && hours > 0) parts.add('${hours}h');
      if (mins != null && mins > 0) parts.add('${mins}m');
      if (parts.isEmpty && secs != null) parts.add('${secs}s');
      if (parts.isNotEmpty) return parts.join(' ');
    }

    // Clean fallback: shorten words
    return raw
        .replaceAll(RegExp(r'\s*hours?', caseSensitive: false), 'h')
        .replaceAll(RegExp(r'\s*hrs?', caseSensitive: false), 'h')
        .replaceAll(RegExp(r'\s*minutes?', caseSensitive: false), 'm')
        .replaceAll(RegExp(r'\s*mins?', caseSensitive: false), 'm')
        .replaceAll(RegExp(r'\s*seconds?', caseSensitive: false), 's')
        .replaceAll(RegExp(r'\s*secs?', caseSensitive: false), 's')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
