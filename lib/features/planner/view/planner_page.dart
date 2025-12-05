import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/planner_viewmodel.dart';
import '../model/meal_type.dart';
import '../model/day_plan.dart';
import '../model/meal_plan.dart';
import '../../recipes/viewmodel/recipe_viewmodel.dart';

/// Página principal del planificador semanal
class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  @override
  void initState() {
    super.initState();
    // Cargar plan de la semana actual al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlannerViewModel>().loadCurrentWeekPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificador Semanal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _savePlan(context),
            tooltip: 'Guardar plan',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              context.read<PlannerViewModel>().goToCurrentWeek();
            },
            tooltip: 'Ir a semana actual',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Limpiar todo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar plan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PlannerViewModel>(
        builder: (context, viewModel, child) {
          // Loading state
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${viewModel.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.clearError(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // No plan state
          final plan = viewModel.currentWeekPlan;
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64),
                  const SizedBox(height: 16),
                  const Text('No hay plan para esta semana'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadCurrentWeekPlan(),
                    child: const Text('Crear plan'),
                  ),
                ],
              ),
            );
          }

          // Plan loaded - Vista tipo calendario
          return Column(
            children: [
              // Week navigation header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      plan.dateRangeFormatted,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.planStats,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Header con días de la semana
              Container(
                height: 40,
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Row(children: _buildWeekDayHeaders()),
              ),

              // Grid del calendario semanal
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: plan.days.length,
                  itemBuilder: (context, index) {
                    final day = plan.days[index];
                    return _DayCell(day: day);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildWeekDayHeaders() {
    const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const weekDayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return List.generate(7, (index) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekDays[index],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(weekDayNames[index], style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
    });
  }

  void _handleMenuAction(String action) {
    final viewModel = context.read<PlannerViewModel>();

    switch (action) {
      case 'clear':
        _showClearDialog(viewModel);
        break;
      case 'delete':
        _showDeleteDialog(viewModel);
        break;
    }
  }

  Future<void> _savePlan(BuildContext context) async {
    final viewModel = context.read<PlannerViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar plan'),
        content: const Text(
          '¿Deseas guardar el plan semanal con todas las recetas asignadas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.savePlan();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Plan guardado correctamente'
                  : 'Error al guardar: ${viewModel.errorMessage}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDialog(PlannerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar plan'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las comidas asignadas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.clearAllMeals();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Plan limpiado'
                          : 'Error al limpiar: ${viewModel.errorMessage}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(PlannerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar el plan completo de esta semana?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.deleteCurrentPlan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Plan eliminado'
                          : 'Error al eliminar: ${viewModel.errorMessage}',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Celda individual para cada día del calendario
class _DayCell extends StatelessWidget {
  final DayPlan day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day.date);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _showDayDetails(context, day);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? theme.colorScheme.primary : Colors.grey.shade300,
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Encabezado con número del día
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),

            // Indicador "Hoy"
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'HOY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            // Comidas del día
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: day.meals.length,
                  itemBuilder: (context, index) {
                    final meal = day.meals[index];
                    return _MealIndicator(meal: meal);
                  },
                ),
              ),
            ),

            // Contador de comidas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.assignedMealsCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('/', style: TextStyle(fontSize: 10)),
                  Text(
                    '${MealType.values.length}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  void _showDayDetails(BuildContext context, DayPlan day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayDetailsSheet(day: day),
    );
  }
}

/// Indicador de comida dentro de la celda
class _MealIndicator extends StatelessWidget {
  final MealPlan meal;

  const _MealIndicator({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            _getMealIcon(meal.mealType),
            size: 12,
            color: meal.hasRecipe
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              meal.hasRecipe
                  ? (meal.recipeName!.length > 8
                        ? '${meal.recipeName!.substring(0, 8)}...'
                        : meal.recipeName!)
                  : '—',
              style: TextStyle(
                fontSize: 10,
                color: meal.hasRecipe ? Colors.black : Colors.grey.shade500,
                fontWeight: meal.hasRecipe
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
    }
  }
}

/// Sheet para mostrar detalles del día
class _DayDetailsSheet extends StatefulWidget {
  final DayPlan day;

  const _DayDetailsSheet({required this.day});

  @override
  State<_DayDetailsSheet> createState() => __DayDetailsSheetState();
}

class __DayDetailsSheetState extends State<_DayDetailsSheet> {
  late DayPlan _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.day;
  }

  @override
  void didUpdateWidget(_DayDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.day != oldWidget.day) {
      setState(() {
        _currentDay = widget.day;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(_currentDay.date);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header del sheet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDay.dayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_currentDay.date.day} de ${_getMonthName(_currentDay.date.month)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'HOY',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de comidas
          Expanded(
            child: Consumer<PlannerViewModel>(
              builder: (context, viewModel, child) {
                // Actualizar el día con la información más reciente
                final updatedPlan = viewModel.currentWeekPlan;
                if (updatedPlan != null) {
                  final updatedDay = updatedPlan.days.firstWhere(
                    (d) => d.date == _currentDay.date,
                    orElse: () => _currentDay,
                  );
                  if (updatedDay != _currentDay) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _currentDay = updatedDay;
                      });
                    });
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentDay.meals.length,
                  itemBuilder: (context, index) {
                    final meal = _currentDay.meals[index];
                    return _MealDetailCard(meal: meal, day: _currentDay);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  String _getMonthName(int month) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}

/// Tarjeta de detalle de comida en el sheet
class _MealDetailCard extends StatelessWidget {
  final MealPlan meal;
  final DayPlan day;

  const _MealDetailCard({required this.meal, required this.day});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PlannerViewModel>();
    final recipeViewModel = context.read<RecipeViewModel>();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _getMealIcon(meal.mealType),
          color: meal.hasRecipe
              ? Theme.of(context).primaryColor
              : Colors.grey.shade500,
        ),
        title: Text(meal.mealType.displayName),
        subtitle: Text(
          meal.hasRecipe ? meal.recipeName! : 'Sin receta asignada',
          style: TextStyle(
            color: meal.hasRecipe ? null : Colors.grey,
            fontStyle: meal.hasRecipe ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        trailing: meal.hasRecipe
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeRecipe(context, viewModel),
              )
            : IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                onPressed: () =>
                    _addRecipe(context, viewModel, recipeViewModel),
              ),
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
    }
  }

  Future<void> _addRecipe(
    BuildContext context,
    PlannerViewModel plannerViewModel,
    RecipeViewModel recipeViewModel,
  ) async {
    await recipeViewModel.loadRecipes();

    if (context.mounted) {
      final selectedRecipe = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar receta'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: recipeViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipeViewModel.recipes.isEmpty
                ? const Center(child: Text('No hay recetas disponibles'))
                : ListView.builder(
                    itemCount: recipeViewModel.recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipeViewModel.recipes[index];
                      return ListTile(
                        title: Text(recipe.name),
                        subtitle: recipe.steps.isNotEmpty
                            ? Text(
                                recipe.steps.length > 50
                                    ? '${recipe.steps.substring(0, 50)}...'
                                    : recipe.steps,
                                maxLines: 2,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context, {
                            'id': recipe.id,
                            'name': recipe.name,
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (selectedRecipe != null && meal.id != null) {
        final success = await plannerViewModel.assignRecipeToMeal(
          meal.id!,
          selectedRecipe['id'],
          selectedRecipe['name'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Receta asignada: ${selectedRecipe['name']}'
                    : 'Error: ${plannerViewModel.errorMessage}',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );

          // Forzar rebuild del Consumer
          plannerViewModel.notifyListeners();
        }
      }
    }
  }

  Future<void> _removeRecipe(
    BuildContext context,
    PlannerViewModel viewModel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover receta'),
        content: Text(
          '¿Remover "${meal.recipeName}" de ${meal.mealType.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.removeRecipeFromMeal(meal.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Receta removida' : 'Error: ${viewModel.errorMessage}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        // Forzar rebuild del Consumer
        viewModel.notifyListeners();
      }
    }
  }
}
