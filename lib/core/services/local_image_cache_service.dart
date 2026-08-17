import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:void_app/core/utils/logger.dart';

/// High-performance disk and memory image cache service for VOID.
/// Persists all media posters locally so they load instantaneously offline.
class LocalImageCacheService {
  static LocalImageCacheService? _instance;
  static LocalImageCacheService get instance =>
      _instance ??= LocalImageCacheService._();

  LocalImageCacheService._();

  Directory? _cacheDir;
  final Map<String, Uint8List> _memoryCache = {};
  final Set<String> _pendingDownloads = {};

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'media_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  /// Converts a URL into a safe, deterministic 32-character hexadecimal filename.
  String _generateFilename(String url) {
    var hash1 = 0x811c9dc5;
    var hash2 = 0x55555555;
    final bytes = utf8.encode(url);
    for (final b in bytes) {
      hash1 = ((hash1 ^ b) * 0x01000193) & 0xFFFFFFFF;
      hash2 = ((hash2 ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    final hex1 = hash1.toRadixString(16).padLeft(8, '0');
    final hex2 = hash2.toRadixString(16).padLeft(8, '0');
    final lengthHex = bytes.length.toRadixString(16).padLeft(4, '0');
    final safeExt = _extractExtension(url);
    return 'cache_${hex1}_${hex2}_$lengthHex$safeExt';
  }

  String _extractExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final ext = p.extension(uri.path).toLowerCase();
      if (ext == '.jpg' ||
          ext == '.jpeg' ||
          ext == '.png' ||
          ext == '.webp' ||
          ext == '.gif') {
        return ext;
      }
    } catch (_) {}
    return '.img';
  }

  /// Returns cached bytes from in-memory cache if available.
  Uint8List? getMemoryCached(String url) {
    return _memoryCache[url];
  }

  /// Returns a local [File] if the image is already cached on disk, or null.
  Future<File?> getLocalFile(String url) async {
    if (url.trim().isEmpty) return null;

    // Handle direct local file paths
    if (url.startsWith('file://')) {
      final path = Uri.parse(url).toFilePath();
      final f = File(path);
      if (await f.exists()) return f;
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final f = File(url);
      if (await f.exists()) return f;
    }

    try {
      final dir = await _getCacheDirectory();
      final filename = _generateFilename(url);
      final file = File(p.join(dir.path, filename));
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Loads image bytes from memory, disk cache, or downloads from network and caches to disk.
  Future<Uint8List?> loadImageBytes(String url) async {
    if (url.trim().isEmpty) return null;

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // 2. Check local file or disk cache
    final localFile = await getLocalFile(url);
    if (localFile != null) {
      try {
        final bytes = await localFile.readAsBytes();
        if (bytes.isNotEmpty) {
          _memoryCache[url] = bytes;
          return bytes;
        }
      } catch (e) {
        AppLogger.warning('Failed reading cached file: $e');
      }
    }

    // If it's a non-HTTP path that doesn't exist, return null
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }

    // 3. Download from network and cache
    if (_pendingDownloads.contains(url)) {
      // Wait briefly for in-flight download
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (_memoryCache.containsKey(url)) return _memoryCache[url];
      }
    }

    _pendingDownloads.add(url);
    try {
      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'VOID/1.0 (Desktop Media Manager)',
          'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        _memoryCache[url] = bytes;

        // Persist to disk asynchronously
        try {
          final dir = await _getCacheDirectory();
          final filename = _generateFilename(url);
          final targetFile = File(p.join(dir.path, filename));
          final tempFile = File(p.join(dir.path, '$filename.tmp'));
          await tempFile.writeAsBytes(bytes, flush: true);
          if (await tempFile.exists()) {
            await tempFile.rename(targetFile.path);
          }
        } catch (e) {
          AppLogger.warning('Failed to save image to disk cache: $e');
        }

        return bytes;
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch image from $url: $e');
    } finally {
      _pendingDownloads.remove(url);
    }

    return null;
  }

  /// Proactively downloads and caches an image URL in the background.
  Future<void> preCache(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      await loadImageBytes(url);
    } catch (_) {}
  }

  /// Clears in-memory cache and optionally wipes disk media cache.
  Future<void> clearCache({bool includeDisk = false}) async {
    _memoryCache.clear();
    if (includeDisk && _cacheDir != null && await _cacheDir!.exists()) {
      try {
        final entities = await _cacheDir!.list().toList();
        for (final entity in entities) {
          if (entity is File) await entity.delete();
        }
      } catch (e) {
        AppLogger.error('Failed clearing disk media cache: $e');
      }
    }
  }
}
