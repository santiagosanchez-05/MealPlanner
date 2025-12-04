import '../../../core/supabase_client.dart';
import 'dart:typed_data';
import '../model/ingredient_model.dart';

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
  List<IngredientModel> ingredients,
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

  for (final ing in ingredients) {
    await _client.from('recipe_ingredients').insert(
      ing.toJson(recipeId), // ✅ AHORA SÍ GUARDA BIEN
    );
  }
}


  Future<void> deleteRecipe(String recipeId) async {
    await _client.from('recipes').delete().eq('id', recipeId);
  }
  Future<List<Map<String, dynamic>>> getCategories() async {
  return await _client
      .from('categories')
      .select()
      .order('name');
}

  Future<void> updateRecipe(
  String id,
  String name,
  String steps,
  Uint8List? photo,
  List ingredients,
) async {
  // 1️⃣ Actualizar receta
  await _client.from('recipes').update({
    'name': name,
    'steps': steps,
    'photo': photo,
  }).eq('id', id);

  // 2️⃣ Borrar ingredientes viejos
  await _client.from('recipe_ingredients')
      .delete()
      .eq('recipe_id', id);

  // 3️⃣ Insertar ingredientes nuevos
  for (var ing in ingredients) {
    await _client.from('recipe_ingredients').insert({
      'recipe_id': id,
      'name': ing.name,
      'quantity': ing.quantity,
      'category_id': ing.categoryId,
    });
  }
}


}
