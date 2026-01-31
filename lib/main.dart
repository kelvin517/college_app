import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ifivpdjbsfbdoebyglyo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlmaXZwZGpic2ZiZG9lYnlnbHlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4Njk0OTgsImV4cCI6MjA4NTQ0NTQ5OH0.-Ad7O_6oSJKVR3jOptIntdKV5hwMSVJ5T5ldENlHKvs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Admission App',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
