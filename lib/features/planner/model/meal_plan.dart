import 'meal_type.dart';

/// Modelo que representa una comida específica en el plan
class MealPlan {
  final String? id;
  final String dayPlanId;
  final MealType mealType;
  final String? recipeId;
  final String? recipeName;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    this.id,
    required this.dayPlanId,
    required this.mealType,
    this.recipeId,
    this.recipeName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Indica si la comida tiene una receta asignada
  bool get hasRecipe => recipeId != null && recipeId!.isNotEmpty;

  /// Crea una instancia desde JSON (respuesta de Supabase)
  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String?,
      dayPlanId: json['day_plan_id'] as String,
      mealType: MealType.fromString(json['meal_type'] as String),
      recipeId: json['recipe_id'] as String?,
      recipeName: json['recipe_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convierte la instancia a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'day_plan_id': dayPlanId,
      'meal_type': mealType.toDBString(),
      'recipe_id': recipeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia del MealPlan con algunos campos actualizados
  MealPlan copyWith({
    String? id,
    String? dayPlanId,
    MealType? mealType,
    String? recipeId,
    String? recipeName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      dayPlanId: dayPlanId ?? this.dayPlanId,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, mealType: ${mealType.displayName}, recipeName: $recipeName)';
  }
}
