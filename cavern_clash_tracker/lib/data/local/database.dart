import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/user_dao.dart';
import 'daos/workout_dao.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get authUserId => text().nullable()();
  TextColumn get username => text()();
  TextColumn get email => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get barbellWeightKg => real().nullable()();
  TextColumn get goal => text().nullable()();
  TextColumn get injuries => text().nullable()();
  TextColumn get restrictions => text().nullable()(); // Comma-separated muscle groups
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get targetMuscles => text().nullable()(); // Involved muscles
  TextColumn get equipment => text().nullable()(); // Required equipment
}

class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get routineId => integer().references(Routines, #id).nullable()();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
}

class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  DateTimeColumn get performedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Users,
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    SetEntries,
  ],
  daos: [
    UserDao,
    WorkoutDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> ensureExerciseNotesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS exercise_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL UNIQUE REFERENCES exercises(id) ON DELETE CASCADE,
        note TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> ensureNutritionEntriesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS nutrition_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        meal_name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        photo_path TEXT,
        source TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<String?> getExerciseNote(int exerciseId) async {
    await ensureExerciseNotesTable();
    final rows = await customSelect(
      'SELECT note FROM exercise_notes WHERE exercise_id = ?',
      [Variable.withInt(exerciseId)],
    ).get();
    final row = rows.isEmpty ? null : rows.singleOrNull;
    return row?.data['note']?.toString();
  }

  Future<void> saveExerciseNote(int exerciseId, String note) async {
    await ensureExerciseNotesTable();
    await customStatement(
      '''
      INSERT INTO exercise_notes (exercise_id, note, updated_at)
      VALUES (?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(exercise_id) DO UPDATE SET note = excluded.note, updated_at = CURRENT_TIMESTAMP
      ''',
      [Variable.withInt(exerciseId), Variable.withString(note)],
    );
  }

  Future<int> insertNutritionEntry({
    required String mealName,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? photoPath,
    String? source,
  }) async {
    await ensureNutritionEntriesTable();
    final result = await customInsert(
      'INSERT INTO nutrition_entries (meal_name, calories, protein_g, carbs_g, fat_g, photo_path, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(mealName),
        Variable.withReal(calories),
        Variable.withReal(proteinG),
        Variable.withReal(carbsG),
        Variable.withReal(fatG),
        Variable.withString(photoPath),
        Variable.withString(source),
        Variable.withDateTime(DateTime.now()),
      ],
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getNutritionEntriesForDate(DateTime date) async {
    await ensureNutritionEntriesTable();
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await customSelect(
      'SELECT id, meal_name, calories, protein_g, carbs_g, fat_g, photo_path, source, created_at FROM nutrition_entries WHERE created_at >= ? AND created_at < ? ORDER BY created_at DESC',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).get();

    return rows.map((row) => {
      'id': row.data['id'],
      'meal_name': row.data['meal_name'],
      'calories': row.data['calories'],
      'protein_g': row.data['protein_g'],
      'carbs_g': row.data['carbs_g'],
      'fat_g': row.data['fat_g'],
      'photo_path': row.data['photo_path'],
      'source': row.data['source'],
      'created_at': row.data['created_at'],
    }).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
