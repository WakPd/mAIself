import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Prompt commun pour extraire les données nutritionnelles + impact métriques
const String _nutritionPromptSuffix =
    "Analyse ce repas et donne-moi une estimation de ses valeurs nutritionnelles "
    "(calories, proteines, glucides, lipides) de maniere claire et concise. "
    "Indique aussi si le repas est sain ou non, et donne un conseil personnalise. "
    "A la FIN de ta reponse, tu DOIS inclure un bloc JSON strict entre les balises "
    "```json et ``` avec ces champs EXACTEMENT : "
    "energyDelta (float entre -0.15 et +0.15), sleepDelta (float), focusDelta (float), "
    "shortAdvice (string max 12 mots), calories (int en kcal), "
    "protein (int en grammes), carbs (int en grammes), fat (int en grammes). "
    'Exemple: ```json\n'
    '{"energyDelta": 0.10, "sleepDelta": -0.05, "focusDelta": 0.05, '
    '"shortAdvice": "Boire de l eau pour stabiliser.", '
    '"calories": 650, "protein": 35, "carbs": 70, "fat": 20}\n'
    '```';

class AiService {
  final String apiKey;
  final String baseUrl;
  final String model;

  AiService()
      : apiKey = dotenv.env['AI_API_KEY'] ?? '',
        baseUrl =
            dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai/v1',
        model = dotenv.env['AI_MODEL'] ?? 'llama-3.2-11b-vision-preview';

  /// Vérifie la clé API
  void _checkApiKey() {
    if (apiKey.isEmpty || apiKey == 'YOUR_AI_API_KEY') {
      throw Exception(
          "Clé API non configurée. Veuillez vérifier votre fichier .env");
    }
  }

  /// Headers communs OpenAI-compatible
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://maiself.app',
        'X-Title': 'mAISelf',
      };

  /// Envoie la requête et décode la réponse
  Future<String?> _sendRequest(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String?;
      } else {
        throw Exception(
            "Erreur de l'IA: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur lors de la communication avec l'IA: $e");
    }
  }

  /// Analyse un repas via une image encodée en base64
  Future<String?> analyzeMeal(String base64Image) async {
    _checkApiKey();

    final body = {
      "model": model,
      "messages": [
        {
          "role": "user",
          "content": [
            {"type": "text", "text": _nutritionPromptSuffix},
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
            }
          ]
        }
      ],
      "max_tokens": 900,
    };

    return _sendRequest(body);
  }

  /// Analyse un repas via une description textuelle
  Future<String?> analyzeMealFromText(String description) async {
    _checkApiKey();

    final body = {
      "model": model,
      "messages": [
        {
          "role": "user",
          "content":
              "Voici la description d'un repas : \"$description\"\n\n$_nutritionPromptSuffix"
        }
      ],
      "max_tokens": 900,
    };

    return _sendRequest(body);
  }
}
