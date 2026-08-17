import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

/// Scalable helper for schema display elements (icons, colors, labels, placeholders).
class SchemaDisplayHelper {
  /// Resolves an IconData from an icon string name or schema ID
  static IconData getIcon(String? iconName, [String? schemaId]) {
    final name = (iconName ?? '').toLowerCase().trim();
    final id = (schemaId ?? '').toLowerCase().trim();

    if (name == 'movie' || name == 'film' || id.contains('movie')) {
      return Icons.movie_outlined;
    }
    if (name == 'tv' || name == 'television' || id.contains('tv')) {
      return Icons.tv_outlined;
    }
    if (name == 'menu_book' ||
        name == 'book' ||
        name == 'books' ||
        id.contains('book')) {
      return Icons.menu_book_outlined;
    }
    if (name == 'gamepad' ||
        name == 'games' ||
        name == 'sports_esports' ||
        id.contains('game')) {
      return Icons.sports_esports_outlined;
    }
    if (name == 'music' ||
        name == 'music_note' ||
        name == 'audio' ||
        id.contains('music')) {
      return Icons.music_note_outlined;
    }
    if (name == 'podcast' ||
        name == 'podcasts' ||
        name == 'headphones' ||
        id.contains('podcast')) {
      return Icons.podcasts_outlined;
    }
    if (name == 'palette' || name == 'art' || id.contains('art')) {
      return Icons.palette_outlined;
    }
    if (name == 'code' || name == 'developer' || id.contains('code')) {
      return Icons.code_outlined;
    }
    if (name == 'folder' || name == 'folder_open') {
      return Icons.folder_open_outlined;
    }

    return Icons.folder_outlined;
  }

  /// Resolves an accent color for a schema
  static Color getAccentColor(String? schemaId, {bool isDark = true}) {
    final id = (schemaId ?? '').toLowerCase();
    if (id.contains('movie')) return AppColors.movieAccent;
    if (id.contains('tv')) return AppColors.tvAccent;
    if (id.contains('book')) return AppColors.bookAccent;
    if (id.contains('game')) return const Color(0xFF10B981);
    if (id.contains('music') || id.contains('podcast')) {
      return const Color(0xFFA855F7);
    }
    return AppColors.primary;
  }

  /// Resolves a human-readable sublabel description for a schema
  static String getSublabel(String? schemaId) {
    if (schemaId == BuiltinSchemas.moviesSchemaId) return 'Films & cinema';
    if (schemaId == BuiltinSchemas.tvShowsSchemaId) return 'Series & anime';
    if (schemaId == BuiltinSchemas.booksSchemaId) return 'Novels & docs';
    return 'Custom collection';
  }

  /// Resolves a context-aware placeholder hint for list naming
  static String getPlaceholderHint(String? schemaId) {
    if (schemaId == BuiltinSchemas.tvShowsSchemaId) {
      return 'e.g. Sci-Fi TV Series, Fall Anime 2026';
    }
    if (schemaId == BuiltinSchemas.booksSchemaId) {
      return 'e.g. 2026 Reading List, Philosophy Books';
    }
    if (schemaId == BuiltinSchemas.moviesSchemaId) {
      return 'e.g. 2026 Movie Watchlist, Sci-Fi Movies';
    }
    return 'e.g. My Custom Collection';
  }
}
