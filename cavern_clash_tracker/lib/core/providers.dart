import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../services/data_seeder.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final seedDataProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await DataSeeder.seed(db);
});
