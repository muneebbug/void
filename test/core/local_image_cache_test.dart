import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/services/local_image_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalImageCacheService Tests', () {
    late LocalImageCacheService cacheService;
    late Directory tempDir;

    setUp(() async {
      cacheService = LocalImageCacheService.instance;
      tempDir = await Directory.systemTemp.createTemp('void_cache_test_');
    });

    tearDown(() async {
      await cacheService.clearCache();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Memory cache store and retrieval works', () async {
      const url = 'https://example.com/poster.jpg';
      expect(cacheService.getMemoryCached(url), isNull);

      // Local file caching test
      final sampleFile = File('${tempDir.path}/sample.png');
      await sampleFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));

      final loadedBytes = await cacheService.loadImageBytes(sampleFile.path);
      expect(loadedBytes, isNotNull);
      expect(loadedBytes!.length, equals(4));

      // Check memory cache has it
      final memoryBytes = cacheService.getMemoryCached(sampleFile.path);
      expect(memoryBytes, isNotNull);
      expect(memoryBytes, equals(loadedBytes));
    });

    test('Empty or null URL handling returns null safely', () async {
      expect(await cacheService.loadImageBytes(''), isNull);
      expect(await cacheService.loadImageBytes('   '), isNull);
      expect(await cacheService.getLocalFile(''), isNull);
    });

    test('Direct file:// URI resolution works', () async {
      final sampleFile = File('${tempDir.path}/local_cover.jpg');
      await sampleFile.writeAsBytes(Uint8List.fromList([10, 20, 30]));

      final fileUri = sampleFile.uri.toString();
      final localFile = await cacheService.getLocalFile(fileUri);
      expect(localFile, isNotNull);
      expect(await localFile!.exists(), isTrue);

      final bytes = await cacheService.loadImageBytes(fileUri);
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(3));
    });
  });
}
