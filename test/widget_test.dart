import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_banking_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BankingApp());

    expect(find.byType(BankingApp), findsOneWidget);
  });
}
