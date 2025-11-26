import 'dart:typed_data';
import 'ingredient_model.dart';

class RecipeModel {
  String id;
  String name;
  String steps;
  Uint8List? photo;
  List<IngredientModel> ingredients;

  RecipeModel({
    required this.id,
    required this.name,
    required this.steps,
    this.photo,
    required this.ingredients,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      name: json['name'],
      steps: json['steps'],
      photo: json['photo'],
      ingredients: [],
    );
  }
}
