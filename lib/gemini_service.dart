import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Set your Gemini API key here or load from a secure config.
  // NEVER commit real API keys to version control.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String _endpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_apiKey';
  
  // Cache for repeated translations
  final Map<String, String> _translationCache = {};

  Future<String> translateText({
    required String originalText,
    required bool isDoctor,
    required String doctorLanguage,
    required String patientLanguage,
  }) async {
    final String cacheKey = '$originalText-$isDoctor-$doctorLanguage-$patientLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    String prompt;
    if (isDoctor) {
      prompt = 'You are a medical interpreter in an Indian hospital. The doctor spoke in $doctorLanguage and said: "$originalText". Translate this into $patientLanguage using simple everyday language. Keep medicine names in English but explain them simply. Return only translated text.';
    } else {
      prompt = 'You are a medical interpreter in an Indian hospital. The patient spoke in $patientLanguage and said: "$originalText". Translate into $doctorLanguage using proper medical terminology. For example pet dard becomes abdominal pain, sar dard becomes headache, bukhaar becomes fever. Return only translated text.';
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String result = data['candidates'][0]['content']['parts'][0]['text'];
        final String cleanResult = result.trim();
        _translationCache[cacheKey] = cleanResult;
        return cleanResult;
      }
    } catch (e) {
      // Ignored intentionally for fallback
    }

    return originalText;
  }

  Future<Map<String, dynamic>> extractClinicalData(String transcript) async {
    final prompt = 'You are a clinical AI for Indian healthcare. Extract structured clinical data and return ONLY valid JSON with:\nchiefComplaint (string),\nsymptoms (array),\ndiagnosis (array of objects with name and icd10),\nmedications (array of objects with name, dose, frequency, duration),\nmanagementPlan (string),\nfollowUp (string),\nclinicalSummary (string).\nTranscript: $transcript';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        // Remove markdown JSON formatting if present
        text = text.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?$'), '').trim();

        return jsonDecode(text) as Map<String, dynamic>;
      }
    } catch (e) {
      // Fall through to empty structure
    }

    return _emptyClinicalData();
  }

  Map<String, dynamic> _emptyClinicalData() {
    return {
      'chiefComplaint': '',
      'symptoms': [],
      'diagnosis': [],
      'medications': [],
      'managementPlan': '',
      'followUp': '',
      'clinicalSummary': ''
    };
  }
}
