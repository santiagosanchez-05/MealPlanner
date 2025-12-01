# Planificador Semanal - Estructura de Base de Datos

## Esquema de tablas en Supabase

### Tabla: `weekly_plans`
Plan semanal completo de un usuario.

```sql
CREATE TABLE weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Índices para búsqueda rápida
  UNIQUE(user_id, week_start_date)
);

-- Índice para búsquedas por usuario y fecha
CREATE INDEX idx_weekly_plans_user_date ON weekly_plans(user_id, week_start_date);
```

### Tabla: `day_plans`
Representa cada día dentro de un plan semanal.

```sql
CREATE TABLE day_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas por plan semanal
CREATE INDEX idx_day_plans_weekly ON day_plans(weekly_plan_id);
```

### Tabla: `meal_plans`
Representa cada comida (desayuno, almuerzo, cena) de cada día.

```sql
CREATE TABLE meal_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES day_plans(id) ON DELETE CASCADE,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner')),
  recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Cada día debe tener solo una comida de cada tipo
  UNIQUE(day_plan_id, meal_type)
);

-- Índice para búsquedas por día
CREATE INDEX idx_meal_plans_day ON meal_plans(day_plan_id);
-- Índice para búsquedas por receta (para saber en qué planes se usa una receta)
CREATE INDEX idx_meal_plans_recipe ON meal_plans(recipe_id);
```

## Políticas de Seguridad (RLS)

### weekly_plans
```sql
-- Habilitar RLS
ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;

-- Los usuarios solo pueden ver sus propios planes
CREATE POLICY "Users can view their own weekly plans"
  ON weekly_plans FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden crear sus propios planes
CREATE POLICY "Users can create their own weekly plans"
  ON weekly_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios solo pueden actualizar sus propios planes
CREATE POLICY "Users can update their own weekly plans"
  ON weekly_plans FOR UPDATE
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden eliminar sus propios planes
CREATE POLICY "Users can delete their own weekly plans"
  ON weekly_plans FOR DELETE
  USING (auth.uid() = user_id);
```

### day_plans
```sql
-- Habilitar RLS
ALTER TABLE day_plans ENABLE ROW LEVEL SECURITY;

-- Los usuarios pueden ver días de sus planes semanales
CREATE POLICY "Users can view day plans from their weekly plans"
  ON day_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden crear días en sus planes semanales
CREATE POLICY "Users can create day plans in their weekly plans"
  ON day_plans FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden actualizar días en sus planes semanales
CREATE POLICY "Users can update day plans in their weekly plans"
  ON day_plans FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden eliminar días en sus planes semanales
CREATE POLICY "Users can delete day plans in their weekly plans"
  ON day_plans FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );
```

### meal_plans
```sql
-- Habilitar RLS
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;

-- Los usuarios pueden ver comidas de sus días
CREATE POLICY "Users can view meal plans from their day plans"
  ON meal_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden crear comidas en sus días
CREATE POLICY "Users can create meal plans in their day plans"
  ON meal_plans FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden actualizar comidas en sus días
CREATE POLICY "Users can update meal plans in their day plans"
  ON meal_plans FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Los usuarios pueden eliminar comidas en sus días
CREATE POLICY "Users can delete meal plans in their day plans"
  ON meal_plans FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );
```

## Funciones de utilidad

### Función para actualizar `updated_at` automáticamente
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a las tablas
CREATE TRIGGER update_weekly_plans_updated_at
  BEFORE UPDATE ON weekly_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_day_plans_updated_at
  BEFORE UPDATE ON day_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at
  BEFORE UPDATE ON meal_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Relaciones

```
weekly_plans (1) ──────< (N) day_plans
                             │
                             │
                             └──< (N) meal_plans ──> (1) recipes
```

## Notas de implementación

1. **Borrado en cascada**: Cuando se elimina un `weekly_plan`, automáticamente se eliminan todos sus `day_plans` y `meal_plans` asociados.

2. **Borrado de recetas**: Cuando se elimina una receta, las referencias en `meal_plans` se establecen a NULL (ON DELETE SET NULL), no se elimina el plan.

3. **Unicidad**: 
   - Un usuario no puede tener dos planes para la misma semana
   - Un día no puede tener dos comidas del mismo tipo

4. **Índices**: Se han creado índices para optimizar las consultas más comunes:
   - Búsqueda de planes por usuario y fecha
   - Búsqueda de días por plan semanal
   - Búsqueda de comidas por día
   - Búsqueda de planes que usan una receta específica
