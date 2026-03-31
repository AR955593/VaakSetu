import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  // IMPORTANT: For production, secure this API key and do not hardcode it. 
  // Putting a placeholder for now, ensuring that it works when the correct key is substituted.
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE'; // Replace with your actual API key
  static const String _anthropicVersion = '2023-06-01';
  static const String _model = 'claude-sonnet-4-5';

  Future<String> translateText({
    required String originalText,
    required String speakerType,
    required String doctorLanguage,
    required String patientLanguage,
  }) async {
    String prompt = '';

    if (speakerType == 'doctor') {
      prompt =
          'You are a medical interpreter in an Indian hospital. The doctor spoke in $doctorLanguage and said: $originalText. Translate this into $patientLanguage for the patient to understand. Use simple everyday words the patient can understand. Keep medicine names in English but explain them simply. Return only the translated text, nothing else.';
    } else {
      prompt =
          'You are a medical interpreter in an Indian hospital. The patient spoke in $patientLanguage and said: $originalText. Translate this into $doctorLanguage for the doctor. Convert all Hindi or Hinglish symptom descriptions into proper medical English terminology. For example pet dard becomes abdominal pain, sar dard becomes headache, bukhaar becomes fever. Return only the translated text, nothing else.';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': _anthropicVersion,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['content'][0]['text'].toString().trim();
      } else {
        throw Exception('Failed to translate: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Translation API failed: $e');
    }
  }

  Future<Map<String, dynamic>> extractClinicalData(String transcript) async {
    final prompt =
        'You are a clinical AI for Indian healthcare. Extract clinical data from this consultation transcript and return only a JSON object with no markdown and no explanation. The JSON must have these keys: chiefComplaint as a string, symptoms as an array of strings, diagnosis as an array of objects each with name and icd10 keys, medications as an array of objects each with name and dose and frequency and duration keys, managementPlan as a string, followUp as a string, clinicalSummary as a string. Transcript: $transcript';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': _anthropicVersion,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2048,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['content'][0]['text'].toString().trim();

        String cleanJson = textResponse;
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.substring(7);
        } else if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.substring(3);
        }
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }

        return jsonDecode(cleanJson.trim());
      } else {
        throw Exception('Failed to extract data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Extraction API failed: $e');
    }
  }
}
  
