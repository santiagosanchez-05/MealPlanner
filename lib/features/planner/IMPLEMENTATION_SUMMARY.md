# HU-03: Implementación del Planificador Semanal

## ✅ Tarea 10 Completada: Lógica de Modelar Planificador

### 📦 Estructura creada

```
lib/features/planner/
├── model/
│   ├── meal_type.dart         ✅ Enum para tipos de comida
│   ├── meal_plan.dart          ✅ Modelo de comida específica
│   ├── day_plan.dart           ✅ Modelo de día completo
│   └── weekly_plan.dart        ✅ Modelo de plan semanal
├── service/
│   └── planner_service.dart    ✅ Servicio con lógica de negocio
├── viewmodel/
│   └── planner_viewmodel.dart  ✅ Gestión de estado
├── view/
│   └── planner_page.dart       ✅ Vista básica del planificador
├── planner.dart                ✅ Archivo de exportación
├── README.md                   ✅ Documentación de uso
└── DATABASE_SCHEMA.md          ✅ Esquema de base de datos
```

### 🎯 Componentes implementados

#### 1. Modelos de datos (model/)

- **MealType** (enum): Define los 3 tipos de comida
  - breakfast (Desayuno)
  - lunch (Almuerzo)  
  - dinner (Cena)

- **MealPlan**: Representa una comida específica
  - Propiedades: id, dayPlanId, mealType, recipeId, recipeName, timestamps
  - Métodos: hasRecipe, fromJson(), toJson(), copyWith()

- **DayPlan**: Representa un día completo (7 días por semana)
  - Propiedades: id, weeklyPlanId, date, dayOfWeek, meals[], timestamps
  - Métodos: dayName, getMealByType(), assignedMealsCount, isFullyPlanned

- **WeeklyPlan**: Representa el plan semanal completo
  - Propiedades: id, userId, weekStartDate, weekEndDate, weekNumber, year, days[], timestamps
  - Métodos: forDate(), dateRangeFormatted, getDayByDate(), getDayByWeekday(), plannedDaysCount, totalAssignedMeals

#### 2. Servicio (service/)

**PlannerService** - Lógica de negocio y comunicación con Supabase:

Operaciones de Weekly Plans:
- `getCurrentWeekPlan()` - Obtiene plan actual
- `getOrCreateCurrentWeekPlan()` - Obtiene o crea plan
- `createWeekPlan(date)` - Crea plan para fecha
- `getWeekPlanById(id)` - Obtiene plan por ID
- `deleteWeekPlan(id)` - Elimina plan completo
- `getAllWeekPlans()` - Lista todos los planes

Operaciones de Meal Plans:
- `assignRecipeToMeal(mealId, recipeId)` - Asigna receta
- `removeRecipeFromMeal(mealId)` - Remueve receta
- `getMealsForDay(dayId)` - Obtiene comidas del día

Operaciones avanzadas:
- `duplicateWeekPlan(sourceId, targetDate)` - Duplica plan

#### 3. ViewModel (viewmodel/)

**PlannerViewModel** - Gestión de estado con ChangeNotifier:

Estado:
- currentWeekPlan, isLoading, errorMessage, selectedDate
- Getters: hasPlan, days, planStats, todayPlan

Métodos principales:
- `loadCurrentWeekPlan()` - Carga plan actual
- `loadWeekPlanForDate(date)` - Carga plan para fecha
- `assignRecipeToMeal(mealId, recipeId)` - Asigna receta
- `removeRecipeFromMeal(mealId)` - Remueve receta
- `getMeal(dayOfWeek, mealType)` - Obtiene comida específica
- `previousWeek() / nextWeek()` - Navegación entre semanas
- `goToCurrentWeek()` - Vuelve a semana actual
- `duplicatePlanToWeek(date)` - Duplica plan
- `clearAllMeals()` - Limpia todas las comidas
- `deleteCurrentPlan()` - Elimina plan actual

#### 4. Vista (view/)

**PlannerPage** - Página básica del planificador:

Características:
- Header con navegación entre semanas (← →)
- Botón para ir a semana actual
- Menú de acciones (duplicar, limpiar, eliminar)
- Lista de 7 días expandibles
- Cada día muestra 3 comidas (desayuno, almuerzo, cena)
- Indicador visual del día actual ("HOY")
- Opción para agregar/remover recetas de cada comida
- Manejo de estados: loading, error, sin plan, plan cargado
- Diálogos de confirmación para acciones destructivas

### 🗄️ Base de datos

Se documentó el esquema completo en `DATABASE_SCHEMA.md`:

Tablas:
- `weekly_plans` - Planes semanales
- `day_plans` - Días individuales (7 por plan)
- `meal_plans` - Comidas (3 por día = 21 por plan)

Características:
- Borrado en cascada configurado
- Políticas RLS (Row Level Security) implementadas
- Índices para optimización de consultas
- Triggers para actualizar timestamps automáticamente
- Constraints para integridad de datos

### 🔗 Relaciones

```
User (auth.users)
    │
    └─> WeeklyPlan (1 por semana)
            │
            └─> DayPlan (7 días)
                    │
                    └─> MealPlan (3 comidas)
                            │
                            └─> Recipe (opcional)
```

### 📖 Documentación

- **README.md**: Guía completa de uso con ejemplos de código
- **DATABASE_SCHEMA.md**: Esquema SQL completo con políticas RLS
- **planner.dart**: Archivo de exportación para importar fácilmente

### 🚀 Próximos pasos sugeridos

1. **Configurar base de datos**: Ejecutar SQL en Supabase (DATABASE_SCHEMA.md)
2. **Integrar con provider**: Agregar PlannerViewModel al MultiProvider
3. **Selector de recetas**: Implementar modal para seleccionar recetas
4. **Mejorar UI**: Agregar calendario visual, drag & drop
5. **Lista de compras**: Generar automáticamente desde plan semanal
6. **Notificaciones**: Recordatorios de comidas planificadas

### ✨ Características destacadas

✅ Arquitectura MVVM completa
✅ Modelos con validación y métodos utilitarios
✅ Servicio con manejo robusto de errores
✅ ViewModel con gestión de estado reactivo
✅ Vista funcional con navegación entre semanas
✅ Documentación completa y ejemplos
✅ Esquema de base de datos profesional con RLS
✅ Código formateado y sin errores
✅ Preparado para integración con recipes existentes

---

**Estimación original**: Alta
**Estado**: ✅ COMPLETADA
**Fecha**: 1 de Diciembre, 2025
