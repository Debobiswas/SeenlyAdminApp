import '../../core/extensions/datetime_extensions.dart';

class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.campaignId,
    required this.status,
    required this.createdAt,
    this.proofUrl,
    this.redeemedAt,
    this.expiresAt,
    this.creatorName,
    this.venueName,
    this.campaignTitle,
  });

  final String id;
  final String userId;
  final String venueId;
  final String campaignId;
  final String status; // 'active', 'redeemed', 'completed', 'expired', 'cancelled'
  final DateTime createdAt;
  final String? proofUrl;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;

  // Join fields
  final String? creatorName;
  final String? venueName;
  final String? campaignTitle;

  String get formattedCreatedAt => createdAt.toReadableDateTime();
  String get formattedRedeemedAt => redeemedAt != null ? redeemedAt!.toReadableDateTime() : '-';
  String get formattedExpiresAt => expiresAt != null ? expiresAt!.toReadableDateTime() : '-';

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '') as String,
      venueId: (json['venue_id'] ?? '') as String,
      campaignId: (json['campaign_id'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      proofUrl: json['proof_url'] as String?,
      redeemedAt: json['redeemed_at'] != null ? DateTime.parse(json['redeemed_at'] as String) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      creatorName: json['creator_name'] as String? ?? (json['profiles'] != null ? json['profiles']['full_name'] as String? : null),
      venueName: json['venue_name'] as String? ?? (json['venues'] != null ? json['venues']['name'] as String? : null),
      campaignTitle: json['campaign_title'] as String? ?? (json['campaigns'] != null ? json['campaigns']['title'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'venue_id': venueId,
      'campaign_id': campaignId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'proof_url': proofUrl,
      'redeemed_at': redeemedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
