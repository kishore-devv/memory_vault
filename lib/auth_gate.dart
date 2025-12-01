import 'package:flutter/material.dart';
import 'package:memory_vault/screens/home_page.dart';
import 'package:memory_vault/screens/login_page.dart';
import 'package:memory_vault/screens/notes_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
  return const HomePage();
}

    return const LoginPage();
  }
}
