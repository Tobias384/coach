import 'dart:math' as math;

class StreakSummary {
  final int currentStreak;
  final int bestStreak;
  final bool isNewRecord;
  final String message;

  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.isNewRecord,
    required this.message,
  });
}

class StreakService {
  static StreakSummary calculate(List<DateTime> sessionDates) {
    if (sessionDates.isEmpty) {
      return const StreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        isNewRecord: false,
        message: 'Tu primera racha empieza hoy.',
      );
    }

    final normalizedDates = sessionDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList()
      ..sort();

    final weeklyCounts = <DateTime, int>{};
    for (final date in normalizedDates) {
      final weekStart = _weekStart(date);
      weeklyCounts.update(weekStart, (count) => count + 1, ifAbsent: () => 1);
    }

    final weekCounts = weeklyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final weekThresholds = weekCounts.map((entry) => entry.value >= 2).toList();

    if (weekThresholds.isEmpty) {
      return const StreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        isNewRecord: false,
        message: 'Tu primera racha empieza hoy.',
      );
    }

    final currentStreak = _countConsecutiveFromEnd(weekThresholds);
    final bestStreak = _bestStreak(weekThresholds);
    final previousBest = weekThresholds.length > 1 ? _bestStreak(weekThresholds.sublist(0, weekThresholds.length - 1)) : 0;
    final isNewRecord = currentStreak > 0 && currentStreak > previousBest;

    final message = isNewRecord
        ? '¡Racha récord! $currentStreak semanas seguidas.'
        : currentStreak > 0
            ? 'Sigue así, cada semana suma.'
            : 'Tu primera racha empieza hoy.';

    return StreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isNewRecord: isNewRecord,
      message: message,
    );
  }

  static int _countConsecutiveFromEnd(List<bool> weekThresholds) {
    var streak = 0;
    for (var index = weekThresholds.length - 1; index >= 0; index--) {
      if (!weekThresholds[index]) break;
      streak++;
    }
    return streak;
  }

  static int _bestStreak(List<bool> weekThresholds) {
    var best = 0;
    var current = 0;
    for (final active in weekThresholds) {
      if (active) {
        current++;
        best = math.max(best, current);
      } else {
        current = 0;
      }
    }
    return best;
  }

  static DateTime _weekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
