import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:rbp_flutter/ui/widgets/stat_card.dart';

void main() {
  testWidgets('renders stat card values', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Disponible',
            value: 'RD\$1,250.00',
            icon: Icons.check_circle,
          ),
        ),
      ),
    );
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('RD\$1,250.00'), findsOneWidget);
  });
}
