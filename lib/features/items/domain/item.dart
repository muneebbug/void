import 'field_value.dart';

class Item {
  final String id;
  final String? collectionId;
  final String schemaId;
  final String? parentItemId;
  final String title;
  final String? coverImage;
  final Map<String, FieldValue> data;
  final String? externalSource;
  final String? externalId;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<Item> subItems;

  const Item({
    required this.id,
    this.collectionId,
    required this.schemaId,
    this.parentItemId,
    required this.title,
    this.coverImage,
    this.data = const {},
    this.externalSource,
    this.externalId,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.subItems = const [],
  });

  Item copyWith({
    String? id,
    String? collectionId,
    String? schemaId,
    String? parentItemId,
    String? title,
    String? coverImage,
    Map<String, FieldValue>? data,
    String? externalSource,
    String? externalId,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<Item>? subItems,
  }) {
    return Item(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      schemaId: schemaId ?? this.schemaId,
      parentItemId: parentItemId ?? this.parentItemId,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      data: data ?? this.data,
      externalSource: externalSource ?? this.externalSource,
      externalId: externalId ?? this.externalId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      subItems: subItems ?? this.subItems,
    );
  }

  FieldValue? getField(String key) => data[key];

  String? get textValue => getField('content')?.toDisplayString();
  double? get ratingValue => (getField('rating') as RatingValue?)?.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == id &&
          other.collectionId == collectionId &&
          other.schemaId == schemaId &&
          other.parentItemId == parentItemId &&
          other.title == title &&
          other.coverImage == coverImage &&
          other.externalSource == externalSource &&
          other.externalId == externalId &&
          other.position == position &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        id,
        collectionId,
        schemaId,
        parentItemId,
        title,
        coverImage,
        externalSource,
        externalId,
        position,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'Item($title, id: $id)';
}
