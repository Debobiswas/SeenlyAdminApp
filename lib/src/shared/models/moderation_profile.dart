import '../../core/extensions/datetime_extensions.dart';

enum AccountType {
  influencer,
  business,
  unknown;

  static AccountType fromValue(String? raw) {
    switch (raw) {
      case 'influencer':
        return AccountType.influencer;
      case 'business':
        return AccountType.business;
      default:
        return AccountType.unknown;
    }
  }
}

enum ProfileStatus {
  pending,
  active,
  rejected,
  unknown;

  static ProfileStatus fromValue(String? raw) {
    switch (raw) {
      case 'pending':
        return ProfileStatus.pending;
      case 'active':
        return ProfileStatus.active;
      case 'rejected':
        return ProfileStatus.rejected;
      default:
        return ProfileStatus.unknown;
    }
  }
}

class ModerationProfile {
  const ModerationProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.accountType,
    required this.status,
    required this.createdAt,
    this.avatarUrl,
    this.bio,
    this.instagramHandle,
    this.tiktokHandle,
    this.website,
    this.followerCount,
    this.strikes,
  });

  final String id;
  final String email;
  final String fullName;
  final AccountType accountType;
  final ProfileStatus status;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? bio;
  final String? instagramHandle;
  final String? tiktokHandle;
  final String? website;
  final int? followerCount;
  final int? strikes;

  String? get username => (instagramHandle != null && instagramHandle!.isNotEmpty) 
      ? instagramHandle 
      : tiktokHandle;

  bool get isInfluencer => accountType == AccountType.influencer;
  bool get isBusiness => accountType == AccountType.business;
  String get formattedCreatedAt => createdAt.toReadableDateTime();

  factory ModerationProfile.fromJson(Map<String, dynamic> json) {
    return ModerationProfile(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? json['name'] ?? '') as String,
      accountType: AccountType.fromValue((json['account_type'] ?? json['role'] ?? json['tier']) as String?),
      status: ProfileStatus.fromValue(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      tiktokHandle: json['tiktok_handle'] as String?,
      website: json['website_url'] as String?,
      followerCount: (json['follower_count'] as num?)?.toInt(),
      strikes: (json['strikes'] as num?)?.toInt(),
    );
  }
}

