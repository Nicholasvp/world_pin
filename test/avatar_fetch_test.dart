import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:world_pin/controllers/auth_controller.dart';
import 'package:world_pin/providers/avatar_provider.dart';
import 'package:world_pin/repositories/avatar_repository.dart';

class _FakeAuthNotifier extends AuthController {
  final AuthState _state;

  _FakeAuthNotifier(this._state);

  @override
  AuthState build() => _state;
}

class _FakeAvatarRepository implements AvatarRepositoryInterface {
  String? _url;
  bool _shouldThrowOnUpload = false;
  bool _shouldThrowOnDelete = false;

  void setUrl(String? url) => _url = url;

  @override
  Future<String?> getAvatarUrl() async => _url;

  @override
  Future<String> uploadAvatar(File file) async {
    if (_shouldThrowOnUpload) throw Exception('Upload failed');
    _url = 'https://example.com/avatar.jpg';
    return _url!;
  }

  @override
  Future<void> deleteAvatar() async {
    if (_shouldThrowOnDelete) throw Exception('Delete failed');
    _url = null;
  }

  void failOnUpload() => _shouldThrowOnUpload = true;
  void failOnDelete() => _shouldThrowOnDelete = true;
}

void main() {
  group('AvatarNotifier', () {
    test('build() returns null when not authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(const AuthUnauthenticated()),
          ),
          avatarRepositoryProvider.overrideWith(
            (ref) => _FakeAvatarRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final url = await container.read(avatarProvider.future);
      expect(url, isNull);
    });

    test('build() returns null when authenticated but no avatar stored',
        () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthAuthenticated(
                User.fromJson({'id': 'test-user-id'})!,
              ),
            ),
          ),
          avatarRepositoryProvider.overrideWith(
            (ref) => _FakeAvatarRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final url = await container.read(avatarProvider.future);
      expect(url, isNull);
    });

    test('build() returns stored URL when avatar exists', () async {
      final repo = _FakeAvatarRepository();
      repo.setUrl('https://example.com/avatar.jpg');

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthAuthenticated(
                User.fromJson({'id': 'test-user-id'})!,
              ),
            ),
          ),
          avatarRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
      addTearDown(container.dispose);

      final url = await container.read(avatarProvider.future);
      expect(url, 'https://example.com/avatar.jpg');
    });

    test('upload() stores URL and updates state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthAuthenticated(
                User.fromJson({'id': 'test-user-id'})!,
              ),
            ),
          ),
          avatarRepositoryProvider.overrideWith(
            (ref) => _FakeAvatarRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(avatarProvider.future);

      await container.read(avatarProvider.notifier).upload(File(''));

      final url = container.read(avatarProvider).valueOrNull;
      expect(url, 'https://example.com/avatar.jpg');
    });

    test('remove() clears URL from state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthAuthenticated(
                User.fromJson({'id': 'test-user-id'})!,
              ),
            ),
          ),
          avatarRepositoryProvider.overrideWith(
            (ref) => _FakeAvatarRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(avatarProvider.future);

      await container.read(avatarProvider.notifier).upload(File(''));
      expect(
        container.read(avatarProvider).valueOrNull,
        'https://example.com/avatar.jpg',
      );

      await container.read(avatarProvider.notifier).remove();
      expect(container.read(avatarProvider).valueOrNull, isNull);
    });

    test('upload() sets error state on failure', () async {
      final repo = _FakeAvatarRepository();
      repo.failOnUpload();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthAuthenticated(
                User.fromJson({'id': 'test-user-id'})!,
              ),
            ),
          ),
          avatarRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(avatarProvider.future);

      await container.read(avatarProvider.notifier).upload(File(''));
      expect(container.read(avatarProvider).hasError, isTrue);
    });
  });
}
