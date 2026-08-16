import 'schema_field.dart';

class Schema {
  final String id;
  final String name;
  final String? icon;
  final bool isBuiltin;
  final List<SchemaField> fields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Schema({
    required this.id,
    required this.name,
    this.icon,
    this.isBuiltin = false,
    this.fields = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Schema copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isBuiltin,
    List<SchemaField>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Schema(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'isBuiltin': isBuiltin,
        'fields': fields.map((f) => f.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Schema.fromJson(Map<String, dynamic> json) => Schema(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        isBuiltin: json['isBuiltin'] as bool? ?? false,
        fields: (json['fields'] as List<dynamic>?)
                ?.map((f) => SchemaField.fromJson(f as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        deletedAt: DateTime.tryParse(json['deletedAt']?.toString() ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schema &&
          other.id == id &&
          other.name == name &&
          other.icon == icon &&
          other.isBuiltin == isBuiltin &&
          other.fields.length == fields.length &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        icon,
        isBuiltin,
        Object.hashAll(fields),
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'Schema($name, id: $id, ${fields.length} fields)';
}
