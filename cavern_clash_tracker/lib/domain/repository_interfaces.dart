import '../data/local/database.dart';

abstract class IWorkoutRepository {
  Future<List<Exercise>> getExercises();
  Future<List<Routine>> getRoutines();
  Future<void> saveSession(WorkoutSession session, List<SetEntry> entries);
}

abstract class IUserRepository {
  Future<User?> getCurrentUser();
  Future<void> updateProfile(User user);
}
