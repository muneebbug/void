import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/theme/app_theme.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/view_options_menu.dart';

void main() {
  group('View Options Menu & Layout Tests', () {
    testWidgets('ViewOptionsMenu renders List, Grid, Columns, and Auto controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ViewOptionsMenu(
                currentCollection: null,
                isAllListsPage: true,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify List, Grid, Columns, Auto
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);

      // Verify Edit List and Delete List are NOT present on homepage
      expect(find.text('Edit List'), findsNothing);
      expect(find.text('Delete List'), findsNothing);
    });

    testWidgets('ViewOptionsMenu shows Edit List & Delete List when on a collection page',
        (WidgetTester tester) async {
      final sampleCollection = Collection(
        id: 'col_test_1',
        name: 'Sci-Fi Movies',
        schemaId: BuiltinSchemas.moviesSchemaId,
        icon: 'movie',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ViewOptionsMenu(
                currentCollection: sampleCollection,
                isAllListsPage: false,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify all items including Edit List and Delete List
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Edit List'), findsOneWidget);
      expect(find.text('Delete List'), findsOneWidget);
    });

    test('SettingsProvider updates ViewMode, GridColumns and Auto correctly', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // Default state
      expect(
        container.read(settingsProvider).defaultViewMode,
        equals(ItemViewMode.grid),
      );
      expect(container.read(settingsProvider).gridColumns, isNull);

      // Set to list view
      await container
          .read(settingsProvider.notifier)
          .setViewMode(ItemViewMode.list);
      expect(
        container.read(settingsProvider).defaultViewMode,
        equals(ItemViewMode.list),
      );

      // Set custom columns
      await container.read(settingsProvider.notifier).setGridColumns(4);
      expect(container.read(settingsProvider).gridColumns, equals(4));

      // Attempt setting below minimum 3 -> clamps to 3
      await container.read(settingsProvider.notifier).setGridColumns(1);
      expect(container.read(settingsProvider).gridColumns, equals(3));

      // Reset to Auto
      await container.read(settingsProvider.notifier).setGridColumns(null);
      expect(container.read(settingsProvider).gridColumns, isNull);

      container.dispose();
      db.close();
    });
  });
}
