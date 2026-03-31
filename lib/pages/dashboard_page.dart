import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Doctor';
    final role = user?.userMetadata?['role'] ?? 'Doctor';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning, $name 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$role Session Active · 29 March 2026', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Today\'s Consults', '14', '↑ 3 more', const Color(0xFF22D3EE)),
              _buildStatCard('FHIR Exported', '12', '↑ 85%', const Color(0xFF818CF8)),
              _buildStatCard('Avg. Doc Time', '2.4m', '↓ 68%', const Color(0xFF34D399)),
              _buildStatCard('Pending Review', '2', 'Attention', const Color(0xFFFBBF24)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Encounters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildEncounterList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String delta, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(delta, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildEncounterList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildEncounterRow('Ramesh Kumar', '10:15 AM', 'Fever, Body Ache', '✓ FHIR Sent', const Color(0xFF34D399)),
          const Divider(height: 1, color: Colors.white10),
          _buildEncounterRow('Priya Sharma', '10:45 AM', 'Diabetes Review', '✓ FHIR Sent', const Color(0xFF34D399)),
          const Divider(height: 1, color: Colors.white10),
          _buildEncounterRow('Suresh Patel', '11:20 AM', 'Chest Pain', '⏳ Pending', const Color(0xFF818CF8)),
        ],
      ),
    );
  }

  Widget _buildEncounterRow(String name, String time, String complaint, String status, Color statusColor) {
    return ListTile(
      title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(complaint, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
