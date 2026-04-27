import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

// ─── État des métriques enrichi ───────────────────────────────────────────────

class MetricsState {
  final double energy;
  final double sleep;
  final double focus;
  final String? lastAdvice;

  // Statistiques journalières
  final int totalCaloriesToday;
  final int mealsToday;
  final double hydrationLiters;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  // Paramètres utilisateur
  final int calorieGoal;
  final double hydrationGoal;
  final int mealsGoal;

  MetricsState({
    required this.energy,
    required this.sleep,
    required this.focus,
    this.lastAdvice,
    this.totalCaloriesToday = 0,
    this.mealsToday = 0,
    this.hydrationLiters = 0.0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.calorieGoal = 2000,
    this.hydrationGoal = 2.0,
    this.mealsGoal = 3,
  });

  MetricsState copyWith({
    double? energy,
    double? sleep,
    double? focus,
    String? lastAdvice,
    int? totalCaloriesToday,
    int? mealsToday,
    double? hydrationLiters,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    int? calorieGoal,
    double? hydrationGoal,
    int? mealsGoal,
  }) {
    return MetricsState(
      energy: energy ?? this.energy,
      sleep: sleep ?? this.sleep,
      focus: focus ?? this.focus,
      lastAdvice: lastAdvice ?? this.lastAdvice,
      totalCaloriesToday: totalCaloriesToday ?? this.totalCaloriesToday,
      mealsToday: mealsToday ?? this.mealsToday,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      mealsGoal: mealsGoal ?? this.mealsGoal,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class MetricsNotifier extends StateNotifier<MetricsState> {
  String? _userId;

  MetricsNotifier()
      : super(MetricsState(
          energy: 0.65,
          sleep: 0.60,
          focus: 0.70,
        ));

  /// Charge les métriques du jour depuis le stockage local
  Future<void> loadForUser(String userId) async {
    _userId = userId;

    // Charger les paramètres utilisateur
    final settings = await PersistenceService.instance.loadUserSettings(userId);

    // Charger les métriques du jour
    final daily = await PersistenceService.instance.loadDailyMetrics(userId);

    state = MetricsState(
      energy: daily?.energy ?? settings.baseEnergy,
      sleep: daily?.sleep ?? settings.baseSleep,
      focus: daily?.focus ?? settings.baseFocus,
      lastAdvice: daily?.lastAdvice,
      totalCaloriesToday: daily?.totalCalories ?? 0,
      mealsToday: daily?.mealsCount ?? 0,
      hydrationLiters: daily?.hydrationLiters ?? 0.0,
      proteinGrams: daily?.proteinGrams ?? 0,
      carbsGrams: daily?.carbsGrams ?? 0,
      fatGrams: daily?.fatGrams ?? 0,
      calorieGoal: settings.calorieGoal,
      hydrationGoal: settings.hydrationGoal,
      mealsGoal: settings.mealsGoal,
    );
  }

  /// Recharge les paramètres utilisateur (ex: après modification profil)
  Future<void> reloadSettings(String userId) async {
    _userId = userId;
    final settings = await PersistenceService.instance.loadUserSettings(userId);
    state = state.copyWith(
      calorieGoal: settings.calorieGoal,
      hydrationGoal: settings.hydrationGoal,
      mealsGoal: settings.mealsGoal,
    );
  }

  void updateMetrics(
      double dEnergy, double dSleep, double dFocus, String advice) {
    state = state.copyWith(
      energy: (state.energy + dEnergy).clamp(0.0, 1.0),
      sleep: (state.sleep + dSleep).clamp(0.0, 1.0),
      focus: (state.focus + dFocus).clamp(0.0, 1.0),
      lastAdvice: advice,
    );
    _persist();
  }

  void addMealData({
    int calories = 0,
    int protein = 0,
    int carbs = 0,
    int fat = 0,
  }) {
    state = state.copyWith(
      totalCaloriesToday: state.totalCaloriesToday + calories,
      mealsToday: state.mealsToday + 1,
      proteinGrams: state.proteinGrams + protein,
      carbsGrams: state.carbsGrams + carbs,
      fatGrams: state.fatGrams + fat,
    );
    _persist();
  }

  void addHydration(double liters) {
    state = state.copyWith(
      hydrationLiters: (state.hydrationLiters + liters).clamp(0.0, 5.0),
    );
    _persist();
  }

  /// Sauvegarde les métriques en local
  void _persist() {
    final uid = _userId;
    if (uid == null) return;
    PersistenceService.instance.saveDailyMetrics(
      uid,
      DailyMetricsData(
        totalCalories: state.totalCaloriesToday,
        mealsCount: state.mealsToday,
        hydrationLiters: state.hydrationLiters,
        proteinGrams: state.proteinGrams,
        carbsGrams: state.carbsGrams,
        fatGrams: state.fatGrams,
        energy: state.energy,
        sleep: state.sleep,
        focus: state.focus,
        lastAdvice: state.lastAdvice,
      ),
    );
  }
}

final metricsProvider =
    StateNotifierProvider<MetricsNotifier, MetricsState>((ref) {
  return MetricsNotifier();
});
