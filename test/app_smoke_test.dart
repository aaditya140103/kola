import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/app/kola_app.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/progress/domain/reading_models.dart';

void main() {
  testWidgets('Kola opens the reading home', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => Stream<List<KolaDocument>>.value(
              const <KolaDocument>[],
            ),
          ),
          readingListProvider.overrideWith(
            (ref) => Stream<List<PlannedReadingItem>>.value(
              const <PlannedReadingItem>[],
            ),
          ),
          allReadingSessionsProvider.overrideWith(
            (ref) => Stream<List<ReadingSession>>.value(
              const <ReadingSession>[],
            ),
          ),
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
