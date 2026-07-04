import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';

class UserPublicProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<String> visitedCountries;

  UserPublicProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.visitedCountries,
  });
}

final allUsersProvider = FutureProvider<List<UserPublicProfile>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final client = Supabase.instance.client;
  final data = await client.from('users').select('''
    id,
    name,
    avatar_url,
    countries_visited
  ''');

  final currentUserId = client.auth.currentUser?.id;

  final users = <UserPublicProfile>[];
  for (final row in data) {
    if (row['id'] == currentUserId) continue;

    final visited = (row['countries_visited'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (visited.isEmpty) continue;

    users.add(UserPublicProfile(
      id: row['id'],
      name: row['name'] ?? 'Usuário',
      avatarUrl: row['avatar_url'] as String?,
      visitedCountries: visited,
    ));
  }

  return users;
});
