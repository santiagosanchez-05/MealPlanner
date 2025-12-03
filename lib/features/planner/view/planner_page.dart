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
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy),
                    SizedBox(width: 8),
                    Text('Duplicar plan'),
                  ],
                ),
              ),
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

          // Plan loaded
          return Column(
            children: [
              // Week navigation header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => viewModel.previousWeek(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            plan.dateRangeFormatted,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            viewModel.planStats,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => viewModel.nextWeek(),
                    ),
                  ],
                ),
              ),

              // Days list
              Expanded(
                child: ListView.builder(
                  itemCount: plan.days.length,
                  itemBuilder: (context, index) {
                    final day = plan.days[index];
                    return _DayCard(day: day);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    final viewModel = context.read<PlannerViewModel>();

    switch (action) {
      case 'duplicate':
        _showDuplicateDialog(viewModel);
        break;
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

  void _showDuplicateDialog(PlannerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar plan'),
        content: const Text(
          'Esta funcionalidad permitirá duplicar el plan actual a otra semana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
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

/// Widget para mostrar un día con sus comidas
class _DayCard extends StatelessWidget {
  final DayPlan day;

  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isToday
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isToday
              ? Theme.of(context).primaryColor
              : Colors.grey,
          child: Text(
            day.date.day.toString(),
            style: TextStyle(
              color: isToday ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              day.dayName,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isToday)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HOY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${day.assignedMealsCount} de ${MealType.values.length} comidas planificadas',
        ),
        children: day.meals.map((meal) => _MealTile(meal: meal)).toList(),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}

/// Widget para mostrar una comida individual
class _MealTile extends StatelessWidget {
  final MealPlan meal;

  const _MealTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getMealIcon(meal.mealType),
        color: meal.hasRecipe ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(meal.mealType.displayName),
      subtitle: Text(
        meal.hasRecipe
            ? meal.recipeName ?? 'Receta sin nombre'
            : 'Sin planificar',
        style: TextStyle(
          color: meal.hasRecipe ? null : Colors.grey,
          fontStyle: meal.hasRecipe ? FontStyle.normal : FontStyle.italic,
        ),
      ),
      trailing: meal.hasRecipe
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeRecipe(context),
            )
          : IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addRecipe(context),
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

  void _addRecipe(BuildContext context) async {
    final recipeViewModel = context.read<RecipeViewModel>();
    final plannerViewModel = context.read<PlannerViewModel>();

    // Cargar recetas del usuario
    await recipeViewModel.loadRecipes();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar receta'),
          content: SizedBox(
            width: double.maxFinite,
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
                            onTap: () async {
                              Navigator.pop(context);
                              
                              // Asignar receta a la comida
                              if (meal.id != null) {
                                final success =
                                    await plannerViewModel.assignRecipeToMeal(
                                  meal.id!,
                                  recipe.id,
                                  recipe.name,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Receta asignada: ${recipe.name}'
                                            : 'Error: ${plannerViewModel.errorMessage}',
                                      ),
                                    ),
                                  );
                                }
                              }
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
    }
  }

  void _removeRecipe(BuildContext context) async {
    final viewModel = context.read<PlannerViewModel>();

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

    if (confirm == true && context.mounted) {
      final success = await viewModel.removeRecipeFromMeal(meal.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Receta removida' : 'Error: ${viewModel.errorMessage}',
            ),
          ),
        );
      }
    }
  }
}
