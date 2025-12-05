import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ IMPORTANTE
import '../../core/supabase_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final passConfirmCtrl = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    final supabase = Supa.client;
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final confirm = passConfirmCtrl.text.trim();

    // ✅ VALIDACIONES LOCALES
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showMessage("Complete todos los campos");
      return;
    }

    if (!email.contains("@")) {
      showMessage("Ingrese un correo válido");
      return;
    }

    if (pass.length < 6) {
      showMessage("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (pass != confirm) {
      showMessage("Las contraseñas no coinciden");
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.auth.signUp(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      showMessage("Cuenta creada ✅. Revisa tu correo para confirmar.");
      Navigator.pop(context);
    } 
    on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains("password")) {
        showMessage("La contraseña es demasiado débil");
      } 
      else if (msg.contains("already") || msg.contains("registered")) {
        showMessage("Este correo ya está registrado");
      } 
      else if (msg.contains("email")) {
        showMessage("Correo inválido");
      } 
      else {
        showMessage("Error al crear la cuenta. Intente nuevamente.");
      }
    } 
    catch (_) {
      showMessage("No se pudo conectar al servidor");
    } 
    finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Crear cuenta"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: passConfirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirmar contraseña",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Crear cuenta",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
