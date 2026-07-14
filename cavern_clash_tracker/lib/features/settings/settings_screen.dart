import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/sync_service.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncEnabled = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Respaldo en la Nube', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          SwitchListTile(
            title: const Text('Activar respaldo en la nube'),
            subtitle: const Text('Sincroniza tus rutinas y sesiones. Los datos de salud (pasos, pulso) nunca se suben.'),
            value: _isSyncEnabled && session != null,
            onChanged: (val) async {
              if (val && session == null) {
                _showAuthDialog();
              } else {
                setState(() => _isSyncEnabled = val);
              }
            },
          ),
          if (session != null) ...[
            ListTile(
              title: const Text('Sincronizar ahora'),
              trailing: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.sync),
              onTap: _isLoading ? null : _performSync,
            ),
            ListTile(
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                setState(() => _isSyncEnabled = false);
              },
            ),
          ],
          const Divider(),
          const ListTile(
            title: Text('Privacidad'),
            subtitle: Text('Tus datos de salud solo se almacenan localmente y se comparten con Health Connect bajo tu permiso explícito.'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSync() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      await SyncService(db).syncUp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronización completada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Sesión'),
        content: const Text('Necesitas una cuenta para activar el respaldo en la nube.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              // Placeholder for actual login logic (Email/Google)
              Navigator.pop(context);
              _fakeLogin();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _fakeLogin() async {
    // This is where you'd call Supabase Auth
    setState(() => _isSyncEnabled = true);
  }
}
