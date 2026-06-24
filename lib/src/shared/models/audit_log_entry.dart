import '../../core/extensions/datetime_extensions.dart';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.adminUserId,
    required this.targetUserId,
    required this.action,
    required this.createdAt,
    this.reason,
    this.targetEmail,
    this.targetName,
  });

  final String id;
  final String adminUserId;
  final String targetUserId;
  final String action;
  final DateTime createdAt;
  final String? reason;
  final String? targetEmail;
  final String? targetName;

  String get formattedTimestamp => createdAt.toReadableDateTime();

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      adminUserId: json['admin_user_id'] as String,
      targetUserId: json['target_user_id'] as String,
      action: json['action'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reason: json['reason'] as String?,
      targetEmail: json['target_email'] as String?,
      targetName: json['target_name'] as String?,
    );
  }
}

