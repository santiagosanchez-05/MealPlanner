# Planificador Semanal - Guía de Uso

## Estructura de la implementación

El planificador semanal ha sido implementado siguiendo una arquitectura MVVM (Model-View-ViewModel) con las siguientes capas:

### 📁 Estructura de archivos

```
lib/features/planner/
├── model/
│   ├── meal_type.dart        # Enum para tipos de comida
│   ├── meal_plan.dart         # Modelo de una comida específica
│   ├── day_plan.dart          # Modelo de un día completo
│   └── weekly_plan.dart       # Modelo de plan semanal
├── service/
│   └── planner_service.dart   # Lógica de comunicación con Supabase
├── viewmodel/
│   └── planner_viewmodel.dart # Gestión de estado con ChangeNotifier
├── view/
│   └── (pendiente implementar vistas)
├── planner.dart               # Archivo de exportación
└── DATABASE_SCHEMA.md         # Esquema de base de datos
```

## 🔧 Modelos de Datos

### 1. MealType (Enum)
Representa los tipos de comidas disponibles:
- `breakfast` (Desayuno)
- `lunch` (Almuerzo)
- `dinner` (Cena)

```dart
import 'package:mealplanner/features/planner/planner.dart';

// Uso básico
final mealType = MealType.breakfast;
print(mealType.displayName); // "Desayuno"

// Conversión desde string
final type = MealType.fromString('almuerzo'); // MealType.lunch
```

### 2. MealPlan
Representa una comida específica (ej: desayuno del lunes).

```dart
final meal = MealPlan(
  dayPlanId: 'day-id',
  mealType: MealType.breakfast,
  recipeId: 'recipe-id', // Opcional
);

// Verificar si tiene receta asignada
if (meal.hasRecipe) {
  print('Receta: ${meal.recipeName}');
}
```

### 3. DayPlan
Representa un día completo con sus 3 comidas.

```dart
final day = DayPlan(
  weeklyPlanId: 'week-id',
  date: DateTime(2025, 12, 1),
  dayOfWeek: 1, // 1 = Lunes
  meals: [breakfastMeal, lunchMeal, dinnerMeal],
);

print(day.dayName); // "Lunes"
print('Comidas asignadas: ${day.assignedMealsCount}');
print('¿Día completo?: ${day.isFullyPlanned}');

// Obtener una comida específica
final breakfast = day.getMealByType(MealType.breakfast);
```

### 4. WeeklyPlan
Representa el plan completo de una semana.

```dart
// Crear plan para una fecha
final plan = WeeklyPlan.forDate(DateTime.now(), userId);

print('Semana ${plan.weekNumber} del ${plan.year}');
print('Rango: ${plan.dateRangeFormatted}');
print('Días planificados: ${plan.plannedDaysCount}/7');
print('Total comidas: ${plan.totalAssignedMeals}');

// Obtener un día específico
final monday = plan.getDayByWeekday(1);
final today = plan.getDayByDate(DateTime.now());
```

## 📡 PlannerService

Servicio para interactuar con la base de datos.

### Métodos principales:

```dart
final service = PlannerService();

// 1. Obtener plan de la semana actual
final currentPlan = await service.getCurrentWeekPlan();

// 2. Obtener o crear plan actual
final plan = await service.getOrCreateCurrentWeekPlan();

// 3. Crear plan para una fecha específica
final newPlan = await service.createWeekPlan(DateTime(2025, 12, 8));

// 4. Asignar receta a una comida
await service.assignRecipeToMeal(mealPlanId, recipeId);

// 5. Remover receta de una comida
await service.removeRecipeFromMeal(mealPlanId);

// 6. Obtener comidas de un día
final meals = await service.getMealsForDay(dayPlanId);

// 7. Duplicar plan a otra semana
await service.duplicateWeekPlan(
  sourcePlanId,
  DateTime(2025, 12, 15), // Nueva semana
);

// 8. Eliminar plan completo
await service.deleteWeekPlan(weekPlanId);

// 9. Listar todos los planes del usuario
final allPlans = await service.getAllWeekPlans();
```

## 🎯 PlannerViewModel

ViewModel con gestión de estado usando ChangeNotifier.

### Uso en Flutter:

```dart
// En main.dart o donde configures los providers
import 'package:provider/provider.dart';
import 'package:mealplanner/features/planner/planner.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlannerViewModel()),
    // ... otros providers
  ],
  child: MyApp(),
)
```

### Uso en widgets:

```dart
class PlannerPage extends StatefulWidget {
  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  @override
  void initState() {
    super.initState();
    // Cargar plan al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlannerViewModel>().loadCurrentWeekPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerViewModel>(
      builder: (context, viewModel, child) {
        // Mostrar loading
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Mostrar error
        if (viewModel.errorMessage != null) {
          return Center(child: Text('Error: ${viewModel.errorMessage}'));
        }

        // Mostrar plan
        final plan = viewModel.currentWeekPlan;
        if (plan == null) {
          return Center(child: Text('No hay plan'));
        }

        return Column(
          children: [
            // Cabecera con navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => viewModel.previousWeek(),
                ),
                Text(plan.dateRangeFormatted),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => viewModel.nextWeek(),
                ),
              ],
            ),
            
            // Estadísticas
            Text(viewModel.planStats),
            
            // Lista de días
            Expanded(
              child: ListView.builder(
                itemCount: plan.days.length,
                itemBuilder: (context, index) {
                  final day = plan.days[index];
                  return DayCard(day: day);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Métodos del ViewModel:

```dart
final viewModel = context.read<PlannerViewModel>();

// Cargar plan actual
await viewModel.loadCurrentWeekPlan();

// Cargar plan para una fecha
await viewModel.loadWeekPlanForDate(DateTime(2025, 12, 15));

// Asignar receta
await viewModel.assignRecipeToMeal(mealPlanId, recipeId);

// Remover receta
await viewModel.removeRecipeFromMeal(mealPlanId);

// Obtener comida específica
final meal = viewModel.getMeal(1, MealType.breakfast); // Lunes, Desayuno

// Obtener comidas de un día
final meals = viewModel.getMealsForDay(1); // Todas las comidas del lunes

// Navegación
await viewModel.previousWeek();
await viewModel.nextWeek();
await viewModel.goToCurrentWeek();

// Operaciones avanzadas
await viewModel.duplicatePlanToWeek(DateTime(2025, 12, 22));
await viewModel.clearAllMeals();
await viewModel.deleteCurrentPlan();

// Acceso a datos
final todayPlan = viewModel.todayPlan;
final isCurrentWeek = viewModel.isDateInCurrentWeek(DateTime.now());
```

## 🎨 Ejemplo de Widget de Comida

```dart
class MealCard extends StatelessWidget {
  final MealPlan meal;
  
  const MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PlannerViewModel>();
    
    return Card(
      child: ListTile(
        leading: Icon(_getMealIcon(meal.mealType)),
        title: Text(meal.mealType.displayName),
        subtitle: Text(
          meal.hasRecipe 
            ? meal.recipeName ?? 'Receta sin nombre'
            : 'Sin planificar'
        ),
        trailing: meal.hasRecipe
          ? IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await viewModel.removeRecipeFromMeal(meal.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta removida')),
                );
              },
            )
          : IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Navegar a selector de recetas
                _showRecipeSelector(context, meal);
              },
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
  
  void _showRecipeSelector(BuildContext context, MealPlan meal) {
    // Implementar selector de recetas
  }
}
```

## 🔄 Flujo de trabajo típico

1. **Inicializar**: Cargar plan de la semana actual
2. **Visualizar**: Mostrar los 7 días con sus comidas
3. **Asignar**: Usuario selecciona una comida y le asigna una receta
4. **Actualizar**: El cambio se refleja automáticamente en la UI
5. **Navegar**: Usuario puede moverse entre semanas
6. **Duplicar**: Copiar plan exitoso a semanas futuras

## ⚠️ Manejo de Errores

```dart
final viewModel = context.read<PlannerViewModel>();

final success = await viewModel.assignRecipeToMeal(mealId, recipeId);

if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(viewModel.errorMessage ?? 'Error desconocido'),
      backgroundColor: Colors.red,
    ),
  );
  viewModel.clearError();
}
```

## 📝 Próximos pasos

1. **Implementar vistas**: Crear widgets para mostrar el planificador
2. **Selector de recetas**: Modal/página para seleccionar recetas
3. **Calendario visual**: Vista de calendario más intuitiva
4. **Notificaciones**: Recordatorios de comidas planificadas
5. **Lista de compras**: Generar lista basada en ingredientes
6. **Exportar**: Compartir plan semanal (PDF, imagen, etc.)

## 🗄️ Base de datos

Para configurar las tablas en Supabase, consulta el archivo `DATABASE_SCHEMA.md` en este mismo directorio.
