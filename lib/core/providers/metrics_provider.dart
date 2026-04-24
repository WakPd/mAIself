import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class MetricsNotifier extends StateNotifier<MetricsState> {
  MetricsNotifier()
      : super(MetricsState(
          energy: 0.75,
          sleep: 0.60,
          focus: 0.80,
        ));

  void updateMetrics(
      double dEnergy, double dSleep, double dFocus, String advice) {
    state = state.copyWith(
      energy: (state.energy + dEnergy).clamp(0.0, 1.0),
      sleep: (state.sleep + dSleep).clamp(0.0, 1.0),
      focus: (state.focus + dFocus).clamp(0.0, 1.0),
      lastAdvice: advice,
    );
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
  }

  void addHydration(double liters) {
    state = state.copyWith(
      hydrationLiters: (state.hydrationLiters + liters).clamp(0.0, 5.0),
    );
  }
}

final metricsProvider =
    StateNotifierProvider<MetricsNotifier, MetricsState>((ref) {
  return MetricsNotifier();
});
