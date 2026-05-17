import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigRepository {
  final SupabaseClient _client;

  ConfigRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Queries the 'config' table in Supabase and returns the 'limit_free_countries' value.
  /// Falls back to a default value of 5 if the table doesn't exist, is empty, or the query fails.
  Future<int> getLimitFreeCountries() async {
    try {
      final response = await _client
          .from('config')
          .select('limit_free_countries')
          .limit(1)
          .maybeSingle();

      if (response != null && response['limit_free_countries'] != null) {
        return response['limit_free_countries'] as int;
      }
    } catch (e) {
      // Table might not be fully configured, return default fallback
    }
    return 3; // Default fallback limit
  }
}
