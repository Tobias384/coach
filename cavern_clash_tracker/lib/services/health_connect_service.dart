import 'dart:io';

import 'package:health/health.dart';

class HealthConnectService {
  static final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: true);

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.EXERCISE,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ_WRITE,
  ];

  HealthFactory get health => _health;

  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<HealthPermissionStatus> requestPermissions() async {
    if (!Platform.isAndroid) {
      return HealthPermissionStatus.notGranted;
    }

    try {
      final hasPermissions = await _health.hasPermissions(_types, permissions: _permissions);
      if (hasPermissions == true) {
        return HealthPermissionStatus.granted;
      }

      final granted = await _health.requestAuthorization(_types, permissions: _permissions);
      return granted ? HealthPermissionStatus.granted : HealthPermissionStatus.partial;
    } catch (_) {
      return HealthPermissionStatus.notGranted;
    }
  }

  Future<Map<String, double>> getTodayStats() async {
    if (!Platform.isAndroid) {
      return {'steps': 0, 'calories': 0};
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final permissionStatus = await requestPermissions();
      if (permissionStatus == HealthPermissionStatus.notGranted) {
        return {'steps': 0, 'calories': 0};
      }

      final stepData = await _health.getHealthDataFromTypes(startOfDay, now, [HealthDataType.STEPS]);
      final calorieData = await _health.getHealthDataFromTypes(startOfDay, now, [HealthDataType.ACTIVE_ENERGY_BURNED]);

      final steps = stepData.fold<double>(0, (sum, point) => sum + (double.tryParse(point.value.toString()) ?? 0));
      final calories = calorieData.fold<double>(0, (sum, point) => sum + (double.tryParse(point.value.toString()) ?? 0));

      return {'steps': steps, 'calories': calories};
    } catch (_) {
      return {'steps': 0, 'calories': 0};
    }
  }

  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    required HealthWorkoutActivityType type,
    double? calories,
    double? steps,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final permissionStatus = await requestPermissions();
      if (permissionStatus == HealthPermissionStatus.notGranted) {
        return false;
      }

      return await _health.writeWorkoutData(
        type,
        start,
        end,
        totalEnergyBurned: calories?.toInt(),
        totalSteps: steps?.toInt(),
      );
    } catch (_) {
      return false;
    }
  }
}

enum HealthPermissionStatus {
  granted,
  partial,
  notGranted,
}
