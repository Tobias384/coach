import 'dart:async';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/database.dart';
import '../../main.dart';

import '../../services/health_connect_service.dart';
import 'package:health/health.dart';

part 'training_provider.g.dart';

class TrainingState {
  final WorkoutSession? activeSession;
  final List<Exercise> currentExercises;
  final int? restTimerSeconds;
  final bool isResting;

  TrainingState({
    this.activeSession,
    this.currentExercises = const [],
    this.restTimerSeconds,
    this.isResting = false,
  });

  TrainingState copyWith({
    WorkoutSession? activeSession,
    List<Exercise>? currentExercises,
    int? restTimerSeconds,
    bool? isResting,
  }) {
    return TrainingState(
      activeSession: activeSession ?? this.activeSession,
      currentExercises: currentExercises ?? this.currentExercises,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      isResting: isResting ?? this.isResting,
    );
  }
}

@riverpod
class TrainingNotifier extends _$TrainingNotifier {
  Timer? _timer;

  @override
  TrainingState build() {
    return TrainingState();
  }

  Future<void> startTraining(Routine routine) async {
    final db = ref.read(databaseProvider);
    final sessionId = await db.workoutDao.startSession(WorkoutSessionsCompanion(
      userId: const Value(1), // Default user for now
      routineId: Value(routine.id),
      startTime: Value(DateTime.now()),
    ));

    final session = (await db.workoutDao.getAllSessions()).firstWhere((s) => s.id == sessionId);
    final exercises = await db.workoutDao.getExercisesForRoutine(routine.id);

    state = state.copyWith(
      activeSession: session,
      currentExercises: exercises,
    );
  }

  Future<void> addSet(int exerciseId, double weight, int reps) async {
    if (state.activeSession == null) return;

    final db = ref.read(databaseProvider);
    await db.workoutDao.addSetEntry(SetEntriesCompanion(
      sessionId: Value(state.activeSession!.id),
      exerciseId: Value(exerciseId),
      weight: Value(weight),
      reps: Value(reps),
      performedAt: Value(DateTime.now()),
    ));

    ref.invalidate(lastExerciseSetProvider(exerciseId));
    startRestTimer(60);
  }

  void startRestTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(restTimerSeconds: seconds, isResting: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimerSeconds! > 0) {
        state = state.copyWith(restTimerSeconds: state.restTimerSeconds! - 1);
      } else {
        stopRestTimer();
      }
    });
  }

  void stopRestTimer() {
    _timer?.cancel();
    state = state.copyWith(isResting: false, restTimerSeconds: 0);
  }

  Future<void> finishTraining() async {
    if (state.activeSession == null) return;

    final db = ref.read(databaseProvider);
    final session = state.activeSession!;
    final startTime = session.startTime;
    final endTime = DateTime.now();

    await db.workoutDao.endSession(session.id);

    // Integración con Health Connect
    final healthService = HealthConnectService();
    try {
      if (await healthService.isHealthConnectAvailable()) {
        final hasPermissions = await healthService.requestPermissions();
        if (hasPermissions) {
          await healthService.writeWorkout(
            start: startTime,
            end: endTime,
            type: HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
          );
        }
      }
    } catch (e) {
      print('Health Connect no disponible o permisos denegados: $e');
    }

    state = TrainingState();
    _timer?.cancel();
  }
}

@riverpod
Future<SetEntry?> lastExerciseSet(LastExerciseSetRef ref, int exerciseId) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.getLastSetForExercise(exerciseId);
}
