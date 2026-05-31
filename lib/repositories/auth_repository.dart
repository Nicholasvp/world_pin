import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Falha ao criar conta');

    await _client.from('users').insert({
      'id': response.user!.id,
      'email': email,
      'name': name,
      'countries_visited': [],
      'countries_wish': [],
    });

    return response.user!;
  }

  Future<User> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Credenciais inválidas');
    return response.user!;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<bool> getPremiumStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('users')
        .select('premium')
        .eq('id', user.id)
        .maybeSingle();

    return response?['premium'] == true;
  }

  Future<void> updatePremiumStatus({required bool isPremium}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado');

    await _client
        .from('users')
        .update({'premium': isPremium})
        .eq('id', user.id);
  }

  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Utilizador não autenticado');

    final accessToken = session.accessToken;
    await _client.functions.invoke(
      'delete-user',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}
