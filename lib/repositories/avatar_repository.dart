import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AvatarRepositoryInterface {
  Future<String?> getAvatarUrl();
  Future<String> uploadAvatar(File file);
  Future<void> deleteAvatar();
}

class AvatarRepository implements AvatarRepositoryInterface {
  final SupabaseClient _client;

  static const _bucket = 'avatars';
  static const _folder = 'private';

  AvatarRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Usuário não autenticado');
    return id;
  }

  String _avatarPath() => '$_folder/$_userId/profile.jpg';

  Future<String> uploadAvatar(File file) async {
    final path = _avatarPath();

    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from(_bucket).getPublicUrl(path);

    await _client.from('users').update({'avatar_url': url}).eq('id', _userId);

    return url;
  }

  Future<String?> getAvatarUrl() async {
    final data = await _client
        .from('users')
        .select('avatar_url')
        .eq('id', _userId)
        .maybeSingle();

    return data?['avatar_url'] as String?;
  }

  Future<void> deleteAvatar() async {
    final path = _avatarPath();

    await _client.storage.from(_bucket).remove([path]);

    await _client.from('users').update({'avatar_url': null}).eq('id', _userId);
  }
}
