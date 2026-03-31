enum Speaker {
  doctor,
  patient,
}

class ChatMessage {
  final Speaker speaker;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;
  final String languageLabel;

  ChatMessage({
    required this.speaker,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
    required this.languageLabel,
  });
}

class ConsultationSession {
  final Map<String, dynamic> clinicalData;
  final List<ChatMessage> transcript;
  final DateTime date;
  final String patientName;

  ConsultationSession({
    required this.clinicalData,
    required this.transcript,
    required this.date,
    required this.patientName,
  });
}
