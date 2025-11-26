import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/login_page.dart';
import 'features/recipes/viewmodel/recipe_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ AQUÍ SE INICIALIZA SUPABASE (ESTO ERA LO QUE FALTABA)
  await Supabase.initialize(
    url: 'https://aadfhgvknrlaizwzfcnk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZGZoZ3ZrbnJsYWl6d3pmY25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzIwNTIsImV4cCI6MjA3OTc0ODA1Mn0.1k7vpKAmZWdD3HrDm2BQLIq8R0O7Nx8qD93po0fvZ-I',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RecipeViewModel()..loadRecipes(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
      ),
    );
  }
}
