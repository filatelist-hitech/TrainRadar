import 'package:flutter_test/flutter_test.dart';
import 'package:trainradar_mobile/main.dart';

void main() {
  testWidgets('M0 shell exposes pending data and disabled GPS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TrainRadarApp());

    expect(find.text('Москва-Павелецкая → Узуново'), findsOneWidget);
    expect(find.textContaining('44 остановочных пункта'), findsOneWidget);
    expect(find.text('Данные требуют верификации'), findsOneWidget);
    expect(find.text('GPS выключен'), findsOneWidget);
    expect(find.text('Расчётная'), findsOneWidget);
  });
}
