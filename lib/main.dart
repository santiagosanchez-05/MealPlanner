import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aadfhgvknrlaizwzfcnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZGZoZ3ZrbnJsYWl6d3pmY25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzIwNTIsImV4cCI6MjA3OTc0ODA1Mn0.1k7vpKAmZWdD3HrDm2BQLIq8R0O7Nx8qD93po0fvZ-I',
  );
print("SUPABASE CONECTADO ✓");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
