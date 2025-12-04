import '../../../core/supabase_client.dart';

class CategoryService {
  final _client = Supa.client;

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _client.from('categories').select().order('name');
  }

  Future<void> insertCategory(String name) async {
    await _client.from('categories').insert({'name': name});
  }

  Future<void> updateCategory(String id, String name) async {
    await _client
        .from('categories')
        .update({'name': name})
        .eq('id', id);
  }
   Future<bool> isCategoryUsed(String categoryId) async {
    final data = await _client
        .from('recipe_ingredients')
        .select('id')
        .eq('category_id', categoryId);

    return data.isNotEmpty;
  }
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
  
}
