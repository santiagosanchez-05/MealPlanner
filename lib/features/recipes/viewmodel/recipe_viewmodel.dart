import 'package:flutter/material.dart';
import '../service/recipe_service.dart';
import '../model/recipe_model.dart';
import '../model/ingredient_model.dart';
import 'dart:typed_data';

class RecipeViewModel extends ChangeNotifier {
  final RecipeService _service = RecipeService();

  // ✅ LISTAS
  List<RecipeModel> recipes = [];
  List<IngredientModel> ingredients = [];

  bool isLoading = false;

  // ===============================
  // CARGAR RECETAS
  // ===============================
  Future<void> loadRecipes() async {
    isLoading = true;
    notifyListeners();

    final data = await _service.getRecipes();
    recipes = data.map((e) => RecipeModel.fromJson(e)).toList();

    isLoading = false;
    notifyListeners();
  }

  // ===============================
  // CARGAR INGREDIENTES POR RECETA
  // ===============================
  Future<void> loadIngredients(String recipeId) async {
    ingredients = [];
    notifyListeners();

    final data = await _service.getIngredients(recipeId);

    ingredients = data
        .map((e) => IngredientModel(
              name: e['name'],
              quantity: e['quantity'],
              category: e['category'],
            ))
        .toList();

    notifyListeners();
  }

  // ===============================
  // CREAR RECETA
  // ===============================
  Future<void> addRecipe(
    String name,
    String steps,
    photo,
    List<IngredientModel> ingredientsList,
  ) async {
    await _service.insertRecipe(name, steps, photo, ingredientsList);
    await loadRecipes();
  }

  // ===============================
  // ELIMINAR RECETA
  // ===============================
  Future<void> delete(String id) async {
    await _service.deleteRecipe(id);
    await loadRecipes();
  }
  Future<void> updateRecipe(
  String id,
  String name,
  String steps,
  Uint8List? photo,
  List<IngredientModel> ingredients,
  ) async {
    await _service.updateRecipe(id, name, steps, photo, ingredients);
    await loadRecipes(); // ✅ ESTE SÍ EXISTE
    notifyListeners();
  }
  
}
