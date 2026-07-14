import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../data/local/database.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<String> muscleGroups = ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps', 'Tríceps', 'Rodillas', 'Espalda Baja'];
  final Set<String> selectedRestrictions = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final db = ref.read(databaseProvider);
    final user = await db.userDao.getUser(1); // Default user
    if (user == null) {
      await db.userDao.createUser(const UsersCompanion(username: Value('Usuario')));
    } else if (user.restrictions != null) {
      setState(() {
        selectedRestrictions.addAll(user.restrictions!.split(','));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configura tus Restricciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Selecciona zonas con lesiones o restricciones:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: muscleGroups.map((group) {
                final isSelected = selectedRestrictions.contains(group);
                return FilterChip(
                  label: Text(group),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) selectedRestrictions.add(group);
                      else selectedRestrictions.remove(group);
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await db.userDao.updateRestrictions(1, selectedRestrictions.join(','));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar y Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
