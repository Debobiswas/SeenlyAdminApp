import '../../core/extensions/datetime_extensions.dart';

class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.isEnabled,
    required this.createdAt,
    this.description,
    this.updatedAt,
    this.valueString,
  });

  final String key;
  final bool isEnabled;
  final DateTime createdAt;
  final String? description;
  final DateTime? updatedAt;
  final String? valueString;

  String get formattedCreatedAt => createdAt.toReadableDateTime();
  String get formattedUpdatedAt => updatedAt != null ? updatedAt!.toReadableDateTime() : '-';

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      key: (json['key'] ?? '') as String,
      isEnabled: (json['is_enabled'] ?? false) as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      valueString: json['value_string'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'updated_at': updatedAt?.toIso8601String(),
      'value_string': valueString,
    };
  }
}
