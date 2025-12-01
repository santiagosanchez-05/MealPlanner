import '../../../core/supabase_client.dart';
import '../model/weekly_plan.dart';
import '../model/day_plan.dart';
import '../model/meal_plan.dart';
import '../model/meal_type.dart';

/// Servicio para gestionar los planes de comidas semanales
class PlannerService {
  final _client = Supa.client;

  // ==================== WEEKLY PLANS ====================

  /// Obtiene el plan semanal actual del usuario autenticado
  Future<WeeklyPlan?> getCurrentWeekPlan() async {
    final userId = _client.auth.currentUser!.id;
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    try {
      final response = await _client
          .from('weekly_plans')
          .select('*, days:day_plans(*, meals:meal_plans(*, recipes(name)))')
          .eq('user_id', userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _parseWeeklyPlanFromResponse(response);
    } catch (e) {
      throw Exception('Error al obtener el plan semanal: $e');
    }
  }

  /// Obtiene o crea el plan semanal para la semana actual
  Future<WeeklyPlan> getOrCreateCurrentWeekPlan() async {
    final existing = await getCurrentWeekPlan();
    if (existing != null) {
      return existing;
    }

    // Crear nuevo plan semanal
    return await createWeekPlan(DateTime.now());
  }

  /// Crea un nuevo plan semanal para una fecha específica
  Future<WeeklyPlan> createWeekPlan(DateTime date) async {
    final userId = _client.auth.currentUser!.id;
    final weekPlan = WeeklyPlan.forDate(date, userId);

    try {
      // Insertar el plan semanal
      final weekResponse = await _client
          .from('weekly_plans')
          .insert(weekPlan.toJson())
          .select()
          .single();

      final weeklyPlanId = weekResponse['id'] as String;

      // Crear los 7 días de la semana
      final dayPlans = <DayPlan>[];
      for (int i = 0; i < 7; i++) {
        final dayDate = weekPlan.weekStartDate.add(Duration(days: i));
        final dayPlan = DayPlan(
          weeklyPlanId: weeklyPlanId,
          date: dayDate,
          dayOfWeek: i + 1,
        );

        // Insertar el día
        final dayResponse = await _client
            .from('day_plans')
            .insert(dayPlan.toJson())
            .select()
            .single();

        final dayPlanId = dayResponse['id'] as String;

        // Crear las 3 comidas para cada día
        final mealPlans = <MealPlan>[];
        for (final mealType in MealType.values) {
          final mealPlan = MealPlan(dayPlanId: dayPlanId, mealType: mealType);

          final mealResponse = await _client
              .from('meal_plans')
              .insert(mealPlan.toJson())
              .select()
              .single();

          mealPlans.add(MealPlan.fromJson(mealResponse));
        }

        dayPlans.add(dayPlan.copyWith(id: dayPlanId, meals: mealPlans));
      }

      return weekPlan.copyWith(id: weeklyPlanId, days: dayPlans);
    } catch (e) {
      throw Exception('Error al crear el plan semanal: $e');
    }
  }

  /// Obtiene el plan semanal por ID
  Future<WeeklyPlan?> getWeekPlanById(String weekPlanId) async {
    try {
      final response = await _client
          .from('weekly_plans')
          .select('*, days:day_plans(*, meals:meal_plans(*, recipes(name)))')
          .eq('id', weekPlanId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _parseWeeklyPlanFromResponse(response);
    } catch (e) {
      throw Exception('Error al obtener el plan semanal: $e');
    }
  }

  /// Elimina un plan semanal completo (cascada)
  Future<void> deleteWeekPlan(String weekPlanId) async {
    try {
      await _client.from('weekly_plans').delete().eq('id', weekPlanId);
    } catch (e) {
      throw Exception('Error al eliminar el plan semanal: $e');
    }
  }

  // ==================== MEAL PLANS ====================

  /// Asigna una receta a una comida específica
  Future<MealPlan> assignRecipeToMeal(
    String mealPlanId,
    String recipeId,
  ) async {
    try {
      final response = await _client
          .from('meal_plans')
          .update({
            'recipe_id': recipeId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mealPlanId)
          .select('*, recipes(name)')
          .single();

      return _parseMealPlanFromResponse(response);
    } catch (e) {
      throw Exception('Error al asignar receta: $e');
    }
  }

  /// Remueve la receta asignada a una comida
  Future<MealPlan> removeRecipeFromMeal(String mealPlanId) async {
    try {
      final response = await _client
          .from('meal_plans')
          .update({
            'recipe_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mealPlanId)
          .select()
          .single();

      return MealPlan.fromJson(response);
    } catch (e) {
      throw Exception('Error al remover receta: $e');
    }
  }

  /// Obtiene todas las comidas de un día específico
  Future<List<MealPlan>> getMealsForDay(String dayPlanId) async {
    try {
      final response = await _client
          .from('meal_plans')
          .select('*, recipes(name)')
          .eq('day_plan_id', dayPlanId)
          .order('meal_type');

      return response
          .map<MealPlan>((json) => _parseMealPlanFromResponse(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener comidas del día: $e');
    }
  }

  // ==================== HELPERS ====================

  /// Obtiene el lunes de la semana para una fecha dada
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    final monday = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Parsea una respuesta de weekly_plan con relaciones anidadas
  WeeklyPlan _parseWeeklyPlanFromResponse(Map<String, dynamic> response) {
    final days = response['days'] as List?;
    final dayPlans = days != null
        ? days.map<DayPlan>((dayJson) {
            final meals = dayJson['meals'] as List?;
            final mealPlans = meals != null
                ? meals
                      .map<MealPlan>(
                        (mealJson) => _parseMealPlanFromResponse(mealJson),
                      )
                      .toList()
                : <MealPlan>[];

            return DayPlan.fromJson(dayJson).copyWith(meals: mealPlans);
          }).toList()
        : <DayPlan>[];

    return WeeklyPlan.fromJson(response).copyWith(days: dayPlans);
  }

  /// Parsea una respuesta de meal_plan con la receta anidada
  MealPlan _parseMealPlanFromResponse(Map<String, dynamic> response) {
    String? recipeName;
    if (response['recipes'] != null) {
      final recipe = response['recipes'] as Map<String, dynamic>;
      recipeName = recipe['name'] as String?;
    }

    return MealPlan.fromJson(response).copyWith(recipeName: recipeName);
  }

  // ==================== UTILIDADES ====================

  /// Obtiene todas las semanas planificadas del usuario
  Future<List<WeeklyPlan>> getAllWeekPlans() async {
    final userId = _client.auth.currentUser!.id;

    try {
      final response = await _client
          .from('weekly_plans')
          .select()
          .eq('user_id', userId)
          .order('week_start_date', ascending: false);

      return response
          .map<WeeklyPlan>((json) => WeeklyPlan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener planes semanales: $e');
    }
  }

  /// Duplica un plan semanal a otra semana
  Future<WeeklyPlan> duplicateWeekPlan(
    String sourceWeekPlanId,
    DateTime targetWeekStart,
  ) async {
    try {
      // Obtener el plan original con todas las comidas
      final sourcePlan = await getWeekPlanById(sourceWeekPlanId);
      if (sourcePlan == null) {
        throw Exception('Plan semanal origen no encontrado');
      }

      // Crear nuevo plan para la semana objetivo
      final newWeekPlan = await createWeekPlan(targetWeekStart);

      // Copiar las asignaciones de recetas
      for (int i = 0; i < sourcePlan.days.length; i++) {
        final sourceDay = sourcePlan.days[i];
        final targetDay = newWeekPlan.days[i];

        for (final sourceMeal in sourceDay.meals) {
          if (sourceMeal.recipeId != null) {
            // Encontrar la comida correspondiente en el nuevo plan
            final targetMeal = targetDay.meals.firstWhere(
              (meal) => meal.mealType == sourceMeal.mealType,
            );

            await assignRecipeToMeal(targetMeal.id!, sourceMeal.recipeId!);
          }
        }
      }

      return await getWeekPlanById(newWeekPlan.id!) ?? newWeekPlan;
    } catch (e) {
      throw Exception('Error al duplicar plan semanal: $e');
    }
  }
}
