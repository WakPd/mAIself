import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _poidsController = TextEditingController();
  final _tailleController = TextEditingController();

  String _sexe = 'Homme';
  String _activite = 'Modérément actif';
  bool _isLoading = false;

  final List<String> _sexeOptions = ['Homme', 'Femme', 'Autre'];
  final List<String> _activiteOptions = [
    'Sédentaire',
    'Modérément actif',
    'Très actif',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _poidsController.dispose();
    _tailleController.dispose();
    super.dispose();
  }

  /// Récupère le userId depuis :
  /// 1. L'état AuthRegistered (inscription sans confirmation)
  /// 2. La session Supabase courante (connexion normale)
  String? _getUserId() {
    final authState = ref.read(authProvider);
    if (authState is AuthRegistered) return authState.userId;
    return Supabase.instance.client.auth.currentUser?.id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Session expirée. Retourne te connecter.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = AuthRepository();
      await repo.saveProfile(
        userId,
        int.parse(_ageController.text.trim()),
        _sexe,
        double.parse(_poidsController.text.trim()),
        double.parse(_tailleController.text.trim()),
        _activite,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Crée ton jumeau numérique 🧬',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ces infos permettent à l'IA de personnaliser ses prédictions",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // ── Âge ──
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Âge',
                    prefixIcon: Icon(Icons.cake_outlined),
                    suffixText: 'ans',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    final parsed = int.tryParse(v);
                    if (parsed == null || parsed < 1 || parsed > 120) {
                      return 'Âge invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Sexe ──
                DropdownButtonFormField<String>(
                  initialValue: _sexe,
                  decoration: const InputDecoration(
                    labelText: 'Sexe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _sexeOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _sexe = v!),
                ),
                const SizedBox(height: 16),

                // ── Poids ──
                TextFormField(
                  controller: _poidsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Poids',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (double.tryParse(v) == null) return 'Valeur invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Taille ──
                TextFormField(
                  controller: _tailleController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Taille',
                    prefixIcon: Icon(Icons.height_outlined),
                    suffixText: 'cm',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (double.tryParse(v) == null) return 'Valeur invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Activité physique ──
                DropdownButtonFormField<String>(
                  initialValue: _activite,
                  decoration: const InputDecoration(
                    labelText: 'Activité physique',
                    prefixIcon: Icon(Icons.directions_run_outlined),
                  ),
                  items: _activiteOptions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _activite = v!),
                ),
                const SizedBox(height: 36),

                // ── Submit ──
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Créer mon jumeau 🧬'),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
