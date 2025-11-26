import '../../core/supabase_client.dart';

class UsuariosService {
  final supabase = Supa.client;

  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final response = await supabase.from('profiles').select('*');
    return response;
  }

  Future<void> addUsuario(String id, String email) async {
    await supabase.from('profiles').insert({
      'id': id,
      'email': email,
    });
  }
}
