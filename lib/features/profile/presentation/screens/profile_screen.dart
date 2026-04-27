import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/metrics_provider.dart';
import '../../../../core/services/persistence_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  String? _userId;
  bool _isLoading = false;
  bool _isSaving = false;

  // Profil
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _sexe = 'Homme';
  String _activite = 'Modérément actif';

  // Paramètres
  int _calorieGoal = 2000;
  double _hydrationGoal = 2.0;
  int _mealsGoal = 3;

  final _sexeOptions = ['Homme', 'Femme', 'Autre'];
  final _activiteOptions = [
    'Sédentaire',
    'Légèrement actif',
    'Modérément actif',
    'Très actif',
    'Sportif intensif'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _userId = user.id;

    // Charger profil local
    final profile = await PersistenceService.instance.loadUserProfile(user.id);
    if (profile != null) {
      _poidsCtrl.text = profile.poids?.toString() ?? '';
      _tailleCtrl.text = profile.taille?.toString() ?? '';
      _ageCtrl.text = profile.age?.toString() ?? '';
      _sexe = profile.sexe ?? 'Homme';
      _activite = profile.activite ?? 'Modérément actif';
    } else {
      // Fallback depuis Supabase
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data != null) {
          _poidsCtrl.text = data['poids']?.toString() ?? '';
          _tailleCtrl.text = data['taille']?.toString() ?? '';
          _ageCtrl.text = data['age']?.toString() ?? '';
          _sexe = data['sexe'] ?? 'Homme';
          _activite = data['activite_physique'] ?? 'Modérément actif';
        }
      } catch (_) {}
    }

    // Charger settings
    final settings =
        await PersistenceService.instance.loadUserSettings(user.id);
    _calorieGoal = settings.calorieGoal;
    _hydrationGoal = settings.hydrationGoal;
    _mealsGoal = settings.mealsGoal;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;
    setState(() => _isSaving = true);
    try {
      // Supabase
      await Supabase.instance.client.from('profiles').upsert({
        'id': _userId,
        'age': int.tryParse(_ageCtrl.text),
        'sexe': _sexe,
        'poids': double.tryParse(_poidsCtrl.text),
        'taille': double.tryParse(_tailleCtrl.text),
        'activite_physique': _activite,
      });

      // Local
      await PersistenceService.instance.saveUserProfile(
        _userId!,
        UserProfileData(
          age: int.tryParse(_ageCtrl.text),
          sexe: _sexe,
          poids: double.tryParse(_poidsCtrl.text),
          taille: double.tryParse(_tailleCtrl.text),
          activite: _activite,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil mis à jour'),
            backgroundColor: Color(0xFF00E676),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;
    setState(() => _isSaving = true);
    try {
      final settings = UserSettings(
        calorieGoal: _calorieGoal,
        hydrationGoal: _hydrationGoal,
        mealsGoal: _mealsGoal,
      );
      await PersistenceService.instance.saveUserSettings(_userId!, settings);
      // Recharger dans le provider
      await ref.read(metricsProvider.notifier).reloadSettings(_userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paramètres sauvegardés'),
            backgroundColor: Color(0xFF00E676),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Profil'),
            Tab(icon: Icon(Icons.tune_rounded, size: 20), text: 'Paramètres'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildProfileTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle('📏 Mesures corporelles'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField(_poidsCtrl, 'Poids', 'kg', Icons.monitor_weight_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildField(_tailleCtrl, 'Taille', 'cm', Icons.height_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(_ageCtrl, 'Âge', 'ans', Icons.cake_outlined, keyboard: TextInputType.number),
          const SizedBox(height: 20),
          _sectionTitle('👤 Informations personnelles'),
          const SizedBox(height: 16),
          _buildDropdown('Sexe', _sexe, _sexeOptions, Icons.person_outline,
              (v) => setState(() => _sexe = v!)),
          const SizedBox(height: 12),
          _buildDropdown('Activité physique', _activite, _activiteOptions,
              Icons.directions_run_outlined, (v) => setState(() => _activite = v!)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Sauvegarder le profil',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionTitle('🔥 Objectif calorique'), 
          const SizedBox(height: 4),
          Text(
            '${_calorieGoal} kcal / jour',
            style: const TextStyle(
                color: Color(0xFFFF6F00),
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          Slider(
            value: _calorieGoal.toDouble(),
            min: 1200,
            max: 4000,
            divisions: 56,
            activeColor: const Color(0xFFFF6F00),
            inactiveColor: const Color(0xFFFF6F00).withValues(alpha: 0.15),
            onChanged: (v) => setState(() => _calorieGoal = v.round()),
          ),
          _sliderHints('1200 kcal', '4000 kcal'),
          const SizedBox(height: 24),

          _sectionTitle('💧 Objectif hydratation'),
          const SizedBox(height: 4),
          Text(
            '${_hydrationGoal.toStringAsFixed(1)} L / jour',
            style: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          Slider(
            value: _hydrationGoal,
            min: 1.0,
            max: 4.0,
            divisions: 12,
            activeColor: const Color(0xFF4FC3F7),
            inactiveColor: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
            onChanged: (v) => setState(() => _hydrationGoal = double.parse(v.toStringAsFixed(1))),
          ),
          _sliderHints('1.0 L', '4.0 L'),
          const SizedBox(height: 24),

          _sectionTitle('🍽️ Nombre de repas par jour'),
          const SizedBox(height: 4),
          Text(
            '$_mealsGoal repas',
            style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          Slider(
            value: _mealsGoal.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            activeColor: const Color(0xFF00E676),
            inactiveColor: const Color(0xFF00E676).withValues(alpha: 0.15),
            onChanged: (v) => setState(() => _mealsGoal = v.round()),
          ),
          _sliderHints('2 repas', '6 repas'),
          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.2)),
            ),
            child: const Text(
              '💡 Ces paramètres personnalisent ton tableau de bord. L\'objectif calorique sera utilisé dans la barre de progression.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.tune_rounded),
              label: const Text('Appliquer les paramètres',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      );

  Widget _sliderHints(String left, String right) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(color: Colors.white24, fontSize: 11)),
          Text(right, style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      );

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String suffix,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard ??
          const TextInputType.numberWithOptions(decimal: true),
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
          borderSide:
              const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged,
  ) {
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
}
