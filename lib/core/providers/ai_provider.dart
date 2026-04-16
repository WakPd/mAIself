import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final scanMealProvider = StateNotifierProvider<ScanMealNotifier, AsyncValue<String?>>((ref) {
  return ScanMealNotifier(ref.watch(aiServiceProvider));
});

class ScanMealNotifier extends StateNotifier<AsyncValue<String?>> {
  final AiService _aiService;
  final ImagePicker _picker = ImagePicker();

  ScanMealNotifier(this._aiService) : super(const AsyncValue.data(null));

  Future<void> scanMeal(ImageSource source) async {
    try {
      state = const AsyncValue.loading();
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800, // reduce image size for API
        imageQuality: 80,
      );

      if (image == null) {
        state = const AsyncValue.data(null); // annulé par l'utilisateur
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

  void reset() {
    state = const AsyncValue.data(null);
  }
}
