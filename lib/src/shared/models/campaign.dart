import '../../core/extensions/datetime_extensions.dart';

class Campaign {
  const Campaign({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.totalInventory,
    required this.remainingInventory,
    required this.isActive,
    required this.createdAt,
    this.imageUrl,
    this.tier,
    this.expiryTime,
    this.valueText,
    this.requirementText,
    this.additionalImages,
    this.videoUrl,
    this.isDeleted = false,
    this.soldOutAt,
    this.venueName, // Joined field
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final int totalInventory;
  final int remainingInventory;
  final bool isActive;
  final DateTime createdAt;
  final String? imageUrl;
  final String? tier;
  final DateTime? expiryTime;
  final String? valueText;
  final String? requirementText;
  final List<String>? additionalImages;
  final String? videoUrl;
  final bool isDeleted;
  final DateTime? soldOutAt;

  // Join fields
  final String? venueName;

  String get formattedCreatedAt => createdAt.toReadableDateTime();
  String get formattedExpiryTime => expiryTime != null ? expiryTime!.toReadableDateTime() : 'No Expiry';

  factory Campaign.fromJson(Map<String, dynamic> json) {
    List<String>? parsedImages;
    if (json['additional_images'] != null) {
      if (json['additional_images'] is List) {
        parsedImages = (json['additional_images'] as List).map((e) => e.toString()).toList();
      }
    }

    return Campaign(
      id: (json['id'] ?? '').toString(),
      venueId: (json['venue_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      totalInventory: (json['total_inventory'] as num?)?.toInt() ?? 0,
      remainingInventory: (json['remaining_inventory'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] ?? false) as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String?,
      tier: json['tier'] as String?,
      expiryTime: json['expiry_time'] != null ? DateTime.parse(json['expiry_time'] as String) : null,
      valueText: json['value_text'] as String?,
      requirementText: json['requirement_text'] as String?,
      additionalImages: parsedImages,
      videoUrl: json['video_url'] as String?,
      isDeleted: (json['is_deleted'] ?? false) as bool,
      soldOutAt: json['sold_out_at'] != null ? DateTime.parse(json['sold_out_at'] as String) : null,
      venueName: json['venue_name'] as String? ?? (json['venues'] != null ? json['venues']['name'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'title': title,
      'description': description,
      'total_inventory': totalInventory,
      'remaining_inventory': remainingInventory,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'tier': tier,
      'expiry_time': expiryTime?.toIso8601String(),
      'value_text': valueText,
      'requirement_text': requirementText,
      'additional_images': additionalImages,
      'video_url': videoUrl,
      'is_deleted': isDeleted,
      'sold_out_at': soldOutAt?.toIso8601String(),
    };
  }
}
