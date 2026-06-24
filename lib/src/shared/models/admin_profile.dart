class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final String? role;

  bool get hasAdminAccess => isAdmin || role == 'admin';

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      isAdmin: (json['is_admin'] ?? false) as bool,
      role: json['role'] as String?,
    );
  }
}

