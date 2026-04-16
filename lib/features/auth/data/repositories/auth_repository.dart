import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Inscrit l'utilisateur. Retourne son userId même si la confirmation
  /// email est activée (Supabase renvoie le user dans la réponse signUp).
  Future<String?> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.user?.id;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> saveProfile(
    String userId,
    int age,
    String sexe,
    double poids,
    double taille,
    String activite,
  ) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'age': age,
      'sexe': sexe,
      'poids': poids,
      'taille': taille,
      'activite_physique': activite,
    });
  }
}
