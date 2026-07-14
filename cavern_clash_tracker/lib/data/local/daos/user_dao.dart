import 'package:drift/drift.dart';
import '../database.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  Future<List<User>> getAllUsers() => select(users).get();
  Future<int> createUser(UsersCompanion user) => into(users).insert(user);

  Future<User?> getUser(int id) => (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getUserByAuthId(String authUserId) {
    return (select(users)..where((t) => t.authUserId.equals(authUserId))).getSingleOrNull();
  }

  Future<User?> getCurrentUser(String? authUserId) async {
    if (authUserId != null && authUserId.isNotEmpty) {
      final profile = await getUserByAuthId(authUserId);
      if (profile != null) return profile;
    }
    return (select(users)..orderBy([(t) => OrderingTerm.asc(t.id)])).getSingleOrNull();
  }

  Future<void> saveProfile({
    required String authUserId,
    required String username,
    required String email,
    double? weightKg,
    double? heightCm,
    double? barbellWeightKg,
    String? goal,
    String? injuries,
    String? restrictions,
  }) async {
    final existing = await getUserByAuthId(authUserId);
    if (existing == null) {
      await createUser(UsersCompanion(
        authUserId: Value(authUserId),
        username: Value(username),
        email: Value(email),
        weightKg: Value(weightKg),
        heightCm: Value(heightCm),
        barbellWeightKg: Value(barbellWeightKg),
        goal: Value(goal),
        injuries: Value(injuries),
        restrictions: Value(restrictions),
      ));
      return;
    }

    await (update(users)..where((t) => t.id.equals(existing.id))).write(UsersCompanion(
      authUserId: Value(authUserId),
      username: Value(username),
      email: Value(email),
      weightKg: Value(weightKg),
      heightCm: Value(heightCm),
      barbellWeightKg: Value(barbellWeightKg),
      goal: Value(goal),
      injuries: Value(injuries),
      restrictions: Value(restrictions),
    ));
  }

  Future<void> updateRestrictions(int userId, String restrictions) {
    return (update(users)..where((t) => t.id.equals(userId)))
      .write(UsersCompanion(restrictions: Value(restrictions)));
  }
}
