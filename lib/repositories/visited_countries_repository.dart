import 'package:supabase_flutter/supabase_flutter.dart';

class VisitedCountriesRepository {
  final SupabaseClient _client;

  static const _table = 'users';
  static const _column = 'countries_visited';

  VisitedCountriesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Usuário não autenticado');
    return id;
  }

  /// Garante que o registro do usuário existe na tabela.
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

  /// Retorna a lista de países visitados do usuário autenticado.
  Future<List<String>> getAll() async {
    final data = await _client
        .from(_table)
        .select(_column)
        .eq('id', _userId)
        .maybeSingle();

    final list = data?[_column] as List?;
    return list?.cast<String>() ?? [];
  }

  /// Adiciona um país à lista (sem duplicatas).
  Future<List<String>> add(String isoCode) async {
    await _ensureUserExists();

    final current = await getAll();
    if (current.contains(isoCode)) return current;

    final updated = [...current, isoCode];
    await _client
        .from(_table)
        .update({_column: updated})
        .eq('id', _userId);

    return updated;
  }

  /// Remove um país da lista.
  Future<List<String>> remove(String isoCode) async {
    await _ensureUserExists();

    final current = await getAll();
    final updated = current.where((c) => c != isoCode).toList();

    await _client
        .from(_table)
        .update({_column: updated})
        .eq('id', _userId);

    return updated;
  }

  /// Substitui toda a lista de países visitados.
  Future<void> setAll(List<String> isoCodes) async {
    await _ensureUserExists();

    await _client
        .from(_table)
        .update({_column: isoCodes})
        .eq('id', _userId);
  }
}