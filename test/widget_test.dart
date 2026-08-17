import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/app/app.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/database/app_database.dart';

void main() {
  testWidgets('VOID app renders Readest-style minimalist topbar and library grid',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const VoidApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify search pill in Readest top bar
    expect(find.byIcon(Icons.search), findsWidgets);
    // Verify add button
    expect(find.byIcon(Icons.add), findsWidgets);
    // Verify grid view icon
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    // Verify more options menu
    expect(find.byIcon(Icons.more_horiz), findsWidgets);

    await db.close();
  });
}
