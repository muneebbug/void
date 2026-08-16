import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/features/schemas/domain/schema.dart';

final schemasStreamProvider = StreamProvider<List<Schema>>((ref) {
  final repo = ref.watch(schemaRepositoryProvider);
  return repo.watchSchemas();
});

final schemaDetailProvider = FutureProvider.family<Schema?, String>((ref, id) {
  final repo = ref.watch(schemaRepositoryProvider);
  return repo.getSchemaById(id);
});
