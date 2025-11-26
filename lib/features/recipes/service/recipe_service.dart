import '../../../core/supabase_client.dart';

class RecipeService {
  final _client = Supa.client;

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final userId = _client.auth.currentUser!.id;

    return await _client
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .order('created_at');
  }

  Future<List<Map<String, dynamic>>> getIngredients(String recipeId) async {
    return await _client
        .from('recipe_ingredients')
        .select()
        .eq('recipe_id', recipeId);
  }

  Future<void> insertRecipe(
    String name,
    String steps,
    photo,
    List ingredients,
  ) async {
    final userId = _client.auth.currentUser!.id;

    final recipe = await _client
        .from('recipes')
        .insert({
          'user_id': userId,
          'name': name,
          'steps': steps,
          'photo': photo,
        })
        .select()
        .single();

    final recipeId = recipe['id'];

    for (var ing in ingredients) {
      await _client.from('recipe_ingredients').insert({
        'recipe_id': recipeId,
        'name': ing.name,
        'quantity': ing.quantity,
        'category': ing.category,
      });
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _client.from('recipes').delete().eq('id', recipeId);
  }
}
