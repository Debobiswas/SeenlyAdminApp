import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/venue.dart';
import '../../../shared/models/campaign.dart';

class DirectoryRepository {
  DirectoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<Venue>> fetchVenues() async {
    final response = await _client
        .from('venues')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Venue.fromJson)
        .toList();
  }

  Future<void> toggleVenueStatus(String venueId, bool isActive) async {
    await _client
        .from('venues')
        .update({'is_active': isActive})
        .eq('id', venueId);
  }

  Future<void> updateVenueSubscriptionTier(String venueId, String tier) async {
    await _client
        .from('venues')
        .update({'subscription_tier': tier})
        .eq('id', venueId);
  }

  Future<List<Campaign>> fetchCampaigns() async {
    // Select campaign data joined with venue name
    final response = await _client
        .from('campaigns')
        .select('*, venues(name)')
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((data) {
      final map = Map<String, dynamic>.from(data);
      if (map['venues'] != null) {
        map['venue_name'] = map['venues']['name'];
      }
      return Campaign.fromJson(map);
    }).toList();
  }

  Future<void> toggleCampaignStatus(String campaignId, bool isActive) async {
    await _client
        .from('campaigns')
        .update({'is_active': isActive})
        .eq('id', campaignId);
  }

  Future<void> adjustCampaignInventory(String campaignId, int remainingSlots) async {
    await _client
        .from('campaigns')
        .update({'remaining_inventory': remainingSlots})
        .eq('id', campaignId);
  }
}
