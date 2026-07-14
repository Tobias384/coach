import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/database.dart';
import '../../main.dart';
import 'dart:math' as math;

part 'dashboard_provider.g.dart';

@riverpod
class DashboardData extends _$DashboardData {
  @override
  Future<Map<String, dynamic>> build() async {
    final db = ref.watch(databaseProvider);
    final allSets = await db.workoutDao.getAllSetEntries();

    return {
      'weeklyVolume': _calculateWeeklyVolume(allSets),
    };
  }

  Map<int, double> _calculateWeeklyVolume(List<SetEntry> sets) {
    final Map<int, double> volumeByWeek = {};

    for (final set in sets) {
      final weekKey = _getWeekKey(set.performedAt);
      final volume = set.weight * set.reps;
      volumeByWeek[weekKey] = (volumeByWeek[weekKey] ?? 0) + volume;
    }
    return volumeByWeek;
  }

  int _getWeekKey(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    final weekNumber = ((dayOfYear - 1) / 7).floor() + 1;
    return date.year * 100 + weekNumber;
  }
}

@riverpod
Future<List<Map<String, dynamic>>> exerciseProgress(ExerciseProgressRef ref, int exerciseId) async {
  final db = ref.watch(databaseProvider);
  final sets = await db.workoutDao.getSetEntriesForExercise(exerciseId);

  // Group by date to get max weight and 1RM per session
  final Map<DateTime, double> maxWeights = {};
  final Map<DateTime, double> max1RM = {};

  for (final set in sets) {
    final date = DateTime(set.performedAt.year, set.performedAt.month, set.performedAt.day);

    // Max Weight
    maxWeights[date] = math.max(maxWeights[date] ?? 0, set.weight);

    // 1RM Epley: Weight * (1 + 0.0333 * Reps)
    final oneRM = set.weight * (1 + 0.0333 * set.reps);
    max1RM[date] = math.max(max1RM[date] ?? 0, oneRM);
  }

  return maxWeights.entries.map((e) => {
    'date': e.key,
    'maxWeight': e.value,
    'oneRM': max1RM[e.key],
  }).toList();
}
