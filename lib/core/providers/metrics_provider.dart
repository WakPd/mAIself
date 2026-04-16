import 'package:flutter_riverpod/flutter_riverpod.dart';

class MetricsState {
  final double energy;
  final double sleep;
  final double focus;
  final String? lastAdvice;

  MetricsState({
    required this.energy,
    required this.sleep,
    required this.focus,
    this.lastAdvice,
  });

  MetricsState copyWith({
    double? energy,
    double? sleep,
    double? focus,
    String? lastAdvice,
  }) {
    return MetricsState(
      energy: energy ?? this.energy,
      sleep: sleep ?? this.sleep,
      focus: focus ?? this.focus,
      lastAdvice: lastAdvice ?? this.lastAdvice,
    );
  }
}

class MetricsNotifier extends StateNotifier<MetricsState> {
  MetricsNotifier() : super(MetricsState(energy: 0.75, sleep: 0.60, focus: 0.80));

  void updateMetrics(double dEnergy, double dSleep, double dFocus, String advice) {
    state = state.copyWith(
      energy: (state.energy + dEnergy).clamp(0.0, 1.0),
      sleep: (state.sleep + dSleep).clamp(0.0, 1.0),
      focus: (state.focus + dFocus).clamp(0.0, 1.0),
      lastAdvice: advice,
    );
  }
}

final metricsProvider = StateNotifierProvider<MetricsNotifier, MetricsState>((ref) {
  return MetricsNotifier();
});
