import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../data/local/database.dart';

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _photoPath;
  List<Map<String, dynamic>> _entries = [];
  Map<String, double> _dailySummary = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final db = ref.read(databaseProvider);
    final rows = await db.getNutritionEntriesForDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _entries = rows;
      _dailySummary = _summarizeEntries(rows);
    });
  }

  Map<String, double> _summarizeEntries(List<Map<String, dynamic>> rows) {
    final summary = {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    for (final row in rows) {
      summary['calories'] = summary['calories']! + _asDouble(row['calories']);
      summary['protein'] = summary['protein']! + _asDouble(row['protein_g']);
      summary['carbs'] = summary['carbs']! + _asDouble(row['carbs_g']);
      summary['fat'] = summary['fat']! + _asDouble(row['fat_g']);
    }
    return summary;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Future<void> _showSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Seleccionar de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    await _analyzePhoto(source);
  }

  Future<void> _analyzePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1400);
    if (pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _photoPath = pickedFile.path;
    });

    try {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final imageBase64 = base64Encode(bytes);
      final mimeType = pickedFile.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      final response = await Supabase.instance.client.functions.invoke('analyze-food', body: {
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'prompt': 'Analiza la comida de la foto y estima el nombre, calorías y macronutrientes. Devuelve JSON válido con foodName, calories, protein, carbs, fat, confidence y reasoning.',
      });

      final payload = response.data;
      Map<String, dynamic>? data;
      if (payload is Map) {
        data = Map<String, dynamic>.from(payload);
      }

      if (data == null || data.isEmpty) {
        throw Exception('La respuesta del análisis no llegó en el formato esperado.');
      }

      _mealNameController.text = (data['foodName'] ?? 'Comida detectada').toString();
      _caloriesController.text = (_asDouble(data['calories'])).toStringAsFixed(0);
      _proteinController.text = (_asDouble(data['protein'])).toStringAsFixed(0);
      _carbsController.text = (_asDouble(data['carbs'])).toStringAsFixed(0);
      _fatController.text = (_asDouble(data['fat'])).toStringAsFixed(0);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimación preparada. Revisa los valores y guarda si todo encaja.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo analizar la imagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveEntry() async {
    final mealName = _mealNameController.text.trim();
    if (mealName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade un nombre para la comida.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      await db.insertNutritionEntry(
        mealName: mealName,
        calories: double.tryParse(_caloriesController.text) ?? 0,
        proteinG: double.tryParse(_proteinController.text) ?? 0,
        carbsG: double.tryParse(_carbsController.text) ?? 0,
        fatG: double.tryParse(_fatController.text) ?? 0,
        photoPath: _photoPath,
        source: 'photo',
      );
      await _loadEntries();
      if (!mounted) return;
      _mealNameController.clear();
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      setState(() => _photoPath = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrada guardada en tu historial local.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar la entrada: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrición')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(label: 'Calorías', value: '${_dailySummary['calories']!.toStringAsFixed(0)} kcal'),
                        _SummaryChip(label: 'Proteína', value: '${_dailySummary['protein']!.toStringAsFixed(0)} g'),
                        _SummaryChip(label: 'Carbs', value: '${_dailySummary['carbs']!.toStringAsFixed(0)} g'),
                        _SummaryChip(label: 'Grasas', value: '${_dailySummary['fat']!.toStringAsFixed(0)} g'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isAnalyzing ? null : _showSourcePicker,
              icon: _isAnalyzing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_outlined),
              label: Text(_isAnalyzing ? 'Analizando...' : 'Tomar o subir foto de comida'),
            ),
            const SizedBox(height: 16),
            if (_photoPath != null)
              Card(
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Revisa los datos estimados y corrige lo que haga falta antes de guardar.', style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resultado editable', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mealNameController,
                      decoration: const InputDecoration(labelText: 'Alimento o plato'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Calorías (kcal)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proteinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Proteína (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Carbs (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Grasas (g)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveEntry,
                        icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar entrada'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Entradas recientes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Todavía no tienes entradas de nutrición hoy. Sube una foto para empezar.', style: theme.textTheme.bodyMedium),
                ),
              )
            else
              ..._entries.map((entry) {
                final createdAt = entry['created_at']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(entry['meal_name']?.toString() ?? 'Comida'),
                    subtitle: Text('$createdAt • ${entry['calories']} kcal • P ${entry['protein_g']}g / C ${entry['carbs_g']}g / G ${entry['fat_g']}g'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
