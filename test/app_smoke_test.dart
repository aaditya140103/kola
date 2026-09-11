import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/app/kola_app.dart';

void main() {
  testWidgets('Kola opens the reading home', (WidgetTester tester) async {
    await tester.pumpWidget(const KolaApp());
    await tester.pumpAndSettle();

    expect(find.text('Your reading space'), findsOneWidget);
    expect(find.text('Continue reading'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
  });
}
