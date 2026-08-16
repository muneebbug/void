import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:void_app/core/errors/app_exception.dart';
import 'package:void_app/core/utils/logger.dart';
import 'package:void_app/features/media_search/domain/media_search_result.dart';

abstract class MediaApiService {
  Future<List<MediaSearchResult>> searchMovies(String query);
  Future<List<MediaSearchResult>> searchTvShows(String query);
  Future<List<MediaSearchResult>> searchBooks(String query);
}

class DefaultMediaApiService implements MediaApiService {
  final http.Client _client;

  DefaultMediaApiService([http.Client? client])
      : _client = client ?? http.Client();

  static const Map<int, String> _tmdbGenreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  @override
  Future<List<MediaSearchResult>> searchMovies(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Try TMDb Movie Search API (The Movie Database)
    try {
      final tmdbUrl = Uri.parse(
        'https://api.themoviedb.org/3/search/movie?query=${Uri.encodeComponent(cleanQuery)}&api_key=4e44d9029b1270a757cddc766a1bcb63&include_adult=false',
      );
      final response = await _client.get(
        tmdbUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VOID-Desktop-App/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        if (results.isNotEmpty) {
          return results.map((item) {
            final map = item as Map<String, dynamic>;
            final title = map['title']?.toString() ??
                map['original_title']?.toString() ??
                'Untitled Movie';
            final releaseDate = map['release_date']?.toString();
            final year = releaseDate != null && releaseDate.length >= 4
                ? releaseDate.substring(0, 4)
                : null;
            final overview = map['overview']?.toString();
            final voteAverage =
                (map['vote_average'] as num?)?.toDouble() ?? 0.0;
            final posterPath = map['poster_path']?.toString();
            final posterUrl = posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : null;

            final genreIds = (map['genre_ids'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList();
            String? genre;
            if (genreIds != null && genreIds.isNotEmpty) {
              genre = _tmdbGenreMap[genreIds.first] ?? 'Other';
            }

            return MediaSearchResult(
              id: 'tmdb_movie_${map['id'] ?? title}',
              title: title,
              type: MediaCandidateType.movie,
              year: year,
              creator: null,
              genre: genre,
              rating: voteAverage,
              overview: overview,
              coverUrl: posterUrl,
              rawMetadata: map,
            );
          }).toList();
        }
      }
    } catch (e) {
      AppLogger.warning('TMDb movie search error, attempting fallback: $e');
    }

    // 2. Fallback to iTunes Search API
    try {
      final itunesUrl = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(cleanQuery)}&limit=25',
      );
      final response = await _client.get(
        itunesUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((item) {
          final map = item as Map<String, dynamic>;
          final trackName = map['trackName']?.toString() ??
              map['collectionName']?.toString() ??
              'Untitled Movie';
          final releaseDate = map['releaseDate']?.toString();
          final year = releaseDate != null && releaseDate.length >= 4
              ? releaseDate.substring(0, 4)
              : null;
          final director = map['artistName']?.toString();
          final genre = map['primaryGenreName']?.toString();
          final overview = map['longDescription']?.toString() ??
              map['shortDescription']?.toString();

          String? posterUrl = map['artworkUrl100']?.toString();
          if (posterUrl != null) {
            posterUrl = posterUrl.replaceAll('100x100bb.jpg', '600x600bb.jpg');
          }

          final trackTimeMillis = (map['trackTimeMillis'] as num?)?.toDouble();
          final runtimeMinutes = trackTimeMillis != null
              ? (trackTimeMillis / 60000).round()
              : null;

          return MediaSearchResult(
            id: 'itunes_movie_${map['trackId'] ?? trackName}',
            title: trackName,
            type: MediaCandidateType.movie,
            year: year,
            creator: director,
            genre: genre,
            rating: 0.0,
            overview: overview,
            coverUrl: posterUrl,
            runtimeOrPages: runtimeMinutes,
            rawMetadata: map,
          );
        }).toList();
      }
    } catch (e, stack) {
      AppLogger.error(
        'All movie search providers failed: $e',
        tag: 'MediaApi',
        stackTrace: stack,
      );
      throw NetworkException('Failed to search movies: $e');
    }

    return [];
  }

  @override
  Future<List<MediaSearchResult>> searchTvShows(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://api.tvmaze.com/search/shows?q=${Uri.encodeComponent(cleanQuery)}',
      );
      final response =
          await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw NetworkException(
          'TV Show search failed with status ${response.statusCode}',
        );
      }

      final results = jsonDecode(response.body) as List<dynamic>;

      return results.map((entry) {
        final show =
            (entry as Map<String, dynamic>)['show'] as Map<String, dynamic>? ??
                {};
        final name = show['name']?.toString() ?? 'Untitled Show';
        final premiered = show['premiered']?.toString();
        final year = premiered != null && premiered.length >= 4
            ? premiered.substring(0, 4)
            : null;
        final network = (show['network'] as Map<String, dynamic>?)?['name']
                ?.toString() ??
            (show['webChannel'] as Map<String, dynamic>?)?['name']?.toString();
        final genresList = (show['genres'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        final genre = genresList != null && genresList.isNotEmpty
            ? genresList.first
            : null;
        final ratingVal =
            ((show['rating'] as Map<String, dynamic>?)?['average'] as num?)
                ?.toDouble();

        String? rawSummary = show['summary']?.toString();
        if (rawSummary != null) {
          // Strip HTML tags from TVmaze summary
          rawSummary =
              rawSummary.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
        }

        final imageMap = show['image'] as Map<String, dynamic>?;
        final posterUrl = imageMap?['original']?.toString() ??
            imageMap?['medium']?.toString();

        return MediaSearchResult(
          id: 'tv_${show['id'] ?? name}',
          title: name,
          type: MediaCandidateType.tv,
          year: year,
          creator: network,
          genre: genre,
          rating: ratingVal ?? 0.0,
          overview: rawSummary,
          coverUrl: posterUrl,
          rawMetadata: show,
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to search TV shows: $e',
        tag: 'MediaApi',
        stackTrace: stack,
      );
      throw NetworkException('Failed to search TV shows: $e');
    }
  }

  @override
  Future<List<MediaSearchResult>> searchBooks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(cleanQuery)}&limit=25',
      );
      final response =
          await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw NetworkException(
          'Book search failed with status ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];

      return docs.map((doc) {
        final map = doc as Map<String, dynamic>;
        final title = map['title']?.toString() ?? 'Untitled Book';
        final authorsList = (map['author_name'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        final author = authorsList != null && authorsList.isNotEmpty
            ? authorsList.join(', ')
            : null;
        final firstPublishYear = map['first_publish_year']?.toString();

        final pageCount = (map['number_of_pages_median'] as num?)?.toInt();
        final subjectsList = (map['subject'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        final genre = subjectsList != null && subjectsList.isNotEmpty
            ? subjectsList.first
            : null;

        final isbnsList =
            (map['isbn'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        final isbn =
            isbnsList != null && isbnsList.isNotEmpty ? isbnsList.first : null;

        final coverId = map['cover_i']?.toString();
        final posterUrl = coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
            : null;

        final ratingsAverage = (map['ratings_average'] as num?)?.toDouble();

        return MediaSearchResult(
          id: 'book_${map['key'] ?? isbn ?? title}',
          title: title,
          type: MediaCandidateType.book,
          year: firstPublishYear,
          creator: author,
          genre: genre,
          rating: ratingsAverage != null ? (ratingsAverage * 1.0) : 0.0,
          coverUrl: posterUrl,
          runtimeOrPages: pageCount,
          extraIdentifier: isbn,
          rawMetadata: map,
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to search books: $e',
        tag: 'MediaApi',
        stackTrace: stack,
      );
      throw NetworkException('Failed to search books: $e');
    }
  }
}
