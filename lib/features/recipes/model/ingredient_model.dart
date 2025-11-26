class IngredientModel {
  String name;
  String quantity;
  String category;

  IngredientModel({
    required this.name,
    required this.quantity,
    required this.category,
  });

  Map<String, dynamic> toJson(String recipeId) => {
        'recipe_id': recipeId,
        'name': name,
        'quantity': quantity,
        'category': category,
      };
}
