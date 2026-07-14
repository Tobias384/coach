import '../../domain/repository_interfaces.dart';
import '../local/database.dart';
import '../local/daos/workout_dao.dart';

class WorkoutRepository implements IWorkoutRepository {
  final WorkoutDao _workoutDao;

  WorkoutRepository(this._workoutDao);

  @override
  Future<List<Exercise>> getExercises() => _workoutDao.getAllExercises();

  @override
  Future<List<Routine>> getRoutines() => _workoutDao.getAllRoutines();

  @override
  Future<void> saveSession(WorkoutSession session, List<SetEntry> entries) async {
    // Logic to save session and entries
  }
}
