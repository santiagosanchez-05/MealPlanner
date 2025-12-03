import 'package:flutter/foundation.dart';
import '../model/weekly_plan.dart';
import '../model/day_plan.dart';
import '../model/meal_plan.dart';
import '../model/meal_type.dart';
import '../service/planner_service.dart';

/// ViewModel para gestionar el estado del planificador semanal
class PlannerViewModel extends ChangeNotifier {
  final PlannerService _service = PlannerService();

  // ==================== ESTADO ====================

  WeeklyPlan? _currentWeekPlan;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // ==================== GETTERS ====================

  WeeklyPlan? get currentWeekPlan => _currentWeekPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  /// Indica si hay un plan cargado
  bool get hasPlan => _currentWeekPlan != null;

  /// Obtiene los días del plan actual
  List<DayPlan> get days => _currentWeekPlan?.days ?? [];

  /// Obtiene estadísticas del plan actual
  String get planStats {
    if (_currentWeekPlan == null) return 'Sin plan';
    return '${_currentWeekPlan!.totalAssignedMeals} comidas planificadas';
  }

  // ==================== INICIALIZACIÓN ====================

  /// Carga el plan de la semana actual
  Future<void> loadCurrentWeekPlan() async {
    await _executeWithLoading(() async {
      _currentWeekPlan = await _service.getOrCreateCurrentWeekPlan();
      _errorMessage = null;
    });
  }

  /// Carga o crea el plan para una fecha específica
  Future<void> loadWeekPlanForDate(DateTime date) async {
    _selectedDate = date;
    await _executeWithLoading(() async {
      final existingPlan = await _service.getCurrentWeekPlan();
      if (existingPlan != null) {
        _currentWeekPlan = existingPlan;
      } else {
        _currentWeekPlan = await _service.createWeekPlan(date);
      }
      _errorMessage = null;
    });
  }

  // ==================== GESTIÓN DE COMIDAS ====================

  /// Asigna una receta a una comida específica
  Future<bool> assignRecipeToMeal(
    String mealPlanId,
    String recipeId,
    String recipeName,
  ) async {
    return await _executeWithLoading(() async {
      await _service.assignRecipeToMeal(mealPlanId, recipeId, recipeName);

      // Recargar el plan actualizado
      if (_currentWeekPlan?.id != null) {
        _currentWeekPlan = await _service.getWeekPlanById(
          _currentWeekPlan!.id!,
        );
      }

      _errorMessage = null;
    });
  }

  /// Remueve una receta de una comida
  Future<bool> removeRecipeFromMeal(String mealPlanId) async {
    return await _executeWithLoading(() async {
      await _service.removeRecipeFromMeal(mealPlanId);

      // Recargar el plan actualizado
      if (_currentWeekPlan?.id != null) {
        _currentWeekPlan = await _service.getWeekPlanById(
          _currentWeekPlan!.id!,
        );
      }

      _errorMessage = null;
    });
  }

  /// Obtiene una comida específica por día y tipo
  MealPlan? getMeal(int dayOfWeek, MealType mealType) {
    final day = _currentWeekPlan?.getDayByWeekday(dayOfWeek);
    return day?.getMealByType(mealType);
  }

  /// Obtiene todas las comidas de un día específico
  List<MealPlan> getMealsForDay(int dayOfWeek) {
    final day = _currentWeekPlan?.getDayByWeekday(dayOfWeek);
    return day?.meals ?? [];
  }

  // ==================== NAVEGACIÓN DE SEMANAS ====================

  /// Navega a la semana anterior
  Future<void> previousWeek() async {
    final newDate = _selectedDate.subtract(const Duration(days: 7));
    await loadWeekPlanForDate(newDate);
  }

  /// Navega a la semana siguiente
  Future<void> nextWeek() async {
    final newDate = _selectedDate.add(const Duration(days: 7));
    await loadWeekPlanForDate(newDate);
  }

  /// Navega a la semana actual
  Future<void> goToCurrentWeek() async {
    await loadWeekPlanForDate(DateTime.now());
  }

  // ==================== OPERACIONES AVANZADAS ====================

  /// Guarda el plan semanal completo con todas las recetas asignadas
  Future<bool> savePlan() async {
    if (_currentWeekPlan == null) {
      _errorMessage = 'No hay plan para guardar';
      notifyListeners();
      return false;
    }

    return await _executeWithLoading(() async {
      // El plan ya está siendo guardado automáticamente con cada asignación de receta
      // Este método confirma que todo está guardado
      await _service.saveWeekPlan(_currentWeekPlan!);
      _errorMessage = null;
    });
  }

  /// Duplica el plan actual a otra semana
  Future<bool> duplicatePlanToWeek(DateTime targetWeekStart) async {
    if (_currentWeekPlan?.id == null) {
      _errorMessage = 'No hay plan para duplicar';
      notifyListeners();
      return false;
    }

    return await _executeWithLoading(() async {
      await _service.duplicateWeekPlan(_currentWeekPlan!.id!, targetWeekStart);
      _errorMessage = null;
    });
  }

  /// Limpia todas las comidas del plan actual
  Future<bool> clearAllMeals() async {
    if (_currentWeekPlan == null) return false;

    return await _executeWithLoading(() async {
      for (final day in _currentWeekPlan!.days) {
        for (final meal in day.meals) {
          if (meal.hasRecipe && meal.id != null) {
            await _service.removeRecipeFromMeal(meal.id!);
          }
        }
      }

      // Recargar el plan
      if (_currentWeekPlan?.id != null) {
        _currentWeekPlan = await _service.getWeekPlanById(
          _currentWeekPlan!.id!,
        );
      }

      _errorMessage = null;
    });
  }

  /// Elimina el plan semanal actual
  Future<bool> deleteCurrentPlan() async {
    if (_currentWeekPlan?.id == null) return false;

    return await _executeWithLoading(() async {
      await _service.deleteWeekPlan(_currentWeekPlan!.id!);
      _currentWeekPlan = null;
      _errorMessage = null;
    });
  }

  // ==================== UTILIDADES ====================

  /// Obtiene el día de la semana actual
  DayPlan? get todayPlan {
    final today = DateTime.now();
    return _currentWeekPlan?.getDayByDate(today);
  }

  /// Verifica si una fecha está en la semana actual del plan
  bool isDateInCurrentWeek(DateTime date) {
    if (_currentWeekPlan == null) return false;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final weekStart = DateTime(
      _currentWeekPlan!.weekStartDate.year,
      _currentWeekPlan!.weekStartDate.month,
      _currentWeekPlan!.weekStartDate.day,
    );
    final weekEnd = DateTime(
      _currentWeekPlan!.weekEndDate.year,
      _currentWeekPlan!.weekEndDate.month,
      _currentWeekPlan!.weekEndDate.day,
    );

    return normalizedDate.isAfter(
          weekStart.subtract(const Duration(days: 1)),
        ) &&
        normalizedDate.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Ejecuta una operación con indicador de carga
  Future<bool> _executeWithLoading(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}
