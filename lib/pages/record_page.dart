import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../consultation_provider.dart';
import '../consultation_models.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = context.read<ConsultationProvider>();
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.errorMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageSelectors(provider),
              const SizedBox(height: 16),
              _buildSpeakerToggle(provider),
              const SizedBox(height: 20),
              _buildRecordingControls(provider),
              const SizedBox(height: 20),
              if (provider.liveTranscriptText.isNotEmpty)
                _buildLiveTranscript(provider),
              const SizedBox(height: 20),
              _buildTranscriptPanel(provider),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.messages.isEmpty || provider.isProcessingEnd
                      ? null
                      : () => provider.endConsultation(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('End Consultation & Generate PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        if (provider.isProcessingEnd)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF22D3EE)),
                  SizedBox(height: 16),
                  Text('Processing Consultation...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageSelectors(ConsultationProvider provider) {
    final langs = ['English', 'Hindi', 'Hinglish'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.translate, size: 16, color: Color(0xFF22D3EE)),
              SizedBox(width: 8),
              Text('Translation Languages',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLangDropdown('Doctor speaks:', provider.doctorLanguage, langs, (v) {
                  provider.setDoctorLanguage(v!);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLangDropdown('Patient speaks:', provider.patientLanguage, langs, (v) {
                  provider.setPatientLanguage(v!);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangDropdown(String label, String value, List<String> langs, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F172A),
          underline: Container(height: 1, color: const Color(0xFF22D3EE).withValues(alpha: 0.3)),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: langs.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSpeakerToggle(ConsultationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who is speaking right now?',
            style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildToggleBtn(
                '👨‍⚕️ Doctor',
                provider.currentSpeaker == Speaker.doctor,
                () => provider.setSpeaker(Speaker.doctor),
                const Color(0xFF22D3EE),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleBtn(
                '🤒 Patient',
                provider.currentSpeaker == Speaker.patient,
                () => provider.setSpeaker(Speaker.patient),
                Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap, Color activeColor) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Colors.transparent : Colors.white10, width: 1.5),
          boxShadow: active
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 8)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls(ConsultationProvider provider) {
    return Center(
      child: Column(
        children: [
          FloatingActionButton.large(
            onPressed: () {
              if (provider.isRecording) {
                provider.stopRecording();
              } else {
                provider.startRecording();
              }
            },
            backgroundColor: provider.isRecording ? Colors.red : const Color(0xFF22D3EE),
            child: Icon(
                provider.isRecording ? Icons.stop : Icons.mic_none_rounded,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            provider.isRecording ? 'RECORDING... (${provider.currentSpeaker.name.toUpperCase()})' : 'TAP TO START',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscript(ConsultationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF22D3EE).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hearing, size: 14, color: Color(0xFF22D3EE)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "${provider.liveTranscriptText}...",
              style: const TextStyle(
                  color: Color(0xFF22D3EE), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptPanel(ConsultationProvider provider) {
    if (provider.messages.isEmpty && !provider.isTranslating) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 32),
            SizedBox(height: 8),
            Text('No conversation yet',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${provider.messages.length} messages',
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.messages.length,
            itemBuilder: (context, index) {
              final msg = provider.messages[index];
              final isDoctor = msg.speaker == Speaker.doctor;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Align(
                  alignment: isDoctor ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDoctor ? const Color(0xFF22D3EE).withValues(alpha: 0.1) : Colors.purpleAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDoctor ? const Color(0xFF22D3EE).withValues(alpha: 0.3) : Colors.purpleAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isDoctor ? "👨‍⚕️ Doctor" : "🤒 Patient",
                              style: TextStyle(
                                  color: isDoctor ? const Color(0xFF22D3EE) : Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                            const Spacer(),
                            Text(DateFormat('HH:mm').format(msg.timestamp),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(msg.originalText,
                            style:
                                const TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.translatedText,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '[${msg.languageLabel}]',
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (provider.isTranslating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                  ),
                  SizedBox(width: 8),
                  Text('Translating...', style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
