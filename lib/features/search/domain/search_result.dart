import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/domain/schema.dart';

enum SearchResultType { item, collection, schema }

class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final String? coverImage;
  final SearchResultType type;
  final Item? item;
  final Collection? collection;
  final Schema? schema;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.coverImage,
    required this.type,
    this.item,
    this.collection,
    this.schema,
  });

  SearchResult copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? icon,
    String? coverImage,
    SearchResultType? type,
    Item? item,
    Collection? collection,
    Schema? schema,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      coverImage: coverImage ?? this.coverImage,
      type: type ?? this.type,
      item: item ?? this.item,
      collection: collection ?? this.collection,
      schema: schema ?? this.schema,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchResult &&
          other.id == id &&
          other.title == title &&
          other.type == type);

  @override
  int get hashCode => Object.hash(id, title, type);
}
