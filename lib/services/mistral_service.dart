import 'dart:convert';
import 'package:http/http.dart' as http;

import '../secret_config.dart';

class MistralService {
  static const String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const String _model = 'mistral-small-latest';

  Future<String> generateIrrigationPlan({
    required String location,
    required String soilType,
    required List<String> crops,
    required int soilHumidity,
    required String weatherDescription,
    required num temperature,
  }) async {
    final prompt = '''Tu es un expert en irrigation agricole.

Contexte de la parcelle :
- Localisation : $location
- Type de sol : $soilType
- Cultures : ${crops.join(', ')}

Données en temps réel :
- Humidité actuelle du sol : $soilHumidity%
- Température actuelle : ${temperature.toStringAsFixed(1)}°C
- Description météo : $weatherDescription

À partir de ces données, rédige un plan d'irrigation détaillé pour la semaine à venir.

Format attendu IMPORTANT :
- Utilise du TEXTE SIMPLE, sans Markdown, sans symboles #, sans listes à puces avec des tirets.
- Organise ta réponse avec des phrases complètes et éventuellement des listes numérotées (1., 2., 3.) uniquement.
- Commence par une courte phrase de synthèse.
- Ensuite, décris clairement :
  1. Les jours d'arrosage recommandés et la fréquence.
  2. La durée de chaque arrosage (en minutes) et/ou le volume approximatif par m².
  3. Les conseils pratiques : économie d'eau, périodes de la journée à privilégier ou à éviter, surveillance de l'humidité, etc.

Très important :
- À la toute fin de ta réponse, ajoute UNE SEULE ligne technique EXACTEMENT sous la forme :
  JOURS_ARROSAGE_CLES: monday,wednesday,friday
- Utilise uniquement ces clés anglaises possibles : monday,tuesday,wednesday,thursday,friday,saturday,sunday.
- Ne rajoute rien d'autre sur cette ligne (pas de texte avant ou après, pas d'explication).
''';

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Tu es un assistant IA spécialisé en irrigation agricole pour les cultures, tu dois être précis et pragmatique.'
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 512,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $mistralApiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API Mistral: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['choices'] is List && data['choices'].isNotEmpty) {
      final choice = data['choices'][0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>;
      final dynamic rawContent = message['content'];

      // L'API Mistral renvoie généralement "content" comme une liste de blocs
      // [{"type": "text", "text": "..."}, ...]. On reconstruit donc le texte.
      if (rawContent is List) {
        final buffer = StringBuffer();
        for (final part in rawContent) {
          if (part is Map<String, dynamic>) {
            final text = part['text'];
            if (text is String && text.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.writeln();
              buffer.write(text);
            }
          }
        }
        final result = buffer.toString();
        if (result.isNotEmpty) {
          return result;
        }
      } else if (rawContent is String && rawContent.isNotEmpty) {
        // Compatibilité si jamais l'API renvoie encore directement une chaîne
        return rawContent;
      }
    }

    throw Exception('Réponse Mistral invalide: ${response.body}');
  }
}
