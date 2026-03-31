import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vaidyascribe_flutter/vaidyascribe_provider.dart';

class PdfService {
  static Future<void> generateConsultationPdf({
    required String doctorName,
    required Map<String, String> patientInfo,
    required List<ConsultationMessage> messages,
    required List<Map<String, String>> medications,
    required String diagnosis,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VaakSetu Medical Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan)),
                    pw.Text('AI-Generated Clinical Summary', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(doctorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Consultation Date: 29 March 2026', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.cyan),
            pw.SizedBox(height: 20),

            // Patient Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPatientDetail('Name', patientInfo['name'] ?? ''),
                  _buildPatientDetail('Age/Sex', '${patientInfo['age']} / ${patientInfo['gender']}'),
                  _buildPatientDetail('ABHA ID', patientInfo['abha'] ?? ''),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Clinical Diagnosis
            pw.Text('Clinical Diagnosis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(diagnosis.isNotEmpty ? diagnosis : 'Acute Viral Syndrome (Suspected)'),
            pw.SizedBox(height: 30),

            // Medications
            pw.Text('Prescription (Rx)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Medicine Name', isHeader: true),
                    _buildTableCell('Instruction', isHeader: true),
                    _buildTableCell('Duration', isHeader: true),
                  ],
                ),
                ...medications.map((m) => pw.TableRow(
                  children: [
                    _buildTableCell(m['name'] ?? ''),
                    _buildTableCell(m['instruction'] ?? ''),
                    _buildTableCell(m['duration'] ?? ''),
                  ],
                )).toList(),
              ],
            ),
            pw.SizedBox(height: 30),

            // Transcript
            pw.Text('Consultation Transcript', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...messages.map((msg) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(msg.speaker, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue)),
                  pw.Text(msg.originalText, style: const pw.TextStyle(fontSize: 11)),
                  if (msg.translatedText.isNotEmpty)
                    pw.Text('AI Translation: ${msg.translatedText}', style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ],
              ),
            )).toList(),
            
            pw.SizedBox(height: 50),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Divider(thickness: 1, color: PdfColors.black, indent: 100),
                    pw.Text('Digital Signature of Registered Medical Practitioner'),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save and preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'VaakSetu_Report_${patientInfo['name']}.pdf',
    );
  }

  static pw.Widget _buildPatientDetail(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10),
      ),
    );
  }
}
