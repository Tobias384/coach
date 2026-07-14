import 'package:flutter/material.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 28),
                        const SizedBox(width: 8),
                        Text('Desbloquea más potencia', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El plan gratuito siempre incluye registro ilimitado de series, historial completo y seguimiento de entrenamientos. Solo Coach IA conversacional, algunos temas visuales y el respaldo en la nube quedan detrás del muro de pago.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PlanCard(
              title: 'Mensual',
              price: '4,99 €/mes',
              description: 'Ideal para probar el modo premium con flexibilidad.',
              accent: true,
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Anual',
              price: '39,99 €/año',
              description: 'Ahorra con el descuento anual marcado.',
              badge: 'Ahorro del 30%',
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Pago único de por vida',
              price: '79,99 €',
              description: 'Acceso completo sin suscripciones recurrentes.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final bool accent;
  final String? badge;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    this.accent = false,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accent ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!, style: Theme.of(context).textTheme.labelSmall),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 8),
                  Text(price, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: () {}, child: const Text('Elegir')),
          ],
        ),
      ),
    );
  }
}
