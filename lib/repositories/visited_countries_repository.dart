import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sealed_countries/sealed_countries.dart';

class VisitedCountriesRepository {
  final SupabaseClient _client;

  static const _table = 'users';
  static const _visitedColumn = 'countries_visited';
  static const _wishColumn = 'countries_wish';

  VisitedCountriesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Usuário não autenticado');
    return id;
  }

  Future<void> _ensureUserExists() async {
    final exists = await _client
        .from(_table)
        .select('id')
        .eq('id', _userId)
        .maybeSingle();

    if (exists != null) return;

    final authUser = _client.auth.currentUser!;
    await _client.from(_table).insert({
      'id': authUser.id,
      'email': authUser.email ?? '',
      'name': authUser.email?.split('@').first ?? 'usuário',
      'countries_visited': [],
      'countries_wish': [],
    });
  }

  /// Retorna a lista de países de uma coluna específica.
  Future<List<String>> _get(String column) async {
    final data = await _client
        .from(_table)
        .select(column)
        .eq('id', _userId)
        .maybeSingle();

    final list = data?[column] as List?;
    return list?.cast<String>() ?? [];
  }

  Future<List<String>> getVisited() => _get(_visitedColumn);
  Future<List<String>> getWishlist() => _get(_wishColumn);

  /// Adiciona um país a uma lista específica.
  Future<List<String>> _add(String column, String isoCode) async {
    await _ensureUserExists();

    final current = await _get(column);
    if (current.contains(isoCode)) return current;

    final updated = [...current, isoCode];
    await _client.from(_table).update({column: updated}).eq('id', _userId);

    return updated;
  }

  Future<List<String>> addVisited(String isoCode) => _add(_visitedColumn, isoCode);
  Future<List<String>> addWishlist(String isoCode) => _add(_wishColumn, isoCode);

  /// Remove um país de uma lista específica.
  Future<List<String>> _remove(String column, String isoCode) async {
    await _ensureUserExists();

    final current = await _get(column);
    final updated = current.where((c) {
      final country = WorldCountry.maybeFromAnyCode(c);
      return country?.code != isoCode && c != isoCode;
    }).toList();

    await _client.from(_table).update({column: updated}).eq('id', _userId);

    return updated;
  }

  Future<List<String>> removeVisited(String isoCode) => _remove(_visitedColumn, isoCode);
  Future<List<String>> removeWishlist(String isoCode) => _remove(_wishColumn, isoCode);
}