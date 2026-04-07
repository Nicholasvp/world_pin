import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

// Estado da autenticação
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Controller
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = AuthRepository();

    // Escuta mudanças de sessão em tempo real
    _repository.authStateChanges.listen((event) {
      final user = event.session?.user;
      state = user != null
          ? AuthAuthenticated(user)
          : const AuthUnauthenticated();
    });

    final user = _repository.currentUser;
    return user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signUp(email: email, password: password);
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repository.signOut();
      state = const AuthUnauthenticated();
    } on AuthException catch (e) {
      state = AuthError(e.message);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    }
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
