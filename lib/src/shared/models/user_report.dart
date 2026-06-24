import '../../core/extensions/datetime_extensions.dart';

class UserReport {
  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.createdAt,
    this.reservationId,
    this.reporterName,
    this.reporterEmail,
    this.reportedName,
    this.reportedEmail,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final DateTime createdAt;
  final String? reservationId;
  
  // Join fields for cleaner UX
  final String? reporterName;
  final String? reporterEmail;
  final String? reportedName;
  final String? reportedEmail;

  String get formattedCreatedAt => createdAt.toReadableDateTime();

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: (json['id'] ?? '').toString(),
      reporterId: (json['reporter_id'] ?? '') as String,
      reportedUserId: (json['reported_user_id'] ?? '') as String,
      reason: (json['reason'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reservationId: json['reservation_id']?.toString(),
      reporterName: json['reporter_name'] as String? ?? json['reporter_full_name'] as String?,
      reporterEmail: json['reporter_email'] as String?,
      reportedName: json['reported_name'] as String? ?? json['reported_full_name'] as String?,
      reportedEmail: json['reported_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'reservation_id': reservationId,
    };
  }
}
