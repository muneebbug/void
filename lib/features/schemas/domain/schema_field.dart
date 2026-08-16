import 'field_config.dart';
import 'field_type.dart';

class SchemaField {
  final String id;
  final String schemaId;
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final int position;
  final FieldConfig config;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SchemaField({
    required this.id,
    required this.schemaId,
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.position = 0,
    this.config = const NoneFieldConfig(),
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  SchemaField copyWith({
    String? id,
    String? schemaId,
    String? key,
    String? label,
    FieldType? type,
    bool? required,
    int? position,
    FieldConfig? config,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SchemaField(
      id: id ?? this.id,
      schemaId: schemaId ?? this.schemaId,
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      position: position ?? this.position,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schemaId': schemaId,
        'key': key,
        'label': label,
        'type': type.wireName,
        'required': required,
        'position': position,
        'config': config.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory SchemaField.fromJson(Map<String, dynamic> json) => SchemaField(
        id: json['id'] as String,
        schemaId: json['schemaId'] as String? ?? '',
        key: json['key'] as String,
        label: json['label'] as String,
        type: FieldType.fromString(json['type'] as String? ?? 'text'),
        required: json['required'] as bool? ?? false,
        position: (json['position'] as num?)?.toInt() ?? 0,
        config: json['config'] is Map<String, dynamic>
            ? FieldConfig.fromJson(json['config'] as Map<String, dynamic>)
            : const NoneFieldConfig(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        deletedAt: DateTime.tryParse(json['deletedAt']?.toString() ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaField &&
          other.id == id &&
          other.schemaId == schemaId &&
          other.key == key &&
          other.label == label &&
          other.type == type &&
          other.required == required &&
          other.position == position &&
          other.config == config &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        id,
        schemaId,
        key,
        label,
        type,
        required,
        position,
        config,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'SchemaField($key: $type, label: "$label")';
}
