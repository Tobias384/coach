import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../data/local/database.dart';

class CoachAIScreen extends ConsumerStatefulWidget {
  const CoachAIScreen({super.key});

  @override
  ConsumerState<CoachAIScreen> createState() => _CoachAIScreenState();
}

class _CoachAIScreenState extends ConsumerState<CoachAIScreen> {
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _getAIAdvice() async {
    setState(() => _isLoading = true);
    _messages.add({'role': 'user', 'content': 'Analiza mi progreso y dame consejos.'});

    try {
      final db = ref.read(databaseProvider);
      final allSets = await db.workoutDao.getAllSetEntries();
      final allEx = await db.workoutDao.getAllExercises();

      // Resumen del historial
      final historySummary = allSets.take(20).map((s) {
        final exName = allEx.firstWhere((e) => e.id == s.exerciseId).name;
        return '${s.performedAt.toIso8601String().substring(0, 10)}: $exName ${s.weight}kg x ${s.reps}';
      }).toList();

      final response = await http.post(
        Uri.parse('https://YOUR_SUPABASE_PROJECT_ID.functions.supabase.co/coach_ai'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_ANON_KEY', // Opcional dependiendo de la config de Supabase
        },
        body: jsonEncode({'history': historySummary}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({'role': 'assistant', 'content': data['advice']});
        });
      } else {
        throw Exception('Error en la API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Lo siento, hubo un error al conectar con el Coach AI. Verifica tu conexión.'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[900] : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    child: Text(m['content']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _getAIAdvice,
              icon: const Icon(Icons.psychology),
              label: const Text('Pedir consejo al Coach AI'),
            ),
          ),
        ],
      ),
    );
  }
}
