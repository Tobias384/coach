import 'package:flutter_test/flutter_test.dart';
import 'package:cavern_clash_tracker/features/dashboard/streak_service.dart';

void main() {
  test('calcula la racha correcta a partir de semanas con 2 entrenamientos o más', () {
    final dates = [
      DateTime(2024, 1, 1),
      DateTime(2024, 1, 2),
      DateTime(2024, 1, 8),
      DateTime(2024, 1, 9),
      DateTime(2024, 1, 15),
      DateTime(2024, 1, 16),
      DateTime(2024, 1, 22),
      DateTime(2024, 1, 23),
      DateTime(2024, 1, 29),
      DateTime(2024, 1, 30),
    ];

    final summary = StreakService.calculate(dates);

    expect(summary.currentStreak, 3);
    expect(summary.bestStreak, 3);
  });
}
