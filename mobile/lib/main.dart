import 'package:flutter/material.dart';

void main() {
  runApp(const TrainRadarApp());
}

class TrainRadarApp extends StatelessWidget {
  const TrainRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainRadar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF126B59),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrainRadar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Москва-Павелецкая → Узуново',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'M0 · 44 остановочных пункта в seed registry',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const _StatusCard(
              icon: Icons.fact_check_outlined,
              title: 'Данные требуют верификации',
              body:
                  'Координаты, расписание и эксплуатационные свойства пока не '
                  'подтверждены. Это не live-карта.',
            ),
            const SizedBox(height: 12),
            const _StatusCard(
              icon: Icons.location_off_outlined,
              title: 'GPS выключен',
              body:
                  'M0 не запрашивает геолокацию и не отправляет реальные точки.',
            ),
            const SizedBox(height: 24),
            Text(
              'Будущие состояния позиции',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Официальная')),
                Chip(label: Text('Подтверждена группой')),
                Chip(label: Text('Расчётная')),
                Chip(label: Text('Связь потеряна')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, semanticLabel: title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
