import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _mapAssetPath = 'assets/data/m1_corridor_map.json';

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
          seedColor: const Color(0xFF2A1B42),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CorridorMapScreen(),
    );
  }
}

class CorridorMapScreen extends StatefulWidget {
  const CorridorMapScreen({super.key});

  @override
  State<CorridorMapScreen> createState() => _CorridorMapScreenState();
}

class _CorridorMapScreenState extends State<CorridorMapScreen> {
  late final Future<CorridorMapData> _map = CorridorMapData.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrainRadar · карта коридора')),
      body: SafeArea(
        child: FutureBuilder<CorridorMapData>(
          future: _map,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _UnavailableMap();
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _ReadOnlyCorridorMap(data: snapshot.requireData);
          },
        ),
      ),
    );
  }
}

class _ReadOnlyCorridorMap extends StatelessWidget {
  const _ReadOnlyCorridorMap({required this.data});

  final CorridorMapData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${data.from} → ${data.to}', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const _StatusCard(
          icon: Icons.map_outlined,
          title: 'Офлайн-схема · 43 текущих остановки',
          body:
              'Только read-only маршрут M1. Нет аккаунтов, GPS, трекинга, '
              'live-поездов, ETA и расписания.',
        ),
        const SizedBox(height: 8),
        Text(
          '${data.attribution} · ${data.licence}',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          'Источник: ${data.sourceVersion}. Публичные OSM tiles не используются.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const _StatusCard(
          icon: Icons.block_outlined,
          title: 'Котляково · planned slot №8',
          body:
              'Не используется: не входит в маршрут, routing, coverage или '
              'stop patterns до отдельного решения владельца.',
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Офлайн-схема коридора: 43 текущих остановки',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 112,
              child: CustomPaint(
                painter: _RailLinePainter(stopCount: data.stops.length),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Москва-Павелецкая'),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Узуново', style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        ...data.stops.map(
          (stop) => ListTile(
            dense: true,
            leading: const Icon(Icons.circle_outlined, size: 18),
            title: Text(stop.name),
            subtitle: Text('Пункт №${stop.ordinal} · current'),
          ),
        ),
      ],
    );
  }
}

class _UnavailableMap extends StatelessWidget {
  const _UnavailableMap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: _StatusCard(
        icon: Icons.error_outline,
        title: 'Карта недоступна',
        body:
            'Офлайн-данные карты не удалось открыть. Расписание не подменяется.',
      ),
    );
  }
}

class _RailLinePainter extends CustomPainter {
  const _RailLinePainter({required this.stopCount});

  final int stopCount;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2F697F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final stopPaint = Paint()..color = const Color(0xFFFC8204);
    final y = size.height / 2;
    const inset = 12.0;
    canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), linePaint);
    for (var index = 0; index < stopCount; index++) {
      final x = inset + (size.width - 2 * inset) * index / (stopCount - 1);
      canvas.drawCircle(Offset(x, y), 3.5, stopPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RailLinePainter oldDelegate) {
    return oldDelegate.stopCount != stopCount;
  }
}

class CorridorMapData {
  const CorridorMapData({
    required this.from,
    required this.to,
    required this.sourceVersion,
    required this.licence,
    required this.attribution,
    required this.stops,
  });

  final String from;
  final String to;
  final String sourceVersion;
  final String licence;
  final String attribution;
  final List<CorridorStop> stops;

  static Future<CorridorMapData> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final decoded =
        jsonDecode(await source.loadString(_mapAssetPath))
            as Map<String, dynamic>;
    final sourceMetadata = decoded['source'] as Map<String, dynamic>;
    final corridor = decoded['corridor'] as Map<String, dynamic>;
    final stops = (decoded['stops'] as List<dynamic>)
        .map((item) => CorridorStop.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    if (stops.length != 43 ||
        stops.any((stop) => stop.id == 'tr-pu-stop-008')) {
      throw const FormatException(
        'M1 map requires exactly 43 enabled current stops',
      );
    }
    return CorridorMapData(
      from: corridor['from'] as String,
      to: corridor['to'] as String,
      sourceVersion: sourceMetadata['version'] as String,
      licence: sourceMetadata['licence'] as String,
      attribution: sourceMetadata['attribution'] as String,
      stops: stops,
    );
  }
}

class CorridorStop {
  const CorridorStop({
    required this.id,
    required this.ordinal,
    required this.name,
  });

  final String id;
  final int ordinal;
  final String name;

  factory CorridorStop.fromJson(Map<String, dynamic> json) {
    return CorridorStop(
      id: json['stop_id'] as String,
      ordinal: json['ordinal'] as int,
      name: json['canonical_name'] as String,
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
