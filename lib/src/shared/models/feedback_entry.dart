import '../../core/extensions/datetime_extensions.dart';

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.status, // 'open', 'resolved'
    this.userId,
    this.type,
    this.contactEmail,
    this.userName,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final String status;
  final String? userId;
  final String? type; // 'bug', 'feedback', 'question', 'other'
  final String? contactEmail;

  // Joined field
  final String? userName;

  String get formattedCreatedAt => createdAt.toReadableDateTime();

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: (json['id'] ?? '').toString(),
      message: (json['message'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: (json['status'] ?? 'open') as String,
      userId: json['user_id'] as String?,
      type: json['type'] as String?,
      contactEmail: json['contact_email'] as String?,
      userName: json['user_name'] as String? ?? (json['profiles'] != null ? json['profiles']['full_name'] as String? : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'user_id': userId,
      'type': type,
      'contact_email': contactEmail,
    };
  }
}
