import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/providers/metrics_provider.dart';
import '../../../../core/services/persistence_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Page 1 — Infos de base
  final _ageCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  String _sexe = 'Homme';

  // Page 2 — Mode de vie
  String _activite = 'Modérément actif';
  String _sommeil = 'Bon';
  String _stress = 'Modéré';

  // Page 3 — Objectifs & régime
  String _objectif = 'Maintien';
  String _regime = 'Omnivore';

  // ── Options ──────────────────────────────────────────────────────────────
  final _sexeOptions = ['Homme', 'Femme', 'Autre'];
  final _activiteOptions = ['Sédentaire', 'Légèrement actif', 'Modérément actif', 'Très actif', 'Sportif intensif'];
  final _sommeilOptions = ['Excellent', 'Bon', 'Mauvais'];
  final _stressOptions = ['Faible', 'Modéré', 'Élevé'];
  final _objectifOptions = ['Perte de poids', 'Maintien', 'Prise de masse'];
  final _regimeOptions = ['Omnivore', 'Végétarien', 'Végétalien', 'Sans gluten', 'Cétogène'];

  @override
  void dispose() {
    _ageCtrl.dispose();
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  String? _getUserId() {
    final authState = ref.read(authProvider);
    if (authState is AuthRegistered) return authState.userId;
    return Supabase.instance.client.auth.currentUser?.id;
  }

  // ── Calcul des métriques initiales selon les réponses ───────────────────

  UserSettings _computeInitialSettings() {
    double baseEnergy = 0.65;
    double baseSleep = 0.60;
    double baseFocus = 0.70;

    // Activité → énergie de base
    switch (_activite) {
      case 'Sédentaire':
        baseEnergy = 0.50;
      case 'Légèrement actif':
        baseEnergy = 0.60;
      case 'Modérément actif':
        baseEnergy = 0.68;
      case 'Très actif':
        baseEnergy = 0.78;
      case 'Sportif intensif':
        baseEnergy = 0.85;
    }

    // Sommeil → sommeil de base
    switch (_sommeil) {
      case 'Excellent':
        baseSleep = 0.85;
      case 'Bon':
        baseSleep = 0.65;
      case 'Mauvais':
        baseSleep = 0.40;
    }

    // Stress → focus de base
    switch (_stress) {
      case 'Faible':
        baseFocus = 0.80;
      case 'Modéré':
        baseFocus = 0.65;
      case 'Élevé':
        baseFocus = 0.45;
    }

    // Objectif → calories
    final poids = double.tryParse(_poidsCtrl.text) ?? 70.0;
    final taille = double.tryParse(_tailleCtrl.text) ?? 170.0;
    final age = int.tryParse(_ageCtrl.text) ?? 25;
    final isMale = _sexe == 'Homme';

    // Formule Mifflin-St Jeor simplifiée
    double bmr = isMale
        ? 10 * poids + 6.25 * taille - 5 * age + 5
        : 10 * poids + 6.25 * taille - 5 * age - 161;

    double actFactor = switch (_activite) {
      'Sédentaire' => 1.2,
      'Légèrement actif' => 1.375,
      'Modérément actif' => 1.55,
      'Très actif' => 1.725,
      _ => 1.9,
    };

    int calorieGoal = switch (_objectif) {
      'Perte de poids' => (bmr * actFactor - 400).round(),
      'Prise de masse' => (bmr * actFactor + 400).round(),
      _ => (bmr * actFactor).round(),
    };
    calorieGoal = calorieGoal.clamp(1200, 4000);

    return UserSettings(
      calorieGoal: calorieGoal,
      hydrationGoal: _activite == 'Très actif' || _activite == 'Sportif intensif' ? 3.0 : 2.0,
      mealsGoal: 3,
      baseEnergy: baseEnergy,
      baseSleep: baseSleep,
      baseFocus: baseFocus,
    );
  }

  Future<void> _submit() async {
    final userId = _getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Session expirée. Retourne te connecter.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_ageCtrl.text.isEmpty || _poidsCtrl.text.isEmpty || _tailleCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Remplis toutes les informations de base')),
        );
      }
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu dois être connecté pour finaliser ton profil.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Sauvegarder dans Supabase
      final repo = AuthRepository();
      final settings = _computeInitialSettings();
      
      await repo.saveProfile(
        currentUser.id,
        int.parse(_ageCtrl.text.trim()),
        _sexe,
        double.parse(_poidsCtrl.text.trim()),
        double.parse(_tailleCtrl.text.trim()),
        _activite,
        (settings.baseEnergy * 100).toInt(),
        (settings.baseSleep * 100).toInt(),
        (settings.baseFocus * 100).toInt(),
      );

      // Sauvegarder les settings locaux
      await PersistenceService.instance.saveUserSettings(userId, settings);

      // Sauvegarder le profil complet en local
      await PersistenceService.instance.saveUserProfile(
        userId,
        UserProfileData(
          age: int.tryParse(_ageCtrl.text),
          sexe: _sexe,
          poids: double.tryParse(_poidsCtrl.text),
          taille: double.tryParse(_tailleCtrl.text),
          activite: _activite,
          sommeilHabituel: _sommeil,
          niveauStress: _stress,
          objectif: _objectif,
          regime: _regime,
        ),
      );

      // Mettre à jour les métriques dans le provider
      ref
          .read(metricsProvider.notifier)
          .setMetrics(settings.baseEnergy, settings.baseSleep, settings.baseFocus);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Header ──────────────────────────────────────────
            _buildHeader(),
            // ── Pages ───────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            // ── Navigation ──────────────────────────────────────────────
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Informations de base', 'Mode de vie', 'Objectifs'];
    final icons = [Icons.fingerprint_rounded, Icons.directions_run_rounded, Icons.flag_rounded];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF11212F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icons[_currentPage], color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crée ton jumeau numérique',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    titles[_currentPage],
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${_currentPage + 1}/3',
                style: const TextStyle(
                    color: Colors.white38, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= _currentPage
                        ? const Color(0xFF00E676)
                        : Colors.white12,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionLabel('Qui es-tu ?'),
          const SizedBox(height: 20),
          _buildField(
            controller: _ageCtrl,
            label: 'Âge',
            icon: Icons.cake_outlined,
            suffix: 'ans',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Sexe',
            icon: Icons.person_outline,
            value: _sexe,
            items: _sexeOptions,
            onChanged: (v) => setState(() => _sexe = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _poidsCtrl,
                  label: 'Poids',
                  icon: Icons.monitor_weight_outlined,
                  suffix: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _tailleCtrl,
                  label: 'Taille',
                  icon: Icons.height_outlined,
                  suffix: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoBox(
            '💡 Ces informations permettent à l\'IA de calculer tes besoins nutritionnels personnalisés.',
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionLabel('Ton mode de vie'),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'Activité physique',
            icon: Icons.directions_run_outlined,
            value: _activite,
            items: _activiteOptions,
            onChanged: (v) => setState(() => _activite = v!),
          ),
          const SizedBox(height: 16),
          _buildChoiceGroup(
            label: 'Qualité de ton sommeil habituel',
            options: _sommeilOptions,
            selected: _sommeil,
            colors: const [Color(0xFF85C1E9), Color(0xFF4FC3F7), Color(0xFF1565C0)],
            onChanged: (v) => setState(() => _sommeil = v),
          ),
          const SizedBox(height: 16),
          _buildChoiceGroup(
            label: 'Niveau de stress au quotidien',
            options: _stressOptions,
            selected: _stress,
            colors: const [Color(0xFF00E676), Color(0xFFFFAB40), Color(0xFFEF5350)],
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 24),
          _buildInfoBox(
            'Ces réponses calibrent tes barres d\'énergie, de sommeil et de concentration par défaut.',
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionLabel('Tes objectifs'),
          const SizedBox(height: 20),
          _buildChoiceGroup(
            label: 'Objectif principal',
            options: _objectifOptions,
            selected: _objectif,
            colors: const [Color(0xFF4FC3F7), Color(0xFF00E676), Color(0xFFFFAB40)],
            onChanged: (v) => setState(() => _objectif = v),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Régime alimentaire',
            icon: Icons.restaurant_outlined,
            value: _regime,
            items: _regimeOptions,
            onChanged: (v) => setState(() => _regime = v!),
          ),
          const SizedBox(height: 24),
          // Récapitulatif des barres calculées
          _buildPreview(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final settings = _computeInitialSettings();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.preview_rounded, color: Color(0xFF00E676), size: 16),
            SizedBox(width: 8),
            Text('Aperçu de ta configuration',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          _previewBar('Énergie', settings.baseEnergy, const Color(0xFF00E676)),
          const SizedBox(height: 8),
          _previewBar('Sommeil', settings.baseSleep, const Color(0xFF4FC3F7)),
          const SizedBox(height: 8),
          _previewBar('Concentration', settings.baseFocus, const Color(0xFFFFAB40)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6F00), size: 16),
              const SizedBox(width: 6),
              Text(
                'Objectif calorique : ${settings.calorieGoal} kcal/jour',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Retour'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00E676)))
                : ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage < 2 ? 'Continuer →' : 'Créer mon jumeau',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF141C2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF141C2B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF141C2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChoiceGroup({
    required String label,
    required List<String> options,
    required String selected,
    required List<Color> colors,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(options.length, (i) {
            final isSelected = options[i] == selected;
            final color = colors[i % colors.length];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(options[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.2)
                        : const Color(0xFF141C2B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.white12,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white54, fontSize: 12, height: 1.5),
      ),
    );
  }
}