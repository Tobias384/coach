import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_provider.dart';
import '../../data/local/database.dart';
import '../../main.dart';
import '../../services/health_connect_service.dart';
import 'streak_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? selectedExerciseId;
  Map<String, double> healthStats = {'steps': 0, 'calories': 0};
  late Future<StreakSummary> _streakFuture;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
    _streakFuture = _loadStreak();
  }

  Future<void> _loadHealthData() async {
    final healthService = HealthConnectService();
    if (await healthService.isHealthConnectAvailable()) {
      if (await healthService.requestPermissions()) {
        final stats = await healthService.getTodayStats();
        if (mounted) {
          setState(() => healthStats = stats);
        }
      }
    }
  }

  Future<StreakSummary> _loadStreak() async {
    final db = ref.read(databaseProvider);
    final sessions = await db.workoutDao.getAllSessions();
    final dates = sessions
        .where((session) => session.endTime != null)
        .map((session) => session.endTime!)
        .toList();
    return StreakService.calculate(dates);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakCard(),
            const SizedBox(height: 16),
            _buildHealthSummary(),
            const SizedBox(height: 24),
            Text('Volumen Semanal Total', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: dashboardAsync.when(
                data: (data) => _buildVolumeChart(data['weeklyVolume']),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Progresión por Ejercicio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<List<Exercise>>(
              future: db.workoutDao.getAllExercises(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return DropdownButton<int>(
                  value: selectedExerciseId,
                  hint: const Text('Seleccionar Ejercicio'),
                  isExpanded: true,
                  items: snapshot.data!.map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedExerciseId = val),
                );
              },
            ),
            if (selectedExerciseId != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: ref.watch(exerciseProgressProvider(selectedExerciseId!)).when(
                  data: (data) => _buildProgressChart(data),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return FutureBuilder<StreakSummary>(
      future: _streakFuture,
      builder: (context, snapshot) {
        final streak = snapshot.data ?? const StreakSummary(currentStreak: 0, bestStreak: 0, isNewRecord: false, message: 'Tu primera racha empieza hoy.');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.local_fire_department, size: 28, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${streak.currentStreak} semanas seguidas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(streak.isNewRecord ? '¡Nuevo récord personal! ${streak.message}' : streak.message),
                      const SizedBox(height: 4),
                      Text('Mejor racha: ${streak.bestStreak} semanas', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Icon(Icons.directions_walk, color: Colors.blue),
                Text('${healthStats['steps']?.toInt() ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall),
                const Text('Pasos Hoy'),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text('${healthStats['calories']?.toInt() ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall),
                const Text('kcal Activas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeChart(Map<int, double> volumeData) {
    if (volumeData.isEmpty) {
      return const Center(child: Text('No hay datos de volumen todavía.'));
    }

    final sortedWeeks = volumeData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxVolume = sortedWeeks.map((entry) => entry.value).reduce((a, b) => a > b ? a : b);
    final barGroups = sortedWeeks.asMap().entries.map((entry) {
      final weekKey = entry.value.key;
      final volume = entry.value.value;
      final weekLabel = 'W${(weekKey % 100).toString().padLeft(2, '0')}';

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: volume,
            color: Theme.of(context).colorScheme.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxVolume * 1.2,
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= sortedWeeks.length) return const SizedBox.shrink();
                final weekKey = sortedWeeks[index].key;
                return Text('W${(weekKey % 100).toString().padLeft(2, '0')}');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(value.toInt().toString()),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildProgressChart(List<Map<String, dynamic>> progressData) {
    if (progressData.isEmpty) {
      return const Center(child: Text('No hay datos para este ejercicio todavía.'));
    }

    final maxWeightSpots = <FlSpot>[];
    final oneRMSpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < progressData.length; i++) {
      final item = progressData[i];
      final date = item['date'] as DateTime;
      labels.add('${date.day}/${date.month}');
      maxWeightSpots.add(FlSpot(i.toDouble(), item['maxWeight'] as double));
      oneRMSpots.add(FlSpot(i.toDouble(), item['oneRM'] as double));
    }

    final maxValue = [
      ...maxWeightSpots.map((spot) => spot.y),
      ...oneRMSpots.map((spot) => spot.y),
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxValue * 1.15,
              lineBarsData: [
                LineChartBarData(
                  spots: maxWeightSpots,
                  color: Theme.of(context).colorScheme.primary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: oneRMSpots,
                  color: Theme.of(context).colorScheme.secondary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                      return Text(labels[index]);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, _) => Text(value.toInt().toString()),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.barIndex == 0 ? 'Peso máx.' : '1RM Epley';
                      return LineTooltipItem('$label: ${spot.y.toStringAsFixed(1)} kg', const TextStyle(color: Colors.white));
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendChip(label: 'Peso máx.', color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            _LegendChip(label: '1RM Epley', color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
