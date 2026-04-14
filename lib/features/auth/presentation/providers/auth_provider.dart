import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// ─── Sealed State ────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentifié avec session complète (ex: après signIn)
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

/// Inscrit mais email en attente de confirmation.
/// [userId] est disponible pour sauvegarder le profil immédiatement.
final class AuthRegistered extends AuthState {
  final String userId;
  const AuthRegistered(this.userId);
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  final _repository = AuthRepository();

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repository.signIn(email, password);
      state = const AuthAuthenticated();
    } catch (e) {
      state = AuthError(_friendlyError(e.toString()));
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthLoading();
    try {
      final userId = await _repository.signUp(email, password);
      if (userId != null) {
        // userId disponible → on va au profile-setup même sans session confirmée
        state = AuthRegistered(userId);
      } else {
        state = const AuthError(
          'Inscription impossible. Vérifie ton e-mail et réessaie.',
        );
      }
    } catch (e) {
      state = AuthError(_friendlyError(e.toString()));
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(_friendlyError(e.toString()));
    }
  }

  /// Traduit les messages d'erreur Supabase en français lisible
  String _friendlyError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (raw.contains('User already registered')) {
      return 'Ce compte existe déjà. Connecte-toi.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Confirme ton e-mail avant de te connecter.';
    }
    if (raw.contains('over_email_send_rate_limit') || raw.contains('rate limit exceeded')) {
      return 'Trop de tentatives. Attends un peu avant de réessayer ou désactive la confirmation email sur Supabase.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'Pas de connexion Internet.';
    }
    return raw;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
