import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vaidyascribe_provider.dart';
import '../pdf_service.dart';

class ClinicalNotesPage extends StatelessWidget {
  const ClinicalNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaidyaScribeProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    final doctorName = user?.userMetadata?['full_name'] ?? 'Dr. Vaidya';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, provider, doctorName),
          const SizedBox(height: 20),

          // Show loader while AI is processing
          if (provider.isAiLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(children: [
                  CircularProgressIndicator(color: Color(0xFF22D3EE)),
                  SizedBox(height: 16),
                  Text('AI is summarizing the consultation…',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),
            )

          // No consultation recorded yet
          else if (provider.messages.isEmpty && provider.aiNotes == null)
            _buildEmptyState(context, provider)

          // Consultation recorded but not yet summarized
          else if (provider.aiNotes == null && provider.messages.isNotEmpty)
            _buildUnsummarizedState(context, provider, doctorName)

          // Real AI-derived clinical notes
          else if (provider.aiNotes != null)
            _buildAiNotesGrid(context, provider, doctorName)
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, VaidyaScribeProvider provider, String doctorName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Extracted from actual doctor-patient conversation · ABDM Ready',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        if (provider.aiNotes != null)
          ElevatedButton.icon(
            onPressed: () => _generatePdf(context, provider, doctorName),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22D3EE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  // ── Empty States ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, VaidyaScribeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off, size: 56, color: Colors.white12),
            const SizedBox(height: 16),
            const Text('No consultation recorded yet',
                style: TextStyle(fontSize: 16, color: Colors.white38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Go to "New Consult", record the doctor-patient conversation,\nthen tap "Summarize Conversation".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.showPage('record'),
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsummarizedState(BuildContext context, VaidyaScribeProvider provider, String doctorName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show the raw transcript so the doctor can see what was captured
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Text('Consultation recorded — not yet summarized',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              const Text('Conversation captured:', style: TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 8),
              Text(
                provider.messages
                    .map((m) => '[${m.speaker}]: ${m.originalText}')
                    .join('\n'),
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => provider.showPage('record'),
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Go to Record → Summarize Conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Real AI Notes ─────────────────────────────────────────────────────────
  Widget _buildAiNotesGrid(BuildContext context, VaidyaScribeProvider provider, String doctorName) {
    final notes = provider.aiNotes!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient info banner
        _buildInfoBanner(provider),
        const SizedBox(height: 16),

        // Chief Complaint
        _buildCard('🩺 Chief Complaint', [
          _buildField('Reported by Patient', notes.chiefComplaint),
        ]),
        const SizedBox(height: 12),

        // Doctor Observations
        _buildCard('👨‍⚕️ Doctor\'s Observations', [
          _buildField('What the doctor noted', notes.doctorObservations),
        ]),
        const SizedBox(height: 12),

        // Symptoms
        _buildCard('🤒 Patient\'s Reported Symptoms', [
          _buildField('Symptoms described', notes.symptoms),
        ]),
        const SizedBox(height: 12),

        // Treatment
        _buildCard('💊 Treatment Discussed', [
          _buildField('Medications / Plan mentioned by doctor', notes.treatmentDiscussed),
          if (notes.treatmentDiscussed.toLowerCase().contains('not mentioned'))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'No prescription was given during this consultation. '
                    'Diagnosis and medications above would have been explicitly discussed.',
                    style: TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 12),

        // Follow-up
        _buildCard('📅 Follow-up', [
          _buildField('Next steps / revisit date', notes.followUp),
        ]),
        const SizedBox(height: 12),

        // Full Transcript collapsible
        _buildTranscriptCard(provider),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoBanner(VaidyaScribeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF22D3EE).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_outlined, color: Color(0xFF22D3EE), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Extracted from actual consultation · ${provider.messages.length} utterances recorded · '
            '${provider.messages.where((m) => m.speaker == "Doctor").length} Doctor · '
            '${provider.messages.where((m) => m.speaker == "Patient").length} Patient',
            style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 11),
          ),
        ),
      ]),
    );
  }

  Widget _buildTranscriptCard(VaidyaScribeProvider provider) {
    return Theme(
      data: ThemeData(
        colorScheme: const ColorScheme.dark(),
        dividerColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ExpansionTile(
          leading: const Text('📜', style: TextStyle(fontSize: 16)),
          title: const Text('Full Conversation Transcript',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          children: provider.messages.map((msg) {
            final isDoctor = msg.speaker == 'Doctor';
            final color = isDoctor ? const Color(0xFF22D3EE) : const Color(0xFFFBBF24);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isDoctor ? '👨‍⚕️' : '🤒', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${msg.speaker}: ',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        TextSpan(
                          text: msg.originalText,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14)),
          const Divider(height: 24, color: Colors.white10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, VaidyaScribeProvider provider, String doctorName) async {
    final notes = provider.aiNotes;
    final List<Map<String, String>> medications = [];

    // Only add medications if treatment was actually mentioned
    if (notes != null && !notes.treatmentDiscussed.toLowerCase().contains('not mentioned')) {
      medications.add({
        'name': notes.treatmentDiscussed,
        'instruction': 'As discussed',
        'duration': notes.followUp.contains('not mentioned') ? 'As directed' : notes.followUp,
      });
    }

    await PdfService.generateConsultationPdf(
      doctorName: doctorName,
      patientInfo: provider.patient,
      messages: provider.messages,
      medications: medications,
      diagnosis: notes?.treatmentDiscussed ?? 'Not determined during consultation',
    );
  }
}
