abstract final class BrazilClock {
  static const _saoPauloOffset = Duration(hours: -3);

  /// Sao Paulo uses UTC-03:00 year-round since 2019.
  /// Starting from UTC avoids inheriting an incorrect device timezone.
  static DateTime now() => fromInstant(DateTime.now());

  static DateTime fromInstant(DateTime instant) {
    return instant.toUtc().add(_saoPauloOffset);
  }

  static String dateKey([DateTime? instant]) {
    final value = instant == null ? now() : fromInstant(instant);
    return '${value.year.toString().padLeft(4, '0')}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
