import '../../core/extensions/datetime_extensions.dart';

class Venue {
  const Venue({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
    this.imageUrl,
    this.heroImageUrl,
    this.category,
    this.categoryEmoji,
    this.tier,
    this.subscriptionTier,
    this.rating,
    this.bio,
    this.website,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final String? imageUrl;
  final String? heroImageUrl;
  final String? category;
  final String? categoryEmoji;
  final String? tier;
  final String? subscriptionTier;
  final double? rating;
  final String? bio;
  final String? website;

  String get formattedCreatedAt => createdAt.toReadableDateTime();

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['owner_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: (json['is_active'] ?? false) as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String?,
      heroImageUrl: json['hero_image_url'] as String?,
      category: json['category'] as String?,
      categoryEmoji: json['category_emoji'] as String?,
      tier: json['tier'] as String?,
      subscriptionTier: json['subscription_tier'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      website: (json['website'] ?? json['website_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'hero_image_url': heroImageUrl,
      'category': category,
      'category_emoji': categoryEmoji,
      'tier': tier,
      'subscription_tier': subscriptionTier,
      'rating': rating,
      'bio': bio,
      'website': website,
    };
  }
}
