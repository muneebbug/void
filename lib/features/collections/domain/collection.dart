class Collection {
  final String id;
  final String name;
  final String? icon;
  final String schemaId;
  final int position;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Collection({
    required this.id,
    required this.name,
    this.icon,
    required this.schemaId,
    this.position = 0,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? icon,
    String? schemaId,
    int? position,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      schemaId: schemaId ?? this.schemaId,
      position: position ?? this.position,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'schemaId': schemaId,
        'position': position,
        'itemCount': itemCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        schemaId: json['schemaId'] as String,
        position: (json['position'] as num?)?.toInt() ?? 0,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        deletedAt: DateTime.tryParse(json['deletedAt']?.toString() ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == id &&
          other.name == name &&
          other.icon == icon &&
          other.schemaId == schemaId &&
          other.position == position &&
          other.itemCount == itemCount &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        icon,
        schemaId,
        position,
        itemCount,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'Collection($name, id: $id, items: $itemCount)';
}
