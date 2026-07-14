import 'package:drift/drift.dart';
import '../data/local/database.dart';

class DataSeeder {
  static Future<void> seed(AppDatabase db) async {
    final existing = await db.workoutDao.getAllExercises();
    if (existing.isNotEmpty) return;

    // Seed Exercises
    final exerciseList = [
      {'name': 'Press de Banca', 'muscle': 'Pecho', 'equip': 'Barra'},
      {'name': 'Sentadilla', 'muscle': 'Piernas', 'equip': 'Barra'},
      {'name': 'Peso Muerto', 'muscle': 'Espalda,Piernas', 'equip': 'Barra'},
      {'name': 'Dominadas', 'muscle': 'Espalda', 'equip': 'Cuerpo'},
      {'name': 'Press Militar', 'muscle': 'Hombros', 'equip': 'Mancuernas'},
      {'name': 'Curl de Bíceps', 'muscle': 'Bíceps', 'equip': 'Mancuernas'},
      {'name': 'Tríceps Polea', 'muscle': 'Tríceps', 'equip': 'Polea'},
      {'name': 'Zancadas', 'muscle': 'Piernas', 'equip': 'Mancuernas'},
      {'name': 'Remo con Barra', 'muscle': 'Espalda', 'equip': 'Barra'},
      {'name': 'Aperturas de Pecho', 'muscle': 'Pecho', 'equip': 'Mancuernas'},
    ];

    for (var ex in exerciseList) {
      await db.workoutDao.addExercise(ExercisesCompanion(
        name: Value(ex['name']!),
        targetMuscles: Value(ex['muscle']!),
        equipment: Value(ex['equip']!),
        category: const Value('Fuerza'),
      ));
    }

    // Seed Templates
    await _createTemplate(db, 'Push/Pull/Legs - Empuje', ['Press de Banca', 'Press Militar', 'Tríceps Polea']);
    await _createTemplate(db, 'Push/Pull/Legs - Tracción', ['Peso Muerto', 'Dominadas', 'Remo con Barra']);
    await _createTemplate(db, 'Push/Pull/Legs - Piernas', ['Sentadilla', 'Zancadas']);
    await _createTemplate(db, 'Full Body - Día 1', ['Sentadilla', 'Press de Banca', 'Remo con Barra']);
    await _createTemplate(db, 'Upper/Lower - Tren Superior', ['Press de Banca', 'Remo con Barra', 'Press Militar', 'Dominadas']);
  }

  static Future<void> _createTemplate(AppDatabase db, String name, List<String> exerciseNames) async {
    final routineId = await db.workoutDao.createRoutine(RoutinesCompanion(
      name: Value(name),
      description: Value('Plantilla predefinida: $name'),
    ));

    final allEx = await db.workoutDao.getAllExercises();
    for (int i = 0; i < exerciseNames.length; i++) {
      final ex = allEx.firstWhere((e) => e.name == exerciseNames[i]);
      await db.workoutDao.addRoutineExercise(RoutineExercisesCompanion(
        routineId: Value(routineId),
        exerciseId: Value(ex.id),
        orderIndex: Value(i),
      ));
    }
  }
}
