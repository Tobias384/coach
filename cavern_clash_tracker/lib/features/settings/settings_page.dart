import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../features/paywall/paywall_page.dart';
import '../../services/sync_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSyncEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSyncEnabled = Supabase.instance.client.auth.currentSession != null;
  }

  Future<void> _performSync() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      await SyncService(db).syncUp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronización completada')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo sincronizar: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fakeLogin() async {
    setState(() => _isSyncEnabled = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo de respaldo activado. Usa Sincronizar ahora para subir tus datos.')));
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respaldar en la nube'),
        content: const Text('Esta opción solo sincroniza perfil, rutinas y sesiones. Nunca sube datos de Health Connect sin tu autorización explícita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            _fakeLogin();
          }, child: const Text('Activar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Respaldar en la nube'),
            subtitle: const Text('Sincronización manual de perfil, rutinas y sesiones de entrenamiento.'),
            value: _isSyncEnabled && session != null,
            onChanged: (value) {
              if (value) {
                _showAuthDialog();
              } else {
                setState(() => _isSyncEnabled = false);
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Sincronizar ahora'),
            subtitle: const Text('Sube perfil, rutinas y sesiones; no se envían datos de salud.'),
            trailing: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _performSync,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Coach Premium'),
            subtitle: const Text('Ver planes y desbloquear Coach IA, temas visuales y respaldo en la nube.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage())),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puedes seguir usando la app sin cuenta. Si quieres, crea una más adelante para activar el respaldo en la nube.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Política de privacidad', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Solo se sincronizan perfil, rutinas y sesiones de entrenamiento. Los datos de Health Connect no se suben a un servidor sin autorización explícita del usuario.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
