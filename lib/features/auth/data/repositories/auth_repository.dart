import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpResult {
  final String? userId;
  final bool hasSession;

  const SignUpResult(this.userId, this.hasSession);
}

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Inscrit l'utilisateur.
  ///
  /// Retourne l'userId et le fait de savoir si une session est active.
  Future<SignUpResult> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return SignUpResult(response.user?.id, response.session != null);
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
    int energy,
    int sleep,
    int concentration,
  ) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'age': age,
      'sexe': sexe,
      'poids': poids,
      'taille': taille,
      'activite_physique': activite,
      'energy': energy,
      'sleep': sleep,
      'concentration': concentration,
      'meals_today': 0,
      'total_calories_today': 0,
      'protein_grams_today': 0,
      'carbs_grams_today': 0,
      'fat_grams_today': 0,
      'stats_date': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> fetchDailyStats(String userId) async {
    final response = await _client
        .from('profiles')
        .select(
          'meals_today, total_calories_today, protein_grams_today, carbs_grams_today, fat_grams_today, stats_date, energy, sleep, concentration',
        )
        .eq('id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response;
    }

    return null;
  }

  Future<void> updateBaselineMetrics(
    String userId, {
    required int energy,
    required int sleep,
    required int concentration,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'energy': energy,
      'sleep': sleep,
      'concentration': concentration,
    });
  }

  Future<void> saveDailyStats(
    String userId, {
    int mealsToday = 0,
    int totalCaloriesToday = 0,
    int proteinGramsToday = 0,
    int carbsGramsToday = 0,
    int fatGramsToday = 0,
    required DateTime statsDate,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'meals_today': mealsToday,
      'total_calories_today': totalCaloriesToday,
      'protein_grams_today': proteinGramsToday,
      'carbs_grams_today': carbsGramsToday,
      'fat_grams_today': fatGramsToday,
      'stats_date': statsDate.toIso8601String(),
    });
  }
}
