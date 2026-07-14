import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/database.dart';
import 'package:drift/drift.dart';

class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppDatabase _db;

  SyncService(this._db);

  Future<void> syncUp() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Sync Profile (Excluding health data)
    final localUser = await _db.userDao.getCurrentUser(user.id);
    if (localUser != null) {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': localUser.username,
        'restrictions': localUser.restrictions,
        'email': localUser.email,
        'weight_kg': localUser.weightKg,
        'height_cm': localUser.heightCm,
        'goal': localUser.goal,
        'injuries': localUser.injuries,
      });
    }

    // 2. Sync Routines
    final routines = await _db.workoutDao.getAllRoutines();
    for (var r in routines) {
      await _supabase.from('routines').upsert({
        'local_id': r.id,
        'user_id': user.id,
        'name': r.name,
        'description': r.description,
      });
    }

    // 3. Sync Workout Sessions (Only metadata)
    final sessions = await _db.workoutDao.getAllSessions();
    for (var s in sessions) {
      await _supabase.from('workout_sessions').upsert({
        'local_id': s.id,
        'user_id': user.id,
        'routine_id': s.routineId,
        'start_time': s.startTime.toIso8601String(),
        'end_time': s.endTime?.toIso8601String(),
      });
    }

    // IMPORTANT: Health Connect data is NOT synced here.
    // It remains local and only exported to Health Connect if authorized.
  }

  Future<void> syncDown() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Implementation to pull data from Supabase to Drift
    // This would involve fetching from 'routines' and inserting into Drift
  }
}
