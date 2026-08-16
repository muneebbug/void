import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

void main() {
  group('AppDatabase Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() {
      db.close();
    });

    test(
        'initializes and seeds all 3 built-in schemas (Movies, TV Shows, Books)',
        () {
      final rows = db.rawDb.select('SELECT * FROM schemas;');
      expect(rows.length, equals(3));

      final schemaIds = rows.map((r) => r['id'] as String).toSet();
      expect(schemaIds.contains(BuiltinSchemas.moviesSchemaId), isTrue);
      expect(schemaIds.contains(BuiltinSchemas.tvShowsSchemaId), isTrue);
      expect(schemaIds.contains(BuiltinSchemas.booksSchemaId), isTrue);
    });

    test('built-in schema fields are properly seeded', () {
      final rows = db.rawDb.select(
        'SELECT * FROM schema_fields WHERE schema_id = ?;',
        [BuiltinSchemas.moviesSchemaId],
      );
      expect(rows.isNotEmpty, isTrue);

      final fieldKeys = rows.map((r) => r['key'] as String).toSet();
      expect(fieldKeys.contains('director'), isTrue);
      expect(fieldKeys.contains('release_year'), isTrue);
      expect(fieldKeys.contains('rating'), isTrue);
      expect(fieldKeys.contains('genre'), isTrue);
    });
  });
}
