import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://whxtitamvrqpzeqyrqea.supabase.co',          
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoeHRpdGFtdnJxcHplcXlycWVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczNTQ5NTUsImV4cCI6MjA2MjkzMDk1NX0.CcuK40m8btHFMNZintJ0KRk-pM2GMqSaOpAnqD7arjM', 
  );

  // Iniciando o app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Seguro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
