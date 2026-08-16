enum MediaCandidateType { movie, tv, book }

class MediaSearchResult {
  final String id;
  final String title;
  final MediaCandidateType type;
  final String? year;
  final String? creator;
  final String? genre;
  final double? rating;
  final String? overview;
  final String? coverUrl;
  final int? runtimeOrPages;
  final String? extraIdentifier;
  final Map<String, dynamic> rawMetadata;

  const MediaSearchResult({
    required this.id,
    required this.title,
    required this.type,
    this.year,
    this.creator,
    this.genre,
    this.rating,
    this.overview,
    this.coverUrl,
    this.runtimeOrPages,
    this.extraIdentifier,
    this.rawMetadata = const {},
  });

  MediaSearchResult copyWith({
    String? id,
    String? title,
    MediaCandidateType? type,
    String? year,
    String? creator,
    String? genre,
    double? rating,
    String? overview,
    String? coverUrl,
    int? runtimeOrPages,
    String? extraIdentifier,
    Map<String, dynamic>? rawMetadata,
  }) {
    return MediaSearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      year: year ?? this.year,
      creator: creator ?? this.creator,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      overview: overview ?? this.overview,
      coverUrl: coverUrl ?? this.coverUrl,
      runtimeOrPages: runtimeOrPages ?? this.runtimeOrPages,
      extraIdentifier: extraIdentifier ?? this.extraIdentifier,
      rawMetadata: rawMetadata ?? this.rawMetadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaSearchResult &&
          other.id == id &&
          other.title == title &&
          other.type == type);

  @override
  int get hashCode => Object.hash(id, title, type);
}
