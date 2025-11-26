import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // Auth helpers
  Future<User?> signIn(String email, String password) =>
    supabase.auth.signInWithPassword(email: email, password: password)
      .then((res) => res.user);

  Future<void> signOut() => supabase.auth.signOut();

  // Notes CRUD
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final user = supabase.auth.currentUser;
    final res = await supabase.from('notes')
      .select()
      .eq('user_id', user!.id)
      .order('created_at', ascending: false);
    return List<Map<String,dynamic>>.from(res);
  }

  Future<void> createNote(String content, {String? title, DateTime? reminderAt}) async {
    final user = supabase.auth.currentUser;
    await supabase.from('notes').insert({
      'user_id': user!.id,
      'title': title,
      'content': content,
      'reminder_at': reminderAt?.toUtc().toIso8601String(),
    });
  }

  // update & delete similar...
}
