import "package:flutter_riverpod/flutter_riverpod.dart";

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier() : super(AuthStatus.initial);

  Future<void> login() async {
    state = AuthStatus.loading;
    state = AuthStatus.authenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier();
});
