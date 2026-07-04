import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../repositories/avatar_repository.dart';

final avatarRepositoryProvider = Provider<AvatarRepositoryInterface>((ref) {
  return AvatarRepository();
});

class AvatarNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return null;

    final repo = ref.watch(avatarRepositoryProvider);
    return repo.getAvatarUrl();
  }

  Future<void> upload(File file) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(avatarRepositoryProvider);
      final url = await repo.uploadAvatar(file);
      state = AsyncData(url);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> remove() async {
    try {
      final repo = ref.read(avatarRepositoryProvider);
      await repo.deleteAvatar();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final avatarProvider =
    AsyncNotifierProvider<AvatarNotifier, String?>(AvatarNotifier.new);
