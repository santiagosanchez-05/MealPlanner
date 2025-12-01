/// Enumeración que representa los tipos de comidas del día
enum MealType {
  breakfast('Desayuno'),
  lunch('Almuerzo'),
  dinner('Cena');

  final String displayName;

  const MealType(this.displayName);

  /// Convierte un string a MealType
  static MealType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'breakfast':
      case 'desayuno':
        return MealType.breakfast;
      case 'lunch':
      case 'almuerzo':
        return MealType.lunch;
      case 'dinner':
      case 'cena':
        return MealType.dinner;
      default:
        throw ArgumentError('Invalid meal type: $value');
    }
  }

  /// Convierte el MealType a string para base de datos
  String toDBString() {
    return name;
  }
}
