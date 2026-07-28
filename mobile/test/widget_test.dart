import 'package:flutter_test/flutter_test.dart';
import 'package:trainradar_mobile/main.dart';

void main() {
  testWidgets('M1 map stays read-only and shows ODbL attribution', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TrainRadarApp());
    await tester.pumpAndSettle();

    expect(find.text('Москва-Павелецкая → Узуново'), findsOneWidget);
    expect(find.text('Офлайн-схема · 43 текущих остановки'), findsOneWidget);
    expect(find.textContaining('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('ODbL 1.0'), findsOneWidget);
    expect(find.text('Котляково · planned slot №8'), findsOneWidget);
    expect(
      find.textContaining('live-поездов, ETA и расписания'),
      findsOneWidget,
    );
  });
}
