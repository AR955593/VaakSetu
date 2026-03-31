import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vaidyascribe_provider.dart';
import 'pages/dashboard_page.dart';
import 'pages/record_page.dart';
import 'pages/clinical_notes_page.dart';
import 'pages/analytics_page.dart';
import 'pages/other_pages.dart';
import 'pages/auth_pages.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaidyaScribeProvider>();
    final activePage = provider.activePage;

    // Use DateTime.now() to check time difference between two back button presses
    DateTime? lastPressed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final backToastDuration = const Duration(seconds: 2);

        if (lastPressed == null || now.difference(lastPressed!) > backToastDuration) {
          lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit VaakSetu'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Allow popping if pressed within 2 seconds
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppTitle(),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          ],
        ),
        drawer: _buildSidebar(context),
        body: Row(
          children: [
            // Sidebar for Desktop
            if (MediaQuery.of(context).size.width > 900)
               _buildSidebar(context, isDrawer: false),
            Expanded(
              child: _getPage(activePage),
            ),
          ],
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width <= 900 
            ? _buildBottomNav(context, activePage) 
            : null,
      ),
    );
  }

  Widget _buildAppTitle() {
    return Row(
      children: [
        const Text('🩺', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('VaakSetu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PRO', style: TextStyle(color: Color(0xFF22D3EE), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Text('AI Ambient Scribe · Bharat Health Bridge', style: TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = true}) {
    final provider = context.read<VaidyaScribeProvider>();
    final activePage = provider.activePage;
    
    final content = Container(
      width: 240,
      color: const Color(0xFF0F172A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (isDrawer) DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF22D3EE),
                  child: Text('👤', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 12),
                Text(Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Doctor', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(16), child: Text('Main', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
          _buildSidebarItem(context, '📊', 'Dashboard', 'dashboard', activePage, isDrawer),
          _buildSidebarItem(context, '📈', 'Analytics', 'analytics', activePage, isDrawer),
          _buildSidebarItem(context, '🎙️', 'New Consult', 'record', activePage, isDrawer),
          _buildSidebarItem(context, '📋', 'Clinical Notes', 'notes', activePage, isDrawer),
          _buildSidebarItem(context, '🔗', 'FHIR Bundle', 'fhir', activePage, isDrawer),
          const Padding(padding: EdgeInsets.all(16), child: Text('Tools', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
          _buildSidebarItem(context, '💊', 'Drug Database', 'drugdb', activePage, isDrawer),
          _buildSidebarItem(context, '🔬', 'ICD-10 Lookup', 'icd', activePage, isDrawer),
          _buildSidebarItem(context, '📁', 'History', 'history', activePage, isDrawer),
          const Padding(padding: EdgeInsets.all(16), child: Text('Account', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
          _buildSidebarItem(context, '⚙️', 'Settings', 'settings', activePage, isDrawer),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Text('🚪', style: TextStyle(fontSize: 18)),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthSwitcher()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('VaakSetu Healthcare Professional', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );

    return isDrawer ? Drawer(child: content) : content;
  }

  Widget _buildSidebarItem(BuildContext context, String icon, String label, String key, String active, bool isDrawer) {
    bool isActive = active == key;
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 18)),
      title: Text(label, style: TextStyle(color: isActive ? const Color(0xFF22D3EE) : Colors.white70, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        context.read<VaidyaScribeProvider>().showPage(key);
        if (isDrawer) {
          Navigator.pop(context);
        }
      },
      tileColor: isActive ? Colors.white.withValues(alpha: 0.05) : null,
    );
  }

  Widget _buildBottomNav(BuildContext context, String active) {
    int index = 0;
    if (active == 'dashboard') index = 0;
    else if (active == 'record') index = 1;
    else if (active == 'notes') index = 2;
    else if (active == 'fhir') index = 3;
    else if (active == 'history') index = 4;

    return BottomNavigationBar(
      currentIndex: index > 4 ? 0 : index,
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: const Color(0xFF22D3EE),
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.mic_none_rounded), label: 'Record'),
        BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Notes'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'FHIR'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
      ],
      onTap: (idx) {
        String key = 'dashboard';
        if (idx == 1) key = 'record';
        else if (idx == 2) key = 'notes';
        else if (idx == 3) key = 'fhir';
        else if (idx == 4) key = 'history';
        context.read<VaidyaScribeProvider>().showPage(key);
      },
    );
  }

  Widget _getPage(String key) {
    switch (key) {
      case 'dashboard': return const DashboardPage();
      case 'analytics': return const AnalyticsPage();
      case 'record': return const RecordPage();
      case 'notes': return const ClinicalNotesPage();
      case 'fhir': return const FhirPage();
      case 'drugdb': return const DrugPage();
      case 'icd': return const IcdPage();
      case 'history': return const HistoryPage();
      case 'settings': return const SettingsPage();
      default: return const DashboardPage();
    }
  }
}
