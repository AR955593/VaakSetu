import 'package:flutter/material.dart';

class ClinicalNotesScreen extends StatelessWidget {
  final Map<String, dynamic>? notesData;

  const ClinicalNotesScreen({super.key, this.notesData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Notes')),
      body: notesData == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('No notes generated yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Process a consultation to see structured notes', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Subjective', notesData?['subjective'] ?? 'No data provided'),
                  _buildSection('Objective', notesData?['objective'] ?? 'No data provided'),
                  _buildSection('Assessment', notesData?['assessment'] ?? 'No data provided'),
                  _buildSection('Plan', notesData?['plan'] ?? 'No data provided'),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF22D3EE))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(content, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
