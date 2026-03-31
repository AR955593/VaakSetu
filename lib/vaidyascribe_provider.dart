import 'package:flutter/material.dart';

class ConsultationMessage {
  final String speaker;
  final String originalText;
  String translatedText;
  final String timestamp;

  ConsultationMessage({
    required this.speaker,
    required this.originalText,
    this.translatedText = "",
    required this.timestamp,
  });
}

/// Structured AI output extracted from the conversation
class AiClinicalNotes {
  final String chiefComplaint;
  final String doctorObservations;
  final String symptoms;
  final String treatmentDiscussed;
  final String followUp;
  final String rawSummary;

  const AiClinicalNotes({
    this.chiefComplaint = 'Not recorded',
    this.doctorObservations = 'Not recorded',
    this.symptoms = 'Not recorded',
    this.treatmentDiscussed = 'Not mentioned',
    this.followUp = 'Not mentioned',
    this.rawSummary = '',
  });

  /// Parse structured fields from the AI plain-text response
  factory AiClinicalNotes.fromText(String text) {
    String extract(String label) {
      final patterns = [
        RegExp(r'(?:^|\n)\s*\d*\.?\s*' + RegExp.escape(label) + r'\s*[:\-]\s*(.+?)(?=\n\s*\d|\n\s*[A-Z][^\n]*[:\-]|\$)',
          dotAll: true, caseSensitive: false),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(text);
        if (m != null) return m.group(1)!.trim();
      }
      // simple fallback: find any line matching the label
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().contains(label.toLowerCase())) {
          // take rest of the line after the colon, or next line
          final colonIdx = lines[i].indexOf(':');
          if (colonIdx != -1) {
            final after = lines[i].substring(colonIdx + 1).trim();
            if (after.isNotEmpty) return after;
          }
          if (i + 1 < lines.length) return lines[i + 1].trim();
        }
      }
      return 'Not mentioned';
    }

    return AiClinicalNotes(
      chiefComplaint: extract('Chief Complaint'),
      doctorObservations: extract("Doctor's Observations"),
      symptoms: extract("Patient's Reported Symptoms"),
      treatmentDiscussed: extract('Treatment Discussed'),
      followUp: extract('Follow-up'),
      rawSummary: text,
    );
  }
}

class VaidyaScribeProvider extends ChangeNotifier {
  // ── AI Clinical Notes ───────────────────────────────────────────────────────
  AiClinicalNotes? _aiNotes;
  AiClinicalNotes? get aiNotes => _aiNotes;

  bool _isAiLoading = false;
  bool get isAiLoading => _isAiLoading;

  void setAiLoading(bool v) { _isAiLoading = v; notifyListeners(); }

  void setAiResult(String rawText) {
    _aiNotes = AiClinicalNotes.fromText(rawText);
    _isAiLoading = false;
    notifyListeners();
  }

  void clearAiNotes() { _aiNotes = null; notifyListeners(); }
  // ───────────────────────────────────────────────────────────────────────────
  String _activePage = 'dashboard';
  String get activePage => _activePage;

  void showPage(String pageName) {
    _activePage = pageName;
    notifyListeners();
  }

  // Consultation State
  String _activeLocale = "en-IN";
  String get activeLocale => _activeLocale;

  void setLocale(String locale) {
    _activeLocale = locale;
    notifyListeners();
  }

  final List<ConsultationMessage> _messages = [];
  List<ConsultationMessage> get messages => _messages;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  bool _isAutoTranslate = true;
  bool get isAutoTranslate => _isAutoTranslate;

  String _activeSpeaker = "Doctor";
  String get activeSpeaker => _activeSpeaker;

  // Language Preferences for Translation
  String _doctorLang = "English";
  String _patientLang = "Hindi";
  
  String get doctorLang => _doctorLang;
  String get patientLang => _patientLang;

  void setDoctorLang(String lang) { _doctorLang = lang; notifyListeners(); }
  void setPatientLang(String lang) { _patientLang = lang; notifyListeners(); }

  String get targetLangForActiveSpeaker {
    // If Doctor is speaking, translate to Patient's language
    // If Patient is speaking, translate to Doctor's language
    return _activeSpeaker == "Doctor" ? _patientLang : _doctorLang;
  }

  String get transcript {
    return _messages.map((m) => "[${m.speaker}]: ${m.originalText}${m.translatedText.isNotEmpty ? '\n(AI: ${m.translatedText})' : ''}").join("\n");
  }

  void addMessage(String text) {
    if (_isPaused) return;
    final newMessage = ConsultationMessage(
      speaker: _activeSpeaker,
      originalText: text,
      timestamp: DateTime.now().toIso8601String(),
    );
    _messages.add(newMessage);
    notifyListeners();
  }

  void updateLastMessageTranslation(String translation) {
    if (_messages.isNotEmpty) {
      _messages.last.translatedText = translation;
      notifyListeners();
    }
  }

  void clearTranscript() {
    _messages.clear();
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void toggleAutoTranslate() {
    _isAutoTranslate = !_isAutoTranslate;
    notifyListeners();
  }

  void setSpeaker(String speaker) {
    _activeSpeaker = speaker;
    notifyListeners();
  }

  void resetConsultation() {
    _messages.clear();
    _isPaused = false;
    _activeSpeaker = "Doctor";
    notifyListeners();
  }

  // Patient Info
  Map<String, String> _patient = {
    'name': 'Ramesh Kumar',
    'age': '45',
    'gender': 'Male',
    'abha': '91-2847-3819-4891',
    'cc': 'Fever and body ache',
    'enc': 'OPD',
  };
  Map<String, String> get patient => _patient;

  void updatePatient(Map<String, String> newPatient) {
    _patient = newPatient;
    notifyListeners();
  }
}
