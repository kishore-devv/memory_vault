import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:memory_vault/auth_gate.dart';
import 'package:memory_vault/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pnxuvrqqgsblelcqnjtr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBueHV2cnFxZ3NibGVsY3FuanRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5OTQwNTcsImV4cCI6MjA3OTU3MDA1N30.jh4c00lzZfedorOG-AMRdrneef8vi9Qjfe5E3abBpmQ',
  );
  // await Firebase.initializeApp();
  // await NotificationService().init(); // init FCM + local notifications
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}


