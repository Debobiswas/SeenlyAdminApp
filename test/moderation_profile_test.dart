import 'package:flutter_test/flutter_test.dart';
import 'package:seenly_admin_app/src/shared/models/moderation_profile.dart';

void main() {
  test('parses moderation profile json', () {
    final profile = ModerationProfile.fromJson({
      'id': '123',
      'email': 'creator@example.com',
      'full_name': 'Creator Name',
      'account_type': 'influencer',
      'status': 'pending',
      'created_at': '2026-06-20T10:00:00.000Z',
      'username': 'creator',
      'follower_count': 2300,
    });

    expect(profile.id, '123');
    expect(profile.accountType, AccountType.influencer);
    expect(profile.status, ProfileStatus.pending);
    expect(profile.followerCount, 2300);
  });
}

