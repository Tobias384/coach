import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../data/local/database.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine? routine;
  const RoutineEditorScreen({super.key, this.routine});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];
  List<Exercise> _libraryExercises = [];
  String _searchQuery = '';
  String? _filterMuscle;
  String? _filterEquipment;
  String _userRestrictions = '';

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
      _loadRoutineExercises();
    }
    _loadLibrary();
    _loadUserRestrictions();
  }

  Future<void> _loadUserRestrictions() async {
    final user = await ref.read(databaseProvider).userDao.getUser(1);
    if (user?.restrictions != null) {
      setState(() => _userRestrictions = user!.restrictions!);
    }
  }

  Future<void> _loadRoutineExercises() async {
    final exercises = await ref.read(databaseProvider).workoutDao.getExercisesForRoutine(widget.routine!.id);
    setState(() => _selectedExercises.addAll(exercises));
  }

  Future<void> _loadLibrary() async {
    final exercises = await ref.read(databaseProvider).workoutDao.getFilteredExercises(
      query: _searchQuery,
      muscle: _filterMuscle,
      equipment: _filterEquipment,
    );
    setState(() => _libraryExercises = exercises);
  }

  bool _isRecommended(Exercise ex) {
    if (_userRestrictions.isEmpty) return true;
    final restrictions = _userRestrictions.split(',');
    final muscleInvolved = ex.targetMuscles?.split(',') ?? [];
    return !muscleInvolved.any((m) => restrictions.contains(m));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine == null ? 'Nueva Rutina' : 'Editar Rutina')),
      body: Row(
        children: [
          // Library Side
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Buscar Ejercicio', prefixIcon: Icon(Icons.search)),
                    onChanged: (val) {
                      _searchQuery = val;
                      _loadLibrary();
                    },
                  ),
                ),
                // Filters (Simplified)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DropdownButton<String>(
                          value: _filterMuscle,
                          hint: const Text('Músculo'),
                          items: ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps', 'Tríceps'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) { setState(() => _filterMuscle = val); _loadLibrary(); },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _libraryExercises.length,
                    itemBuilder: (context, index) {
                      final ex = _libraryExercises[index];
                      final recommended = _isRecommended(ex);
                      return Draggable<Exercise>(
                        data: ex,
                        feedback: Material(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.blue,
                            child: Text(ex.name),
                          ),
                        ),
                        child: ListTile(
                          title: Text(ex.name, style: TextStyle(color: recommended ? null : Colors.red[300])),
                          subtitle: Text('${ex.targetMuscles} - ${ex.equipment}'),
                          trailing: recommended ? null : const Icon(Icons.warning, color: Colors.orange),
                          onTap: () => setState(() => _selectedExercises.add(ex)), // Also allow tap
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // Routine Side
          Expanded(
            flex: 3,
            child: DragTarget<Exercise>(
              onAccept: (ex) => setState(() => _selectedExercises.add(ex)),
              builder: (context, candidateData, rejectedData) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nombre de la Rutina'),
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _selectedExercises.removeAt(oldIndex);
                            _selectedExercises.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < _selectedExercises.length; i++)
                            ListTile(
                              key: ValueKey('${_selectedExercises[i].id}_$i'),
                              leading: const Icon(Icons.drag_handle),
                              title: Text(_selectedExercises[i].name),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => setState(() => _selectedExercises.removeAt(i)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        int rId;
                        if (widget.routine == null) {
                          rId = await db.workoutDao.createRoutine(RoutinesCompanion(
                            name: Value(_nameController.text),
                          ));
                        } else {
                          rId = widget.routine!.id;
                          await db.workoutDao.deleteRoutineExercises(rId);
                        }

                        for (int i = 0; i < _selectedExercises.length; i++) {
                          await db.workoutDao.addRoutineExercise(RoutineExercisesCompanion(
                            routineId: Value(rId),
                            exerciseId: Value(_selectedExercises[i].id),
                            orderIndex: Value(i),
                          ));
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Guardar Rutina'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
