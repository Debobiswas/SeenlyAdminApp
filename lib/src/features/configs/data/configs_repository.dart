import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/feature_flag.dart';

class ConfigsRepository {
  ConfigsRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeatureFlag>> fetchFeatureFlags() async {
    final response = await _client
        .from('feature_flags')
        .select()
        .order('key', ascending: true);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FeatureFlag.fromJson)
        .toList();
  }

  Future<void> toggleFeatureFlag(String key, bool isEnabled) async {
    await _client
        .from('feature_flags')
        .update({
          'is_enabled': isEnabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('key', key);
  }

  Future<void> updateFeatureFlagValue(String key, String? valueString) async {
    await _client
        .from('feature_flags')
        .update({
          'value_string': valueString,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('key', key);
  }
}
