import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../model/recipe_model.dart';
import '../model/ingredient_model.dart';
import '../../categories/model/category_model.dart';
import '../service/recipe_service.dart';

class RecipeViewModel extends ChangeNotifier {
  final RecipeService _service = RecipeService();

  List<RecipeModel> recipes = [];
  List<IngredientModel> ingredients = [];
  List<CategoryModel> categories = [];

  bool isLoading = false;
  bool ingredientsLoading = false;


  // ==========================
  // CARGAR RECETAS
  // ==========================
  Future<void> loadRecipes() async {
    isLoading = true;
    notifyListeners();

    final data = await _service.getRecipes();
    recipes = data.map((e) => RecipeModel.fromJson(e)).toList();

    isLoading = false;
    notifyListeners();
  }

  // ==========================
  // CARGAR INGREDIENTES
  // ==========================
  Future<void> loadIngredients(String recipeId) async {
  ingredientsLoading = true;
  notifyListeners();

  final data = await _service.getIngredients(recipeId);

  ingredients = data.map<IngredientModel>((e) {
    return IngredientModel(
      name: e['name'],
      quantity: e['quantity'],
      categoryId: e['category_id'],
    );
  }).toList();

  ingredientsLoading = false;
  notifyListeners();
}


  // ==========================
  // CARGAR CATEGORÍAS
  // ==========================
  Future<void> loadCategories() async {
    final data = await _service.getCategories();
    categories = data.map((e) => CategoryModel.fromJson(e)).toList();
    notifyListeners();
  }

  // ==========================
  // CREAR RECETA
  // ==========================
  Future<void> addRecipe(
    String name,
    String steps,
    Uint8List? photo,
    List<IngredientModel> ingredients,
  ) async {
    await _service.insertRecipe(name, steps, photo, ingredients);
    await loadRecipes();
  }

  // ==========================
  // ACTUALIZAR RECETA
  // ==========================
  Future<void> updateRecipe(
    String id,
    String name,
    String steps,
    Uint8List? photo,
    List<IngredientModel> ingredients,
  ) async {
    await _service.updateRecipe(id, name, steps, photo, ingredients);
    await loadRecipes();
  }

  // ==========================
  // ELIMINAR RECETA
  // ==========================
  Future<void> delete(String id) async {
    await _service.deleteRecipe(id);
    await loadRecipes();
  }
}
