import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/ai_provider.dart';
import '../../../../core/providers/metrics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthUnauthenticated) {
        context.go('/login');
      }
    });

    final scanState = ref.watch(scanMealProvider);
    final metrics = ref.watch(metricsProvider);

    ref.listen<AsyncValue<String?>>(scanMealProvider, (previous, next) {
      if (!next.isLoading && next.hasValue && next.value != null) {
        final resultText = next.value!;
        
        // Extraction du JSON
        final jsonRegex = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true);
        final match = jsonRegex.firstMatch(resultText);
        
        String cleanMessage = resultText;
        if (match != null) {
          try {
            final jsonStr = match.group(1)!;
            final data = jsonDecode(jsonStr);
            ref.read(metricsProvider.notifier).updateMetrics(
              (data['energyDelta'] ?? 0.0).toDouble(),
              (data['sleepDelta'] ?? 0.0).toDouble(),
              (data['focusDelta'] ?? 0.0).toDouble(),
              data['shortAdvice'] ?? "",
            );
            // On retire le bloc JSON du message final affiché
            cleanMessage = resultText.replaceFirst(match.group(0)!, '').trim();
          } catch (e) {
            debugPrint("Erreur parsing JSON AI: $e");
          }
        }

        _showScanResult(context, cleanMessage);
        ref.read(scanMealProvider.notifier).reset();
      } else if (!next.isLoading && next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: AppBar(
        title: const Text(
          'mAISelf 🧬',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Voici l'état de ton jumeau numérique aujourd'hui",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),

              // ── Cartes de métriques ──
              _MetricCard(
                label: 'Énergie',
                emoji: '⚡',
                value: metrics.energy,
                color: const Color(0xFF4CAF50),
                subtitle: '${(metrics.energy * 100).toInt()}% — Niveau ajusté',
              ),
              const SizedBox(height: 16),
              _MetricCard(
                label: 'Sommeil',
                emoji: '😴',
                value: metrics.sleep,
                color: const Color(0xFF2196F3),
                subtitle: '${(metrics.sleep * 100).toInt()}% — Niveau ajusté',
              ),
              const SizedBox(height: 16),
              _MetricCard(
                label: 'Concentration',
                emoji: '🎯',
                value: metrics.focus,
                color: const Color(0xFFFF9800),
                subtitle: '${(metrics.focus * 100).toInt()}% — Niveau ajusté',
              ),
              if (metrics.lastAdvice != null && metrics.lastAdvice!.isNotEmpty) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        const Color(0xFF2196F3).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          metrics.lastAdvice!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanState.isLoading 
            ? null 
            : () => _showPickerOptions(context, ref),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: scanState.isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.camera_alt_outlined),
        label: Text(
          scanState.isLoading ? 'Analyse en cours...' : 'Scanner mon repas',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showPickerOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(scanMealProvider.notifier).scanMeal(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(scanMealProvider.notifier).scanMeal(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showScanResult(BuildContext context, String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analyse du Repas 🥗'),
        content: SingleChildScrollView(child: Text(result)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ─── Widget interne : carte de métrique ───────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.emoji,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final String emoji;
  final double value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: value),
              builder: (context, animatedValue, child) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
