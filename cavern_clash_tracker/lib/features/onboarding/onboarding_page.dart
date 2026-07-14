import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _barbellWeightController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _injuriesController = TextEditingController();
  final TextEditingController _restrictionsController = TextEditingController();
  bool _isSaving = false;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _barbellWeightController.dispose();
    _goalController.dispose();
    _injuriesController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final db = ref.read(databaseProvider);
    final sessionUser = Supabase.instance.client.auth.currentUser;
    final user = sessionUser == null ? null : await db.userDao.getCurrentUser(sessionUser.id);
    if (!mounted) return;
    setState(() {
      _nameController.text = user?.username ?? 'Usuario';
      _emailController.text = user?.email ?? '';
      _weightController.text = user?.weightKg?.toString() ?? '';
      _heightController.text = user?.heightCm?.toString() ?? '';
      _barbellWeightController.text = user?.barbellWeightKg?.toString() ?? '20';
      _goalController.text = user?.goal ?? '';
      _injuriesController.text = user?.injuries ?? '';
      _restrictionsController.text = user?.restrictions ?? '';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final auth = Supabase.instance.client.auth;
      final db = ref.read(databaseProvider);
      final currentUser = auth.currentUser;

      if (currentUser == null && email.isEmpty && password.isEmpty) {
        await db.userDao.saveProfile(
          authUserId: 'local-anonymous',
          username: _nameController.text.trim().isEmpty ? 'Usuario' : _nameController.text.trim(),
          email: null,
          weightKg: double.tryParse(_weightController.text.trim()),
          heightCm: double.tryParse(_heightController.text.trim()),
          barbellWeightKg: double.tryParse(_barbellWeightController.text.trim()) ?? 20,
          goal: _goalController.text.trim(),
          injuries: _injuriesController.text.trim(),
          restrictions: _restrictionsController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo local activado. Puedes seguir entrenando sin cuenta.')));
          context.go('/dashboard');
        }
        return;
      }

      if (currentUser == null) {
        final response = _isLogin
            ? await auth.signInWithPassword(email: email, password: password)
            : await auth.signUp(email: email, password: password);
        if (response.user == null) {
          throw Exception('No se pudo autenticar con Supabase');
        }
      }

      final authUser = auth.currentUser;
      if (authUser == null) {
        throw Exception('No se encontró un usuario autenticado');
      }

      await db.userDao.saveProfile(
        authUserId: authUser.id,
        username: _nameController.text.trim().isEmpty ? 'Usuario' : _nameController.text.trim(),
        email: email,
        weightKg: double.tryParse(_weightController.text.trim()),
        heightCm: double.tryParse(_heightController.text.trim()),
        barbellWeightKg: double.tryParse(_barbellWeightController.text.trim()) ?? 20,
        goal: _goalController.text.trim(),
        injuries: _injuriesController.text.trim(),
        restrictions: _restrictionsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        context.go('/dashboard');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y restricciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => _isLogin = true),
                    child: const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isLogin = false),
                    child: const Text('Crear cuenta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Altura (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barbellWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Peso de barra habitual (kg)', hintText: 'Por defecto 20'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: 'Objetivo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _injuriesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Lesiones o limitaciones'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restrictionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Restricciones o lesiones',
                hintText: 'Ej. Rodillas, Espalda Baja, Hombros',
              ),
            ),
            const SizedBox(height: 16),
            Text('Se ocultarán o marcarán como no recomendados los ejercicios que involucren alguna zona escrita aquí.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isLogin ? 'Iniciar sesión y guardar perfil' : 'Crear cuenta y guardar perfil'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : () async {
                final db = ref.read(databaseProvider);
                await db.userDao.saveProfile(
                  authUserId: 'local-anonymous',
                  username: _nameController.text.trim().isEmpty ? 'Usuario' : _nameController.text.trim(),
                  email: null,
                  weightKg: double.tryParse(_weightController.text.trim()),
                  heightCm: double.tryParse(_heightController.text.trim()),
                  barbellWeightKg: double.tryParse(_barbellWeightController.text.trim()) ?? 20,
                  goal: _goalController.text.trim(),
                  injuries: _injuriesController.text.trim(),
                  restrictions: _restrictionsController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo local activado. Puedes probar la app sin cuenta.')));
                context.go('/dashboard');
              },
              icon: const Icon(Icons.directions_run_outlined),
              label: const Text('Probar sin cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
