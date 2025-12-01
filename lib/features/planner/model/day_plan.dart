import 'meal_plan.dart';
import 'meal_type.dart';

/// Modelo que representa el plan de comidas para un día específico
class DayPlan {
  final String? id;
  final String weeklyPlanId;
  final DateTime date;
  final int dayOfWeek; // 1 = Lunes, 7 = Domingo
  final List<MealPlan> meals;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayPlan({
    this.id,
    required this.weeklyPlanId,
    required this.date,
    required this.dayOfWeek,
    List<MealPlan>? meals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : meals = meals ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Obtiene el nombre del día de la semana
  String get dayName {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[dayOfWeek - 1];
  }

  /// Obtiene una comida específica por tipo
  MealPlan? getMealByType(MealType mealType) {
    try {
      return meals.firstWhere((meal) => meal.mealType == mealType);
    } catch (e) {
      return null;
    }
  }

  /// Cuenta cuántas comidas tienen receta asignada
  int get assignedMealsCount {
    return meals.where((meal) => meal.hasRecipe).length;
  }

  /// Indica si el día tiene todas las comidas planificadas
  bool get isFullyPlanned {
    return assignedMealsCount == MealType.values.length;
  }

  /// Crea una instancia desde JSON (respuesta de Supabase)
  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      id: json['id'] as String?,
      weeklyPlanId: json['weekly_plan_id'] as String,
      date: DateTime.parse(json['date'] as String),
      dayOfWeek: json['day_of_week'] as int,
      meals: json['meals'] != null
          ? (json['meals'] as List)
                .map((meal) => MealPlan.fromJson(meal as Map<String, dynamic>))
                .toList()
          : [],
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
      'weekly_plan_id': weeklyPlanId,
      'date': date.toIso8601String().split('T')[0], // Solo la fecha
      'day_of_week': dayOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia del DayPlan con algunos campos actualizados
  DayPlan copyWith({
    String? id,
    String? weeklyPlanId,
    DateTime? date,
    int? dayOfWeek,
    List<MealPlan>? meals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayPlan(
      id: id ?? this.id,
      weeklyPlanId: weeklyPlanId ?? this.weeklyPlanId,
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      meals: meals ?? this.meals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DayPlan(id: $id, dayName: $dayName, date: ${date.toIso8601String().split('T')[0]}, meals: ${meals.length})';
  }
}
