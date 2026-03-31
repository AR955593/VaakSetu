import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://fevsmjakpqwnvjelgdsa.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZldnNtamFrcHF3bnZqZWxnZHNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NTQwMDQsImV4cCI6MjA5MDMzMDAwNH0.7abTyYP_bXQVaicYlCW51v5cb_H6PeZLjc81BO-14xg';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
