import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/local/database.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  List<Routine> _routines = [];
  List<Exercise> _libraryExercises = [];
  List<Exercise> _selectedExercises = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _search = '';
  String? _muscleFilter;
  String? _equipmentFilter;
  String _userRestrictions = '';
  int? _editingRoutineId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final routines = await db.workoutDao.getAllRoutines();
    final user = await db.userDao.getUser(1);
    final exercises = await db.workoutDao.getFilteredExercises(
      query: _search,
      muscle: _muscleFilter,
      equipment: _equipmentFilter,
    );

    if (!mounted) return;

    setState(() {
      _routines = routines;
      _libraryExercises = exercises;
      _userRestrictions = user?.restrictions ?? '';
    });
  }

  Future<void> _loadLibrary() async {
    final db = ref.read(databaseProvider);
    final exercises = await db.workoutDao.getFilteredExercises(
      query: _search,
      muscle: _muscleFilter,
      equipment: _equipmentFilter,
    );
    if (!mounted) return;
    setState(() => _libraryExercises = exercises);
  }

  Future<void> _createOrUpdateRoutine() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    final db = ref.read(databaseProvider);

    try {
      final routineId = _editingRoutineId ?? await db.workoutDao.createRoutine(
        RoutinesCompanion(
          name: drift.Value(_nameController.text.trim()),
          description: drift.Value(_descriptionController.text.trim()),
        ),
      );

      await db.workoutDao.deleteRoutineExercises(routineId);
      for (var i = 0; i < _selectedExercises.length; i++) {
        await db.workoutDao.addRoutineExercise(RoutineExercisesCompanion(
          routineId: drift.Value(routineId),
          exerciseId: drift.Value(_selectedExercises[i].id),
          orderIndex: drift.Value(i),
        ));
      }

      if (_editingRoutineId != null) {
        await db.workoutDao.deleteRoutineExercises(routineId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingRoutineId == null ? 'Rutina creada' : 'Rutina actualizada')),
      );
      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedExercises = [];
        _editingRoutineId = null;
      });
      await _loadData();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadRoutineForEdit(Routine routine) async {
    final db = ref.read(databaseProvider);
    final exercises = await db.workoutDao.getExercisesForRoutine(routine.id);
    if (!mounted) return;
    setState(() {
      _editingRoutineId = routine.id;
      _nameController.text = routine.name;
      _descriptionController.text = routine.description ?? '';
      _selectedExercises = exercises;
    });
  }

  bool _isRecommended(Exercise exercise) {
    if (_userRestrictions.isEmpty) return true;
    final restrictions = _userRestrictions.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    final muscles = (exercise.targetMuscles ?? '').split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    return muscles.every((muscle) => !restrictions.contains(muscle));
  }

  Future<void> _applyTemplate(String title) async {
    final db = ref.read(databaseProvider);
    final templateExercises = <String, List<String>>{
      'Push/Pull/Legs': ['Press de Banca', 'Remo con Barra', 'Sentadilla', 'Press Militar', 'Dominadas', 'Zancadas'],
      'Full Body 3 Días': ['Sentadilla', 'Press de Banca', 'Peso Muerto', 'Press Militar', 'Remo con Barra', 'Curl de Bíceps'],
      'Upper/Lower': ['Press de Banca', 'Remo con Barra', 'Sentadilla', 'Press Militar', 'Dominadas', 'Peso Muerto'],
      'Pecho/Espalda': ['Press de Banca', 'Aperturas de Pecho', 'Dominadas', 'Remo con Barra'],
      'Piernas/Fuerza': ['Sentadilla', 'Peso Muerto', 'Zancadas', 'Curl de Bíceps'],
    };

    final selected = templateExercises[title];
    if (selected == null) return;

    final match = await db.workoutDao.getAllExercises();
    final resolved = selected.whereType<String>().map((name) {
      return match.firstWhere((exercise) => exercise.name == name, orElse: () => match.first);
    }).toList();

    setState(() {
      _selectedExercises = resolved;
      _nameController.text = title;
      _descriptionController.text = 'Plantilla predefinida';
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final library = _libraryExercises.where((exercise) => _isRecommended(exercise) || _muscleFilter != null || _equipmentFilter != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la rutina'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'Push/Pull/Legs',
              'Full Body 3 Días',
              'Upper/Lower',
              'Pecho/Espalda',
              'Piernas/Fuerza',
            ].map((template) => ActionChip(label: Text(template), onPressed: () => _applyTemplate(template))).toList(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Buscar ejercicio'),
                    onChanged: (value) {
                      _search = value;
                      _loadLibrary();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _muscleFilter,
                  hint: const Text('Músculo'),
                  items: ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps', 'Tríceps']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _muscleFilter = value);
                    _loadLibrary();
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _equipmentFilter,
                  hint: const Text('Equipo'),
                  items: ['Barra', 'Mancuernas', 'Polea', 'Cuerpo']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _equipmentFilter = value);
                    _loadLibrary();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Text('Biblioteca'),
                            const Spacer(),
                            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLibrary),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: library.length,
                          itemBuilder: (context, index) {
                            final exercise = library[index];
                            final recommended = _isRecommended(exercise);
                            return Draggable<Exercise>(
                              data: exercise,
                              feedback: Material(
                                elevation: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(exercise.name),
                                ),
                              ),
                              child: ListTile(
                                title: Text(exercise.name, style: TextStyle(color: recommended ? null : Colors.orangeAccent)),
                                subtitle: Text('${exercise.targetMuscles ?? '-'} • ${exercise.equipment ?? '-'}'),
                                trailing: recommended ? null : const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                                onTap: () => setState(() => _selectedExercises.add(exercise)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Text('Tu rutina'),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _isSaving ? null : _createOrUpdateRoutine,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(_editingRoutineId == null ? 'Guardar' : 'Actualizar'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: DragTarget<Exercise>(
                          onAccept: (exercise) => setState(() => _selectedExercises.add(exercise)),
                          builder: (context, _, __) {
                            if (_selectedExercises.isEmpty) {
                              return const Center(child: Text('Arrastra ejercicios aquí para construir tu rutina.'));
                            }

                            return ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final item = _selectedExercises.removeAt(oldIndex);
                                  _selectedExercises.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (var i = 0; i < _selectedExercises.length; i++)
                                  ListTile(
                                    key: ValueKey('${_selectedExercises[i].id}_$i'),
                                    title: Text(_selectedExercises[i].name),
                                    subtitle: Text(_selectedExercises[i].targetMuscles ?? '-'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => setState(() => _selectedExercises.removeAt(i)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Routine>>(
            future: db.workoutDao.getAllRoutines(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final routine = snapshot.data![index];
                    return Card(
                      child: SizedBox(
                        width: 180,
                        child: ListTile(
                          title: Text(routine.name),
                          subtitle: Text(routine.description ?? ''),
                          onTap: () => _loadRoutineForEdit(routine),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
