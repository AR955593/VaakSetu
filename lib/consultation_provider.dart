import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:typed_data';

import 'consultation_models.dart';
import 'gemini_service.dart';

class ConsultationProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];
  List<ConsultationSession> history = [];
  bool isRecording = false;
  bool isTranslating = false;
  bool isProcessingEnd = false;
  Speaker currentSpeaker = Speaker.doctor;
  String liveTranscriptText = '';
  String? errorMessage;
  Uint8List? pdfBytes;

  String doctorLanguage = 'English';
  String patientLanguage = 'Hindi';

  String patientName = 'Unknown Patient';
  int patientAge = 30;
  String patientGender = 'Male';
  String abhaId = '00-0000-0000-0000';
  String doctorName = 'Dr. Sharma';
  String clinicName = 'VaidyaScribe Clinic';

  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _geminiService = GeminiService();

  Future<void> startRecording() async {
    // If already recording, stop first to be safe
    if (isRecording || _speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    bool hasPermission = true;
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        hasPermission = false;
      }
    }

    if (!hasPermission) {
      errorMessage = 'Microphone permission denied';
      notifyListeners();
      return;
    }

    // Initialize with a clean state
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && isRecording) {
            _restartListeningIfNeeded();
        }
      },
      onError: (errorNotification) {
        // If it's a transient error, we try to handle it
        if (errorNotification.errorMsg == 'error_client') {
           print('Speech error_client detected. Recovery needed.');
        } else {
           errorMessage = 'Speech error: ${errorNotification.errorMsg}';
           isRecording = false;
        }
        notifyListeners();
      },
    );

    if (available) {
      String localeId = 'en_IN';
      if (currentSpeaker == Speaker.doctor) {
        localeId = (doctorLanguage == 'English') ? 'en_IN' : 'hi_IN';
      } else if (currentSpeaker == Speaker.patient) {
        localeId = (patientLanguage == 'English') ? 'en_IN' : 'hi_IN';
      }

      isRecording = true;
      errorMessage = null;
      notifyListeners();

      _speech.listen(
        onResult: (result) async {
          liveTranscriptText = result.recognizedWords;
          notifyListeners();

          if (result.finalResult && liveTranscriptText.isNotEmpty) {
            final textToTranslate = liveTranscriptText;
            final speaker = currentSpeaker;
            liveTranscriptText = '';
            notifyListeners();
            await _translateAndAddMessage(speaker, textToTranslate);
          }
        },
        localeId: localeId,
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 10), // Increased for doctor pauses
      );
    } else {
      errorMessage = 'Speech recognition not available';
      notifyListeners();
    }
  }

  void _restartListeningIfNeeded() {
    if (isRecording) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isRecording && !_speech.isListening) {
          String localeId = 'en_IN';
          if (currentSpeaker == Speaker.doctor) {
            localeId = (doctorLanguage == 'English') ? 'en_IN' : 'hi_IN';
          } else if (currentSpeaker == Speaker.patient) {
            localeId = (patientLanguage == 'English') ? 'en_IN' : 'hi_IN';
          }
          _speech.listen(
            onResult: (result) async {
              liveTranscriptText = result.recognizedWords;
              notifyListeners();
              if (result.finalResult && liveTranscriptText.isNotEmpty) {
                final textToTranslate = liveTranscriptText;
                final speaker = currentSpeaker;
                liveTranscriptText = '';
                notifyListeners();
                await _translateAndAddMessage(speaker, textToTranslate);
              }
            },
            localeId: localeId,
            listenFor: const Duration(minutes: 30),
            pauseFor: const Duration(seconds: 10),
          );
        }
      });
    }
  }

  void stopRecording() {
    _speech.stop();
    isRecording = false;
    liveTranscriptText = '';
    notifyListeners();
  }

  void setSpeaker(Speaker speaker) {
    currentSpeaker = speaker;
    notifyListeners();
  }

  void setDoctorLanguage(String language) {
    doctorLanguage = language;
    notifyListeners();
  }

  void setPatientLanguage(String language) {
    patientLanguage = language;
    notifyListeners();
  }

  Future<void> _translateAndAddMessage(Speaker speaker, String text) async {
    isTranslating = true;
    notifyListeners();

    String translated = text; // Default to original text if translation fails
    try {
      translated = await _geminiService.translateText(
        originalText: text,
        isDoctor: speaker == Speaker.doctor,
        doctorLanguage: doctorLanguage,
        patientLanguage: patientLanguage,
      );
    } catch (e) {
      print('Translation fail: $e');
    }

    String label = speaker == Speaker.doctor
        ? '[Patient ke liye $patientLanguage mein]'
        : '[Doctor ke liye $doctorLanguage mein]';

    messages.add(ChatMessage(
      speaker: speaker,
      originalText: text,
      translatedText: translated,
      timestamp: DateTime.now(),
      languageLabel: label,
    ));

    isTranslating = false;
    notifyListeners();
  }

  Future<void> endConsultation() async {
    if (messages.isEmpty) return;

    isProcessingEnd = true;
    notifyListeners();

    try {
      // Step one: Full transcript
      StringBuffer transcriptBuffer = StringBuffer();
      for (var msg in messages) {
        String role = msg.speaker == Speaker.doctor ? 'Doctor' : 'Patient';
        transcriptBuffer.writeln('$role: ${msg.originalText}');
      }
      String fullTranscript = transcriptBuffer.toString();

      // Step two: Call Gemini API for clinical data
      Map<String, dynamic> clinicalJson =
          await _geminiService.extractClinicalData(fullTranscript);

      // Step three: Generate PDF
      final pdf = pw.Document();
      // Load Font for Devanagari text using google_fonts from printing package
      final devanagariFont = await PdfGoogleFonts.notoSansDevanagariRegular();

      _buildClinicalReportPage(pdf, clinicalJson);
      _buildTranscriptPage(pdf, devanagariFont);

      // Step four: Call Printing.sharePdf
      pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes!,
        filename: 'VaidyaScribe_Report.pdf',
      );

      // Step five: Save to history
      history.insert(0, ConsultationSession(
        clinicalData: clinicalJson,
        transcript: List.from(messages),
        date: DateTime.now(),
        patientName: patientName,
      ));
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to process consultation ending: $e';
    } finally {
      isProcessingEnd = false;
      notifyListeners();
    }
  }

  void _buildClinicalReportPage(pw.Document pdf, Map<String, dynamic> data) {
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
        build: (context) {
          return [
            // Header
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(clinicName,
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(doctorName,
                            style: pw.TextStyle(fontSize: 16)),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                            'Date: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                        pw.Text(
                            'Time: ${intl.DateFormat('HH:mm').format(DateTime.now())}'),
                      ])
                ]),
            pw.SizedBox(height: 20),

            // Patient Info Box
            pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Name: $patientName',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('Age/Sex: $patientAge / $patientGender'),
                            pw.Text('ABHA ID: $abhaId'),
                          ]),
                      pw.Divider(color: PdfColors.grey300),
                      pw.Text(
                          'Chief Complaint: ${data['chiefComplaint'] ?? 'N/A'}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold)),
                    ])),
            pw.SizedBox(height: 15),

            // Diagnosis
            _buildSectionTitle('Diagnosis / ICD-10'),
            _buildDiagnosisList(data['diagnosis']),
            pw.SizedBox(height: 15),

            // Prescription Table
            _buildSectionTitle('Prescription'),
            _buildPrescriptionTable(data['medications']),
            pw.SizedBox(height: 15),

            // Management Plan
            _buildSectionTitle('Management Plan'),
            pw.Text(data['managementPlan']?.toString() ?? 'N/A'),
            pw.SizedBox(height: 15),

            // Follow Up
            _buildSectionTitle('Follow Up'),
            pw.Text(data['followUp']?.toString() ?? 'N/A'),
            pw.SizedBox(height: 15),

            // Clinical Summary (Grey Box)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Clinical Summary'),
                  pw.Text(data['clinicalSummary']?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  void _buildTranscriptPage(pw.Document pdf, pw.Font devanagariFont) {
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: devanagariFont,
          bold: devanagariFont,
          italic: devanagariFont,
        ),
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Generated by VaidyaScribe Pro — Built for Bharat.',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
        build: (context) {
          return [
            pw.Header(
                level: 0,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bilingual Consultation Transcript',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          'Doctor Language: $doctorLanguage | Patient Language: $patientLanguage',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ])),
            pw.SizedBox(height: 10),
            ...messages.map((m) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey300, width: 0.5))),
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 40,
                          child: pw.Text(
                              intl.DateFormat('HH:mm').format(m.timestamp),
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey)),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  m.speaker == Speaker.doctor
                                      ? 'DOCTOR'
                                      : 'PATIENT',
                                  style: pw.TextStyle(
                                    color: m.speaker == Speaker.doctor
                                        ? PdfColors.cyan700
                                        : PdfColors.purple700,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  )),
                              pw.SizedBox(height: 2),
                              pw.Text(m.originalText,
                                  style: const pw.TextStyle(fontSize: 12)),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.only(
                                          right: 5, top: 1),
                                      child: pw.Text('→',
                                          style: const pw.TextStyle(
                                              fontSize: 10,
                                              color: PdfColors.grey600)),
                                    ),
                                    pw.Expanded(
                                      child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text(
                                              m.translatedText,
                                              style: pw.TextStyle(
                                                  fontSize: 12,
                                                  fontStyle:
                                                      pw.FontStyle.italic,
                                                  color: PdfColors.grey800),
                                            ),
                                            pw.SizedBox(height: 2),
                                            pw.Text(
                                              '[${m.languageLabel}]',
                                              style: const pw.TextStyle(
                                                  fontSize: 8,
                                                  color: PdfColors.grey600),
                                            ),
                                          ]),
                                    ),
                                  ])
                            ],
                          ),
                        ),
                      ]),
                )).toList(),
          ];
        },
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800),
      ),
    );
  }

  pw.Widget _buildDiagnosisList(dynamic diagnosisData) {
    final List diagList = (diagnosisData is List) ? diagnosisData : [];
    if (diagList.isEmpty) return pw.Text('No diagnosis recorded');

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: diagList.map((d) {
          String name = d['name']?.toString() ?? '';
          String icd = d['icd10']?.toString() ?? '';
          return pw.Text('• $name ($icd)');
        }).toList());
  }

  pw.Widget _buildPrescriptionTable(dynamic medsData) {
    final List medsList = (medsData is List) ? medsData : [];
    if (medsList.isEmpty) return pw.Text('No medications prescribed');

    return pw.TableHelper.fromTextArray(
      headers: ['Medicine Name', 'Dose', 'Frequency', 'Duration'],
      data: medsList.map((m) {
        return [
          m['name']?.toString() ?? '',
          m['dose']?.toString() ?? '',
          m['frequency']?.toString() ?? '',
          m['duration']?.toString() ?? '',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
}
