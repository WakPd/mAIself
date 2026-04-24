import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final scanMealProvider =
    StateNotifierProvider<ScanMealNotifier, AsyncValue<String?>>((ref) {
  return ScanMealNotifier(ref.watch(aiServiceProvider));
});

class ScanMealNotifier extends StateNotifier<AsyncValue<String?>> {
  final AiService _aiService;
  final ImagePicker _picker = ImagePicker();

  // Garde en mémoire la dernière source pour le bouton "Réessayer"
  ImageSource? _lastSource;
  String? _lastTextDescription;

  ScanMealNotifier(this._aiService) : super(const AsyncValue.data(null));

  /// Analyse via image (caméra ou galerie)
  Future<void> scanMeal(ImageSource source) async {
    _lastSource = source;
    _lastTextDescription = null;
    try {
      state = const AsyncValue.loading();

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (image == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _aiService.analyzeMeal(base64Image);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Analyse via description textuelle
  Future<void> scanMealFromText(String description) async {
    _lastTextDescription = description;
    _lastSource = null;
    try {
      state = const AsyncValue.loading();
      final result = await _aiService.analyzeMealFromText(description);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Réessaie la dernière analyse (image ou texte)
  Future<void> retry() async {
    if (_lastTextDescription != null) {
      await scanMealFromText(_lastTextDescription!);
    } else if (_lastSource != null) {
      await scanMeal(_lastSource!);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
