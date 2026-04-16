import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey;
  final String baseUrl;
  final String model;

  AiService()
      : apiKey = dotenv.env['AI_API_KEY'] ?? '',
        baseUrl = dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai/v1',
        model = dotenv.env['AI_MODEL'] ?? 'llama-3.2-11b-vision-preview';

  /// Analyse une image encodée en base64 pour estimer les valeurs nutritionnelles du repas
  Future<String?> analyzeMeal(String base64Image) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_AI_API_KEY') {
      throw Exception("Clé API non configurée. Veuillez vérifier votre fichier .env");
    }

    final url = Uri.parse('$baseUrl/chat/completions');
    
    // Format requis par l'API compatible OpenAI (Groq / OpenRouter)
    final Map<String, dynamic> body = {
      "model": model,
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": "Analyse ce repas et donne-moi une estimation de ses valeurs nutritionnelles (calories, protéines, glucides, lipides, etc.) de manière claire et concise. Tu dois aussi recommander s'il est sain, et donner un conseil pour le jumeau numérique. À la TERME de ta réponse, tu DOIS inclure un bloc JSON strict entouré par ```json et ``` contenant l'impact de ce repas sur 3 métriques (énergie, sommeil, concentration) de -0.15 à +0.15, ainsi qu'un conseil court (max 12 mots) pour optimiser la journée. Par exemple: ```json\n{\"energyDelta\": 0.10, \"sleepDelta\": -0.05, \"focusDelta\": 0.05, \"shortAdvice\": \"Boîre de l'eau pour stabiliser l'énergie.\"} \n```",
            },
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,$base64Image"
              }
            }
          ]
        }
      ],
      "max_tokens": 800,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          // L'en-tête suivant est souvent utile pour OpenRouter :
          'HTTP-Referer': 'https://maiself.app', 
          'X-Title': 'mAISelf',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception("Erreur de l'IA: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur lors de la communication avec l'IA: $e");
    }
  }
}
