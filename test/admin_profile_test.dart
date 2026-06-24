import 'package:flutter_test/flutter_test.dart';
import 'package:seenly_admin_app/src/shared/models/admin_profile.dart';

void main() {
  test('admin access is granted by is_admin', () {
    const profile = AdminProfile(
      id: '1',
      email: 'admin@example.com',
      fullName: 'Admin',
      isAdmin: true,
    );

    expect(profile.hasAdminAccess, isTrue);
  });

  test('admin access is granted by role', () {
    const profile = AdminProfile(
      id: '1',
      email: 'admin@example.com',
      fullName: 'Admin',
      isAdmin: false,
      role: 'admin',
    );

    expect(profile.hasAdminAccess, isTrue);
  });
}
