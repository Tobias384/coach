import 'package:drift/drift.dart';
import '../database.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [Exercises, Routines, RoutineExercises, WorkoutSessions, SetEntries])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(AppDatabase db) : super(db);

  // Exercises
  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<List<Exercise>> getFilteredExercises({String? query, String? muscle, String? equipment}) {
    return (select(exercises)..where((t) {
      final matchesQuery = query != null ? t.name.contains(query.toLowerCase()) | t.name.contains(query) : const Constant(true);
      final matchesMuscle = muscle != null ? t.targetMuscles.contains(muscle) : const Constant(true);
      final matchesEquipment = equipment != null ? t.equipment.contains(equipment) : const Constant(true);
      return matchesQuery & matchesMuscle & matchesEquipment;
    })).get();
  }

  Future<int> addExercise(ExercisesCompanion entry) => into(exercises).insert(entry);

  // Routines
  Future<void> deleteRoutineExercises(int routineId) {
    return (delete(routineExercises)..where((t) => t.routineId.equals(routineId))).go();
  }

  Future<void> addRoutineExercise(RoutineExercisesCompanion entry) => into(routineExercises).insert(entry);

  // Routines
  Future<List<Routine>> getAllRoutines() => select(routines).get();
  Future<int> createRoutine(RoutinesCompanion entry) => into(routines).insert(entry);

  // Sessions
  Future<List<WorkoutSession>> getAllSessions() => select(workoutSessions).get();
  Future<int> startSession(WorkoutSessionsCompanion entry) => into(workoutSessions).insert(entry);

  Future<String?> getExerciseNote(int exerciseId) => db.getExerciseNote(exerciseId);
  Future<void> saveExerciseNote(int exerciseId, String note) => db.saveExerciseNote(exerciseId, note);
  Future<void> endSession(int sessionId) =>
    (update(workoutSessions)..where((t) => t.id.equals(sessionId)))
    .write(WorkoutSessionsCompanion(endTime: Value(DateTime.now())));

  // Sets
  Future<int> addSetEntry(SetEntriesCompanion entry) => into(setEntries).insert(entry);

  Future<List<SetEntry>> getSetEntriesForExercise(int exerciseId) {
    return (select(setEntries)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm(expression: t.performedAt, mode: OrderingMode.asc)]))
    .get();
  }

  Future<List<SetEntry>> getAllSetEntries() => select(setEntries).get();

  Future<SetEntry?> getLastSetForExercise(int exerciseId) {
    return (select(setEntries)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm(expression: t.performedAt, mode: OrderingMode.desc)])
      ..limit(1))
    .getSingleOrNull();
  }

  Future<List<Exercise>> getExercisesForRoutine(int routineId) async {
    final query = select(routineExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(routineExercises.exerciseId)),
    ])..where(routineExercises.routineId.equals(routineId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(exercises)).toList();
  }
}
