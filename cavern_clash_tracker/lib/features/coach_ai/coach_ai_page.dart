import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/providers.dart';

class CoachAiPage extends ConsumerStatefulWidget {
  const CoachAiPage({super.key});

  @override
  ConsumerState<CoachAiPage> createState() => _CoachAiPageState();
}

class _CoachAiPageState extends ConsumerState<CoachAiPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: prompt));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final db = ref.read(databaseProvider);
      final allSets = await db.workoutDao.getAllSetEntries();
      final recentHistory = allSets.take(20).map((set) {
        return {
          'exerciseId': set.exerciseId,
          'weight': set.weight,
          'reps': set.reps,
          'performedAt': set.performedAt.toIso8601String(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('https://YOUR_SUPABASE_PROJECT_REF.functions.supabase.co/coach-ai/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'history': recentHistory, 'question': prompt}),
      );

      if (!response.ok) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final recommendation = data['recommendation']?.toString();
      final reasoning = data['reasoning']?.toString();
      final advice = recommendation != null && reasoning != null
          ? 'Recomendación: $recommendation\n\nPor qué: $reasoning'
          : data['advice']?.toString() ?? 'No he podido generar una recomendación.';

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', text: advice));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', text: 'No he podido contactar con Coach AI. Revisa la configuración del endpoint.'));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                final message = _messages[index];
                final isUser = message.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.only(bottom: 12), child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Escribe una pregunta o un objetivo'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _isLoading ? null : _sendMessage, icon: const Icon(Icons.send), label: const Text('Enviar')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;

  const _ChatMessage({required this.role, required this.text});
}
