import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clés et utilitaires
class _Keys {
  static String profileData(String userId) => 'profile_data_$userId';

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ─── Modèle métriques journalières ───────────────────────────────────────────

class DailyMetricsData {
  final int totalCalories;
  final int mealsCount;
  final double hydrationLiters;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final double energy;
  final double sleep;
  final double focus;
  final String? lastAdvice;

  const DailyMetricsData({
    this.totalCalories = 0,
    this.mealsCount = 0,
    this.hydrationLiters = 0.0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.energy = 0.65,
    this.sleep = 0.60,
    this.focus = 0.70,
    this.lastAdvice,
  });

  Map<String, dynamic> toJson() => {
        'totalCalories': totalCalories,
        'mealsCount': mealsCount,
        'hydrationLiters': hydrationLiters,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'energy': energy,
        'sleep': sleep,
        'focus': focus,
        'lastAdvice': lastAdvice,
      };

  factory DailyMetricsData.fromJson(Map<String, dynamic> json) =>
      DailyMetricsData(
        totalCalories: json['totalCalories'] as int? ?? 0,
        mealsCount: json['mealsCount'] as int? ?? 0,
        hydrationLiters: (json['hydrationLiters'] as num?)?.toDouble() ?? 0.0,
        proteinGrams: json['proteinGrams'] as int? ?? 0,
        carbsGrams: json['carbsGrams'] as int? ?? 0,
        fatGrams: json['fatGrams'] as int? ?? 0,
        energy: (json['energy'] as num?)?.toDouble() ?? 0.65,
        sleep: (json['sleep'] as num?)?.toDouble() ?? 0.60,
        focus: (json['focus'] as num?)?.toDouble() ?? 0.70,
        lastAdvice: json['lastAdvice'] as String?,
      );
}

// ─── Modèle paramètres utilisateur ───────────────────────────────────────────

class UserSettings {
  final int calorieGoal;
  final double hydrationGoal;
  final int mealsGoal;
  final double baseEnergy;
  final double baseSleep;
  final double baseFocus;

  const UserSettings({
    this.calorieGoal = 2000,
    this.hydrationGoal = 2.0,
    this.mealsGoal = 3,
    this.baseEnergy = 0.65,
    this.baseSleep = 0.60,
    this.baseFocus = 0.70,
  });

  UserSettings copyWith({
    int? calorieGoal,
    double? hydrationGoal,
    int? mealsGoal,
    double? baseEnergy,
    double? baseSleep,
    double? baseFocus,
  }) =>
      UserSettings(
        calorieGoal: calorieGoal ?? this.calorieGoal,
        hydrationGoal: hydrationGoal ?? this.hydrationGoal,
        mealsGoal: mealsGoal ?? this.mealsGoal,
        baseEnergy: baseEnergy ?? this.baseEnergy,
        baseSleep: baseSleep ?? this.baseSleep,
        baseFocus: baseFocus ?? this.baseFocus,
      );

  Map<String, dynamic> toJson() => {
        'calorieGoal': calorieGoal,
        'hydrationGoal': hydrationGoal,
        'mealsGoal': mealsGoal,
        'baseEnergy': baseEnergy,
        'baseSleep': baseSleep,
        'baseFocus': baseFocus,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        calorieGoal: json['calorieGoal'] as int? ?? 2000,
        hydrationGoal: (json['hydrationGoal'] as num?)?.toDouble() ?? 2.0,
        mealsGoal: json['mealsGoal'] as int? ?? 3,
        baseEnergy: (json['baseEnergy'] as num?)?.toDouble() ?? 0.65,
        baseSleep: (json['baseSleep'] as num?)?.toDouble() ?? 0.60,
        baseFocus: (json['baseFocus'] as num?)?.toDouble() ?? 0.70,
      );
}

// ─── Modèle profil utilisateur complet ───────────────────────────────────────

class UserProfileData {
  final int? age;
  final String? sexe;
  final double? poids;
  final double? taille;
  final String? activite;
  final String? sommeilHabituel;
  final String? niveauStress;
  final String? objectif;
  final String? regime;

  const UserProfileData({
    this.age,
    this.sexe,
    this.poids,
    this.taille,
    this.activite,
    this.sommeilHabituel,
    this.niveauStress,
    this.objectif,
    this.regime,
  });

  UserProfileData copyWith({
    int? age,
    String? sexe,
    double? poids,
    double? taille,
    String? activite,
    String? sommeilHabituel,
    String? niveauStress,
    String? objectif,
    String? regime,
  }) =>
      UserProfileData(
        age: age ?? this.age,
        sexe: sexe ?? this.sexe,
        poids: poids ?? this.poids,
        taille: taille ?? this.taille,
        activite: activite ?? this.activite,
        sommeilHabituel: sommeilHabituel ?? this.sommeilHabituel,
        niveauStress: niveauStress ?? this.niveauStress,
        objectif: objectif ?? this.objectif,
        regime: regime ?? this.regime,
      );

  Map<String, dynamic> toJson() => {
        'age': age,
        'sexe': sexe,
        'poids': poids,
        'taille': taille,
        'activite': activite,
        'sommeilHabituel': sommeilHabituel,
        'niveauStress': niveauStress,
        'objectif': objectif,
        'regime': regime,
      };

  factory UserProfileData.fromJson(Map<String, dynamic> json) =>
      UserProfileData(
        age: json['age'] as int?,
        sexe: json['sexe'] as String?,
        poids: (json['poids'] as num?)?.toDouble(),
        taille: (json['taille'] as num?)?.toDouble(),
        activite: json['activite'] as String?,
        sommeilHabituel: json['sommeilHabituel'] as String?,
        niveauStress: json['niveauStress'] as String?,
        objectif: json['objectif'] as String?,
        regime: json['regime'] as String?,
      );
}

// ─── Service Principal ───────────────────────────────────────────────────────

class PersistenceService {
  static PersistenceService? _instance;
  static PersistenceService get instance =>
      _instance ??= PersistenceService._();
  PersistenceService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'PersistenceService not initialized');
    return _prefs!;
  }

  // ── Daily Metrics (Sur Supabase) ──────────────────────────────────────────

  Future<DailyMetricsData?> loadDailyMetrics(String userId) async {
    try {
      final date = _Keys.todayKey();
      final data = await Supabase.instance.client
          .from('daily_metrics')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();

      if (data == null) return null;
      
      return DailyMetricsData(
        totalCalories: data['total_calories'] as int? ?? 0,
        mealsCount: data['meals_count'] as int? ?? 0,
        hydrationLiters: (data['hydration_liters'] as num?)?.toDouble() ?? 0.0,
        proteinGrams: data['protein_grams'] as int? ?? 0,
        carbsGrams: data['carbs_grams'] as int? ?? 0,
        fatGrams: data['fat_grams'] as int? ?? 0,
        energy: (data['energy'] as num?)?.toDouble() ?? 0.65,
        sleep: (data['sleep'] as num?)?.toDouble() ?? 0.60,
        focus: (data['focus'] as num?)?.toDouble() ?? 0.70,
        lastAdvice: data['last_advice'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyMetrics(String userId, DailyMetricsData data) async {
    try {
      await Supabase.instance.client.from('daily_metrics').upsert({
        'user_id': userId,
        'date': _Keys.todayKey(),
        'total_calories': data.totalCalories,
        'meals_count': data.mealsCount,
        'hydration_liters': data.hydrationLiters,
        'protein_grams': data.proteinGrams,
        'carbs_grams': data.carbsGrams,
        'fat_grams': data.fatGrams,
        'energy': data.energy,
        'sleep': data.sleep,
        'focus': data.focus,
        'last_advice': data.lastAdvice,
      });
    } catch (_) {}
  }

  // ── User Settings (Sur Supabase) ──────────────────────────────────────────

  Future<UserSettings> loadUserSettings(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return const UserSettings();
      
      return UserSettings(
        calorieGoal: data['calorie_goal'] as int? ?? 2000,
        hydrationGoal: (data['hydration_goal'] as num?)?.toDouble() ?? 2.0,
        mealsGoal: data['meals_goal'] as int? ?? 3,
        baseEnergy: (data['base_energy'] as num?)?.toDouble() ?? 0.65,
        baseSleep: (data['base_sleep'] as num?)?.toDouble() ?? 0.60,
        baseFocus: (data['base_focus'] as num?)?.toDouble() ?? 0.70,
      );
    } catch (_) {
      return const UserSettings();
    }
  }

  Future<void> saveUserSettings(String userId, UserSettings settings) async {
    try {
      await Supabase.instance.client.from('user_settings').upsert({
        'user_id': userId,
        'calorie_goal': settings.calorieGoal,
        'hydration_goal': settings.hydrationGoal,
        'meals_goal': settings.mealsGoal,
        'base_energy': settings.baseEnergy,
        'base_sleep': settings.baseSleep,
        'base_focus': settings.baseFocus,
      });
    } catch (_) {}
  }

  // ── User Profile ───────────────────────────────────────────────────────────

  Future<UserProfileData?> loadUserProfile(String userId) async {
    await init();
    final key = _Keys.profileData(userId);
    final raw = _p.getString(key);
    if (raw == null) return null;
    try {
      return UserProfileData.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserProfile(String userId, UserProfileData profile) async {
    await init();
    await _p.setString(
        _Keys.profileData(userId), jsonEncode(profile.toJson()));
  }
}
