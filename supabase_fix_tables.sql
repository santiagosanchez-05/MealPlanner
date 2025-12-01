-- ============================================
-- SCRIPT PARA CORREGIR LA ESTRUCTURA DE TABLAS
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ADVERTENCIA: Este script eliminará la tabla weekly_plans actual
-- Si tienes datos importantes, haz un backup primero

-- PRIMERO: Eliminar la tabla incorrecta weekly_plans
DROP TABLE IF EXISTS weekly_plans CASCADE;

-- También eliminar day_plans y meal_plans si existen
DROP TABLE IF EXISTS day_plans CASCADE;
DROP TABLE IF EXISTS meal_plans CASCADE;

-- ============================================
-- CREAR LAS 3 TABLAS CORRECTAMENTE
-- ============================================

-- 1. TABLA: weekly_plans (Plan semanal completo)
CREATE TABLE weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, week_start_date)
);

CREATE INDEX idx_weekly_plans_user_date ON weekly_plans(user_id, week_start_date);

-- 2. TABLA: day_plans (Un día dentro del plan semanal)
CREATE TABLE day_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_day_plans_weekly ON day_plans(weekly_plan_id);

-- 3. TABLA: meal_plans (Una comida dentro de un día)
CREATE TABLE meal_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES day_plans(id) ON DELETE CASCADE,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner')),
  recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(day_plan_id, meal_type)
);

CREATE INDEX idx_meal_plans_day ON meal_plans(day_plan_id);
CREATE INDEX idx_meal_plans_recipe ON meal_plans(recipe_id);

-- ============================================
-- FUNCIÓN PARA ACTUALIZAR updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_weekly_plans_updated_at
  BEFORE UPDATE ON weekly_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_day_plans_updated_at
  BEFORE UPDATE ON day_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at
  BEFORE UPDATE ON meal_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- POLÍTICAS DE SEGURIDAD (RLS)
-- ============================================

ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE day_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;

-- Políticas para weekly_plans
CREATE POLICY "Users can view their own weekly plans"
  ON weekly_plans FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own weekly plans"
  ON weekly_plans FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own weekly plans"
  ON weekly_plans FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own weekly plans"
  ON weekly_plans FOR DELETE USING (auth.uid() = user_id);

-- Políticas para day_plans
CREATE POLICY "Users can view day plans from their weekly plans"
  ON day_plans FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create day plans in their weekly plans"
  ON day_plans FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update day plans in their weekly plans"
  ON day_plans FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete day plans in their weekly plans"
  ON day_plans FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM weekly_plans
      WHERE weekly_plans.id = day_plans.weekly_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- Políticas para meal_plans
CREATE POLICY "Users can view meal plans from their day plans"
  ON meal_plans FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create meal plans in their day plans"
  ON meal_plans FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update meal plans in their day plans"
  ON meal_plans FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete meal plans in their day plans"
  ON meal_plans FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM day_plans
      JOIN weekly_plans ON weekly_plans.id = day_plans.weekly_plan_id
      WHERE day_plans.id = meal_plans.day_plan_id
      AND weekly_plans.user_id = auth.uid()
    )
  );

-- ✅ COMPLETADO
