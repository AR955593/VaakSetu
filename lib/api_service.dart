import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Set your Gemini API key here or load from a secure config.
  // NEVER commit real API keys to version control.
  static const String _apiKey = 'AIzaSyDW0_3eghVAFOXwbz0X4_jXnGzzEb4iU8M';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_apiKey';

  static Future<Map<String, dynamic>> processConsult({
    required String prompt,
    required String transcript,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$prompt\n\nTranscript:\n$transcript'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
        return {'summary': textResponse.trim()};
      } else {
        throw Exception('Failed to process consult: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing consultation: $e');
    }
  }

  static Future<Map<String, dynamic>> trainModel() async {
    return {'status': 'success', 'message': 'Model training disabled on device'};
  }

  static Future<Map<String, dynamic>> searchDrug(String query) async {
    return {'status': 'success', 'results': []};
  }

  static Future<String> translateText(String text, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Translate the following text into $targetLang: "$text". Return only the translated text.'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        return text; // Fallback
      }
    } catch (_) {
      return text;
    }
  }
}
