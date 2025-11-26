import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:memory_vault/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Supabase.initialize(
  //   url: 'https://YOUR-PROJECT.supabase.co',
  //   anonKey: 'public-anon-key',
  // );
  // await Firebase.initializeApp();
  // await NotificationService().init(); // init FCM + local notifications
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    
      home: LoginPage(),
    );
  }
}


