import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'training_provider.dart';
import '../../core/providers.dart';
import '../../data/local/database.dart';

class ActiveTrainingScreen extends ConsumerWidget {
  const ActiveTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingState = ref.watch(trainingNotifierProvider);
    final notifier = ref.read(trainingNotifierProvider.notifier);

    if (trainingState.activeSession == null) {
      return const RoutineSelectionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento activo'),
        actions: [
          IconButton(
            onPressed: () async {
              await notifier.finishTraining();
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.check_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (trainingState.isResting)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Descanso: ${trainingState.restTimerSeconds ?? 0}s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: notifier.stopRestTimer,
                    child: const Text('Omitir'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trainingState.currentExercises.length,
              itemBuilder: (context, index) {
                final exercise = trainingState.currentExercises[index];
                return ExerciseTrainingCard(exercise: exercise);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseTrainingCard extends ConsumerStatefulWidget {
  final Exercise exercise;
  const ExerciseTrainingCard({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseTrainingCard> createState() => _ExerciseTrainingCardState();
}

class _ExerciseTrainingCardState extends ConsumerState<ExerciseTrainingCard> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _perSideController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _repsFocusNode = FocusNode();
  bool _isSaving = false;
  bool _isSavingNote = false;
  bool _usePerSide = false;

  @override
  void initState() {
    super.initState();
    _loadLastSet();
    _loadExerciseNote();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _perSideController.dispose();
    _noteController.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLastSet() async {
    final lastSet = await ref.read(lastExerciseSetProvider(widget.exercise.id).future);
    if (!mounted) return;

    setState(() {
      if (lastSet != null) {
        _weightController.text = lastSet.weight.toString();
        _repsController.text = lastSet.reps.toString();
      } else {
        _weightController.clear();
        _repsController.clear();
      }
    });
  }

  Future<void> _loadExerciseNote() async {
    final note = await ref.read(databaseProvider).workoutDao.getExerciseNote(widget.exercise.id);
    if (!mounted) return;
    setState(() => _noteController.text = note ?? '');
  }

  Future<void> _saveExerciseNote() async {
    setState(() => _isSavingNote = true);
    try {
      await ref.read(databaseProvider).workoutDao.saveExerciseNote(widget.exercise.id, _noteController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota guardada')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar la nota: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNote = false);
      }
    }
  }

  Future<void> _saveSet() async {
    final db = ref.read(databaseProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final profile = currentUser == null ? null : await db.userDao.getCurrentUser(currentUser.id);
    final barbellWeight = profile?.barbellWeightKg ?? 20.0;

    final reps = int.tryParse(_repsController.text);
    final weight = _usePerSide
        ? (barbellWeight + ((double.tryParse(_perSideController.text) ?? 0) * 2))
        : (double.tryParse(_weightController.text));

    if (weight == null || reps == null || weight <= 0 || reps <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Introduce peso y repeticiones válidos.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(trainingNotifierProvider.notifier).addSet(widget.exercise.id, weight, reps);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serie guardada'), duration: Duration(seconds: 1)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastSetAsync = ref.watch(lastExerciseSetProvider(widget.exercise.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Notas persistentes', style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Asiento, rack, posición, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isSavingNote ? null : _saveExerciseNote,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar nota'),
                    ),
                  ),
                ],
              ),
            ),
            Text(widget.exercise.name, style: Theme.of(context).textTheme.titleMedium),
            if (widget.exercise.targetMuscles != null && widget.exercise.targetMuscles!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.exercise.targetMuscles!, style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Peso total')),
                      ButtonSegment(value: true, label: Text('Por lado')),
                    ],
                    selected: {_usePerSide},
                    onSelectionChanged: (value) => setState(() => _usePerSide = value.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_usePerSide)
              TextField(
                controller: _perSideController,
                decoration: InputDecoration(labelText: 'Peso por disco por lado (kg)', hintText: 'Ej. 10'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_repsFocusNode),
              )
            else
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso total (kg)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_repsFocusNode),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _repsController,
              focusNode: _repsFocusNode,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveSet(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: lastSetAsync.when(
                    data: (lastSet) {
                      final label = lastSet == null
                          ? 'Sin registros previos'
                          : 'Último: ${lastSet.weight.toStringAsFixed(1)} kg × ${lastSet.reps} reps';
                      return Text(label, style: Theme.of(context).textTheme.bodySmall);
                    },
                    loading: () => const Text('Cargando último registro...'),
                    error: (error, _) => Text('Error: $error'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSet,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineSelectionScreen extends ConsumerWidget {
  const RoutineSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar rutina')),
      body: FutureBuilder<List<Routine>>(
        future: db.workoutDao.getAllRoutines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final routines = snapshot.data!;

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Todavía no hay rutinas creadas.'),
                  const SizedBox(height: 12),
                  Text('Crea una rutina en la pantalla de rutinas para comenzar.', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Card(
                child: ListTile(
                  title: Text(routine.name),
                  subtitle: Text(routine.description ?? 'Sin descripción'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await ref.read(trainingNotifierProvider.notifier).startTraining(routine);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
