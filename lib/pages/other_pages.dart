import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../consultation_provider.dart';
import '../consultation_models.dart';
import 'package:intl/intl.dart';
import '../api_service.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clinical Notes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('AI-extracted structured clinical data', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 30),
          _buildEmptyState('📋', 'No notes generated yet', 'Process a consultation to see structured clinical notes'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String icon, String title, String sub) {
    return Center(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(sub, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class FhirPage extends StatelessWidget {
  const FhirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FHIR R4 Bundle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('HL7 FHIR compliant resources', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 30),
          _buildEmptyState('🔗', 'No FHIR resources yet', 'Process a consultation to generate FHIR R4 output'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String icon, String title, String sub) {
    return Center(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(sub, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}


class DrugPage extends StatefulWidget {
  const DrugPage({super.key});

  @override
  State<DrugPage> createState() => _DrugPageState();
}

class _DrugPageState extends State<DrugPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  void _search(String query) async {
    if (query.length < 3) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.searchDrug(query);
      setState(() => _results = res['drugs'] ?? []);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Drug Database', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('RxNorm coded · Interaction checker included', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              hintText: 'Search drug name (e.g. Paracetamol)...',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty 
              ? const Center(child: Text('Type a drug name to search...', style: TextStyle(color: Colors.white38, fontSize: 12)))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, idx) {
                    final d = _results[idx];
                    return ListTile(
                      title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(d['genericName'] ?? ''),
                      trailing: Text(d['class'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class IcdPage extends StatefulWidget {
  const IcdPage({super.key});

  @override
  State<IcdPage> createState() => _IcdPageState();
}

class _IcdPageState extends State<IcdPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  void _search(String query) async {
    if (query.length < 3) return;
    setState(() => _isLoading = true);
    // Simulate ICD Search
    setState(() {
       _results = [{"code": "J06.9", "name": "Acute upper respiratory infection", "category": "Respiratory"}];
       _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ICD-10 Lookup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('AI-powered diagnosis code search', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.science, color: Colors.white38),
              hintText: 'Search condition or code...',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty 
              ? const Center(child: Text('Type a condition to find ICD-10 code...', style: TextStyle(color: Colors.white38, fontSize: 12)))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, idx) {
                    final r = _results[idx];
                    return ListTile(
                      title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(r['category'] ?? ''),
                      trailing: Text(r['code'] ?? '', style: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold)),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();
    final history = provider.history;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Encounter History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('All consultations with saved notes', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 20),
          if (history.isEmpty)
             _buildEmptyState('📁', 'No consultations yet', 'Recorded consultations will appear here')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, idx) {
                final session = history[idx];
                return _buildHistoryCard(context, session);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ConsultationSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(session.patientName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF22D3EE))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, yyyy · HH:mm').format(session.date), style: const TextStyle(fontSize: 10, color: Colors.white38)),
            const SizedBox(height: 8),
            Text('Diagnosis: ${session.clinicalData['diagnosis']?.isNotEmpty == true ? session.clinicalData['diagnosis'][0]['name'] : 'N/A'}',
               style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          _showAnalysisDialog(context, session);
        },
      ),
    );
  }

  void _showAnalysisDialog(BuildContext context, ConsultationSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('Analysis: ${session.patientName}', style: const TextStyle(color: Color(0xFF22D3EE))),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                 _buildDialogSection('Chief Complaint', session.clinicalData['chiefComplaint'] ?? 'N/A'),
                 _buildDialogSection('Summary', session.clinicalData['clinicalSummary'] ?? 'N/A'),
                 const Divider(height: 32, color: Colors.white10),
                 const Text('Transcript Preview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 10)),
                 const SizedBox(height: 8),
                 ...session.transcript.take(5).map((m) => Padding(
                   padding: const EdgeInsets.only(bottom: 6),
                   child: Text('${m.speaker.name.toUpperCase()}: ${m.originalText}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                 )).toList(),
                 if (session.transcript.length > 5)
                   const Text('...', style: TextStyle(color: Colors.white38)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDialogSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmptyState(String icon, String title, String sub) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(sub, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Configure VaidyaScribe for your practice', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          _buildSettingsCard('🌐 Language & AI', ['Primary Language: Hindi + English', 'Clinical Specialty: General Medicine']),
          const SizedBox(height: 12),
          _buildSettingsCard('🔗 FHIR & ABDM', ['FHIR Version: R4', 'Server: HAPI FHIR']),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 20, color: Colors.white10),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(d, style: const TextStyle(fontSize: 13, color: Colors.white60)),
          )),
        ],
      ),
    );
  }
}
