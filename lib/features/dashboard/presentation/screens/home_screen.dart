import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/providers/ai_provider.dart';
import '../../../../core/providers/metrics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/avatar_3d_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await ref.read(metricsProvider.notifier).loadForUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthUnauthenticated) context.go('/login');
    });

    final scanState = ref.watch(scanMealProvider);
    final metrics = ref.watch(metricsProvider);

    // ── Listener sur le scan ──────────────────────────────────────────────────
    ref.listen<AsyncValue<String?>>(scanMealProvider, (previous, next) {
      if (next.isLoading || previous == next) return;

      if (next.hasValue && next.value != null) {
        final resultText = next.value!;
        final jsonRegex =
            RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true);
        final match = jsonRegex.firstMatch(resultText);

        String cleanMessage = resultText;
        if (match != null) {
          try {
            final data = jsonDecode(match.group(1)!);
            ref.read(metricsProvider.notifier).updateMetrics(
                  (data['energyDelta'] ?? 0.0).toDouble(),
                  (data['sleepDelta'] ?? 0.0).toDouble(),
                  (data['focusDelta'] ?? 0.0).toDouble(),
                  data['shortAdvice'] ?? '',
                );
            ref.read(metricsProvider.notifier).addMealData(
                  calories: (data['calories'] ?? 0) as int,
                  protein: (data['protein'] ?? 0) as int,
                  carbs: (data['carbs'] ?? 0) as int,
                  fat: (data['fat'] ?? 0) as int,
                );
            cleanMessage =
                resultText.replaceFirst(match.group(0)!, '').trim();
          } catch (e) {
            debugPrint("Erreur parsing JSON AI: $e");
          }
        }

        ref.read(scanMealProvider.notifier).reset();
        _showResultDialog(context, ref, cleanMessage);
      } else if (next.hasError) {
        _showErrorDialog(context, ref, next.error.toString());
      }
    });

    final avatarState = computeAvatarState(metrics);
    final avatarColor = _primaryColorForState(avatarState);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: _buildAppBar(avatarColor),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero : Avatar 3D + stats autour ────────────────────────
            _AvatarHeroSection(metrics: metrics, avatarColor: avatarColor),

            // ── Conseil IA ─────────────────────────────────────────────
            if (metrics.lastAdvice != null && metrics.lastAdvice!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _buildAdviceChip(metrics.lastAdvice!, avatarColor),
              ),

            // ── Stats journalières ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _DailyStatsRow(metrics: metrics),
            ),

            // ── Métriques bio ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Métriques biologiques'),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Énergie',
                    icon: Icons.bolt_rounded,
                    value: metrics.energy,
                    color: const Color(0xFF00E676),
                    subtitle: _metricLabel(metrics.energy),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Sommeil',
                    icon: Icons.bedtime_rounded,
                    value: metrics.sleep,
                    color: const Color(0xFF4FC3F7),
                    subtitle: _metricLabel(metrics.sleep),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Concentration',
                    icon: Icons.psychology_rounded,
                    value: metrics.focus,
                    color: const Color(0xFFFFAB40),
                    subtitle: _metricLabel(metrics.focus),
                  ),
                  const SizedBox(height: 80), // espace FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _ScanFAB(
        isLoading: scanState.isLoading,
        avatarColor: avatarColor,
        onPressed: () => _showPickerSheet(context, ref),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(Color avatarColor) {
    return AppBar(
      title: const Text(
        'mAISelf 🧬',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF11212F)],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Mon profil',
          onPressed: () => context.push('/profile'),
          icon: Icon(Icons.person_rounded, color: avatarColor),
        ),
        IconButton(
          tooltip: 'Se déconnecter',
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: Icon(Icons.logout_rounded, color: avatarColor.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ── Picker Sheet : Photo / Galerie / Texte ──────────────────────────────────

  void _showPickerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141C2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Analyser un repas',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choisissez une méthode d\'analyse',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Options
              _PickerOption(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF00E676),
                title: 'Prendre une photo',
                subtitle: 'Utiliser la caméra de votre appareil',
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(scanMealProvider.notifier)
                      .scanMeal(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _PickerOption(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF4FC3F7),
                title: 'Galerie',
                subtitle: 'Choisir depuis vos photos',
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(scanMealProvider.notifier)
                      .scanMeal(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _PickerOption(
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFFFAB40),
                title: 'Description textuelle',
                subtitle: 'Décrire votre repas en texte',
                onTap: () {
                  Navigator.pop(ctx);
                  _showTextDescriptionDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog description textuelle ────────────────────────────────────────────

  void _showTextDescriptionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141C2B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✏️ Description du repas',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Décrivez votre repas en détail (ingrédients, quantités…)',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Ex: 200g de poulet grillé, riz basmati, salade verte avec vinaigrette...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF0D1B2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFFFAB40), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(ctx);
                          ref
                              .read(scanMealProvider.notifier)
                              .scanMealFromText(text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAB40),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Analyser',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog résultat ─────────────────────────────────────────────────────────

  void _showResultDialog(
      BuildContext context, WidgetRef ref, String result) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141C2B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF4FC3F7)],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Analyse Nutritionnelle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result,
                  style: const TextStyle(
                      color: Colors.white70, height: 1.6, fontSize: 14),
                ),
              ),
            ),
            // Bouton Fermer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Fermer l\'analyse',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog erreur + Réessayer ───────────────────────────────────────────────

  void _showErrorDialog(
      BuildContext context, WidgetRef ref, String errorMsg) {
    // Nettoie le message d'erreur
    final clean = errorMsg
        .replaceAll('Exception: ', '')
        .replaceAll('Erreur lors de la communication avec l\'IA: Exception: ',
            '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141C2B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône erreur
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'analyse',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                clean,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              // Bouton Réessayer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(scanMealProvider.notifier).retry();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFAB40),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(scanMealProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Fermer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Color _primaryColorForState(AvatarState state) => switch (state) {
        AvatarState.energized => const Color(0xFF00E676),
        AvatarState.normal => const Color(0xFF4FC3F7),
        AvatarState.tired => const Color(0xFF78909C),
        AvatarState.focused => const Color(0xFFFF6F00),
      };

  String _metricLabel(double value) {
    if (value >= 0.8) return '${(value * 100).toInt()}% — Excellent';
    if (value >= 0.6) return '${(value * 100).toInt()}% — Bon';
    if (value >= 0.4) return '${(value * 100).toInt()}% — Moyen';
    return '${(value * 100).toInt()}% — Faible';
  }

  Widget _buildAdviceChip(String advice, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              advice,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: color),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Hero Avatar ──────────────────────────────────────────────────────

class _AvatarHeroSection extends StatelessWidget {
  final MetricsState metrics;
  final Color avatarColor;

  const _AvatarHeroSection(
      {required this.metrics, required this.avatarColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1B2A),
            avatarColor.withValues(alpha: 0.08),
            const Color(0xFF0A0E1A),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'JUMEAU NUMÉRIQUE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: avatarColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 2),
          const Text('État en temps réel',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 16),

          // Avatar centré avec stats sur les côtés
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stats gauche
              _VerticalStats(
                items: [
                  _StatMini(
                      label: 'Repas',
                      value: '${metrics.mealsToday}',
                      unit: 'auj.',
                      color: const Color(0xFF00E676)),
                  const SizedBox(height: 16),
                  _StatMini(
                      label: 'Protéines',
                      value: '${metrics.proteinGrams}',
                      unit: 'g',
                      color: const Color(0xFF4FC3F7)),
                ],
              ),

              const SizedBox(width: 8),

              // Avatar 3D
              Avatar3DWidget(metrics: metrics),

              const SizedBox(width: 8),

              // Stats droite
              _VerticalStats(
                items: [
                  _StatMini(
                      label: 'Calories',
                      value: '${metrics.totalCaloriesToday}',
                      unit: 'kcal',
                      color: const Color(0xFFFFAB40)),
                  const SizedBox(height: 16),
                  _StatMini(
                      label: 'Glucides',
                      value: '${metrics.carbsGrams}',
                      unit: 'g',
                      color: const Color(0xFFFF6F00)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalStats extends StatelessWidget {
  final List<Widget> items;
  const _VerticalStats({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatMini(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1),
          ),
          Text(
            unit,
            style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Ligne de stats journalières ─────────────────────────────────────────────

class _DailyStatsRow extends StatelessWidget {
  final MetricsState metrics;
  const _DailyStatsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final calorieGoal = metrics.calorieGoal;
    final calPercent = (metrics.totalCaloriesToday / calorieGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Bilan du jour'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyStat(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: '${metrics.totalCaloriesToday} / $calorieGoal kcal',
                color: const Color(0xFFFF6F00),
                progress: calPercent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyStat(
                icon: Icons.restaurant_rounded,
                label: 'Repas',
                value: '${metrics.mealsToday} / ${metrics.mealsGoal} repas',
                color: const Color(0xFF00E676),
                progress: (metrics.mealsToday / metrics.mealsGoal).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Macros bar
        _MacroBar(metrics: metrics),
      ],
    );
  }
}

class _DailyStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _DailyStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: progress),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final MetricsState metrics;
  const _MacroBar({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total =
        (metrics.proteinGrams + metrics.carbsGrams + metrics.fatGrams)
            .toDouble();
    final hasData = total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart_rounded, color: Colors.white54, size: 16),
            SizedBox(width: 6),
            Text('Macronutriments',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          hasData
              ? _buildMacroLine(total)
              : const Text('Scannez un repas pour voir les macros',
                  style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
          if (hasData) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroChip('🥩 P', '${metrics.proteinGrams}g',
                    const Color(0xFF4FC3F7)),
                _MacroChip('🌾 G', '${metrics.carbsGrams}g',
                    const Color(0xFFFFEB3B)),
                _MacroChip('🫒 L', '${metrics.fatGrams}g',
                    const Color(0xFFFF6F00)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroLine(double total) {
    final pPct = metrics.proteinGrams / total;
    final cPct = metrics.carbsGrams / total;
    final fPct = metrics.fatGrams / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
                flex: (pPct * 100).round(),
                child: Container(color: const Color(0xFF4FC3F7))),
            Expanded(
                flex: (cPct * 100).round(),
                child: Container(color: const Color(0xFFFFEB3B))),
            Expanded(
                flex: (fPct * 100).round(),
                child: Container(color: const Color(0xFFFF6F00))),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

// ─── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final IconData icon;
  final double value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              const Spacer(),
              Text('${(value * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: value),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ─── FAB Scan ─────────────────────────────────────────────────────────────────

class _ScanFAB extends StatelessWidget {
  final bool isLoading;
  final Color avatarColor;
  final VoidCallback onPressed;

  const _ScanFAB({
    required this.isLoading,
    required this.avatarColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: avatarColor,
      foregroundColor: Colors.black,
      elevation: 10,
      icon: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2.5))
          : const Icon(Icons.document_scanner_rounded),
      label: Text(
        isLoading ? 'Analyse en cours...' : 'Scanner mon repas',
        style:
            const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: Colors.white38),
    );
  }
}

// ─── Picker Option ────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
