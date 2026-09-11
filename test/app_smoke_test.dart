import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/app/kola_app.dart';
import 'package:kola/core/database/database_provider.dart';
import 'package:kola/core/database/kola_database.dart';

void main() {
  testWidgets('Kola opens the reading home', (WidgetTester tester) async {
    final KolaDatabase database = KolaDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          kolaDatabaseProvider.overrideWithValue(database),
        ],
        child: const KolaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your reading space'), findsWidgets);
    expect(find.text('Continue reading'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
  });
}
