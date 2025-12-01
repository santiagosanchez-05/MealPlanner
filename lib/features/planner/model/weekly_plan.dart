import 'day_plan.dart';

/// Modelo que representa el plan semanal completo
class WeeklyPlan {
  final String? id;
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int weekNumber;
  final int year;
  final List<DayPlan> days;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyPlan({
    this.id,
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.weekNumber,
    required this.year,
    List<DayPlan>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : days = days ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Crea un plan semanal para una fecha específica
  factory WeeklyPlan.forDate(DateTime date, String userId) {
    // Obtener el lunes de la semana
    final dayOfWeek = date.weekday;
    final monday = date.subtract(Duration(days: dayOfWeek - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Calcular el número de semana del año
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = weekStart.difference(firstDayOfYear).inDays;
    final weekNumber = (daysSinceStart / 7).ceil() + 1;

    return WeeklyPlan(
      userId: userId,
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      weekNumber: weekNumber,
      year: date.year,
      days: [],
    );
  }

  /// Obtiene el rango de fechas formateado
  String get dateRangeFormatted {
    final startFormatted =
        '${weekStartDate.day}/${weekStartDate.month}/${weekStartDate.year}';
    final endFormatted =
        '${weekEndDate.day}/${weekEndDate.month}/${weekEndDate.year}';
    return '$startFormatted - $endFormatted';
  }

  /// Obtiene un día específico por fecha
  DayPlan? getDayByDate(DateTime date) {
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      return days.firstWhere(
        (day) =>
            DateTime(day.date.year, day.date.month, day.date.day) ==
            normalizedDate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un día específico por día de la semana (1-7)
  DayPlan? getDayByWeekday(int dayOfWeek) {
    try {
      return days.firstWhere((day) => day.dayOfWeek == dayOfWeek);
    } catch (e) {
      return null;
    }
  }

  /// Cuenta cuántos días tienen al menos una comida planificada
  int get plannedDaysCount {
    return days.where((day) => day.assignedMealsCount > 0).length;
  }

  /// Cuenta el total de comidas asignadas en la semana
  int get totalAssignedMeals {
    return days.fold(0, (total, day) => total + day.assignedMealsCount);
  }

  /// Indica si la semana está completamente planificada
  bool get isFullyPlanned {
    return days.length == 7 && days.every((day) => day.isFullyPlanned);
  }

  /// Crea una instancia desde JSON (respuesta de Supabase)
  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      weekEndDate: DateTime.parse(json['week_end_date'] as String),
      weekNumber: json['week_number'] as int,
      year: json['year'] as int,
      days: json['days'] != null
          ? (json['days'] as List)
                .map((day) => DayPlan.fromJson(day as Map<String, dynamic>))
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
      'user_id': userId,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'week_end_date': weekEndDate.toIso8601String().split('T')[0],
      'week_number': weekNumber,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia del WeeklyPlan con algunos campos actualizados
  WeeklyPlan copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    int? weekNumber,
    int? year,
    List<DayPlan>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      weekNumber: weekNumber ?? this.weekNumber,
      year: year ?? this.year,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WeeklyPlan(id: $id, week: $weekNumber/$year, range: $dateRangeFormatted, days: ${days.length})';
  }
}
