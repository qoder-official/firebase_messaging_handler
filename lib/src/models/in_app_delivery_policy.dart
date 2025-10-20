class InAppQuietHours {
  const InAppQuietHours({
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  bool isQuiet(DateTime now) {
    final int currentMinutes = now.hour * 60 + now.minute;
    final int start = startHour * 60 + startMinute;
    final int end = endHour * 60 + endMinute;

    if (start == end) {
      return false;
    }

    if (start < end) {
      return currentMinutes >= start && currentMinutes < end;
    }

    return currentMinutes >= start || currentMinutes < end;
  }

  DateTime nextAllowedTime(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime endTime =
        today.add(Duration(hours: endHour, minutes: endMinute));

    if (!isQuiet(now)) {
      return now;
    }

    if (startHour < endHour ||
        (startHour == endHour && startMinute < endMinute)) {
      if (now.isBefore(endTime)) {
        return endTime;
      }
      return endTime.add(const Duration(days: 1));
    }

    return endTime;
  }
}

class InAppDeliveryDecision {
  const InAppDeliveryDecision._({
    required this.allowed,
    this.nextEligibleAt,
    this.reason,
  });

  final bool allowed;
  final DateTime? nextEligibleAt;
  final String? reason;

  static const InAppDeliveryDecision allow =
      InAppDeliveryDecision._(allowed: true);

  factory InAppDeliveryDecision.defer({
    required DateTime nextEligibleAt,
    String? reason,
  }) =>
      InAppDeliveryDecision._(
        allowed: false,
        nextEligibleAt: nextEligibleAt,
        reason: reason,
      );
}

class InAppDeliveryPolicy {
  const InAppDeliveryPolicy({
    this.globalInterval,
    this.perTemplateInterval,
    this.globalDailyCap,
    this.perTemplateDailyCap,
    this.quietHours,
  });

  final Duration? globalInterval;
  final Duration? perTemplateInterval;
  final int? globalDailyCap;
  final int? perTemplateDailyCap;
  final InAppQuietHours? quietHours;
}

class InAppDeliveryStats {
  InAppDeliveryStats({
    this.lastShown,
    Map<String, int>? perDayCounts,
  }) : perDayCounts = perDayCounts ?? <String, int>{};

  DateTime? lastShown;
  final Map<String, int> perDayCounts;

  void register(DateTime now) {
    lastShown = now;
    final String key = _dateKey(now);
    _pruneOldEntries(now);
    perDayCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  int countForDay(DateTime day) {
    return perDayCounts[_dateKey(day)] ?? 0;
  }

  void _pruneOldEntries(DateTime now) {
    final DateTime threshold = now.subtract(const Duration(days: 7));
    final Iterable<String> staleKeys = perDayCounts.keys.where((String key) {
      final DateTime parsed = DateTime.tryParse(key) ?? now;
      return parsed.isBefore(threshold);
    }).toList();
    for (final String key in staleKeys) {
      perDayCounts.remove(key);
    }
  }

  static String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();
}
