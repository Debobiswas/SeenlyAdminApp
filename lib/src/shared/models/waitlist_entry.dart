import '../../core/extensions/datetime_extensions.dart';

class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.email,
    required this.userType,
    required this.fullName,
    required this.createdAt,
    this.city,
    this.socialHandle,
    this.businessName,
    this.googleMapsLink,
    this.instagramLink,
  });

  final String id; // UUID or String representation of id
  final String email;
  final String userType; // 'influencer' or 'business'
  final String fullName;
  final DateTime createdAt;
  final String? city;
  final String? socialHandle;
  final String? businessName;
  final String? googleMapsLink;
  final String? instagramLink;

  String get formattedCreatedAt => createdAt.toReadableDateTime();

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '') as String,
      userType: (json['user_type'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      city: json['city'] as String?,
      socialHandle: json['social_handle'] as String?,
      businessName: json['business_name'] as String?,
      googleMapsLink: json['google_maps_link'] as String?,
      instagramLink: json['instagram_link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'city': city,
      'social_handle': socialHandle,
      'business_name': businessName,
      'google_maps_link': googleMapsLink,
      'instagram_link': instagramLink,
    };
  }
}
