class IngredientModel {
  String name;
  String quantity;
  String categoryId;

  IngredientModel({
    required this.name,
    required this.quantity,
    required this.categoryId,
  });

  Map<String, dynamic> toJson(String recipeId) => {
        'recipe_id': recipeId,
        'name': name,
        'quantity': quantity,
        'category_id': categoryId,
      };

  IngredientModel copy() {
  return IngredientModel(
    name: name,
    quantity: quantity,
    categoryId: categoryId,
  );
}

}
