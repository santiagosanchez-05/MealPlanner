import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/ingredient_model.dart';
import '../model/recipe_model.dart';
import '../../categories/model/category_model.dart';
import '../viewmodel/recipe_viewmodel.dart';

class EditRecipePage extends StatefulWidget {
  final RecipeModel recipe;

  const EditRecipePage({super.key, required this.recipe});

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController stepsCtrl;

  final ingCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  String? selectedCategoryId; // ✅ FK REAL

  Uint8List? photo;
  List<IngredientModel> ingredients = [];

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.recipe.name);
    stepsCtrl = TextEditingController(text: widget.recipe.steps);
    photo = widget.recipe.photo;
    ingredients = List.from(widget.recipe.ingredients);

    final vm = Provider.of<RecipeViewModel>(context, listen: false);
    vm.loadCategories(); // ✅ cargar categorías
  }

  // ============================
  // AGREGAR INGREDIENTE
  // ============================
  void addIngredient() {
    final name = ingCtrl.text.trim();
    final qty = qtyCtrl.text.trim();

    if (name.isEmpty || qty.isEmpty || selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nombre, cantidad y categoría son obligatorios"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Evitar duplicados
    final exists = ingredients.any(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este ingrediente ya fue agregado"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validar formato cantidad
    final validFormat = RegExp(r'^\d+(\s?[a-zA-Z]+)?$');

    if (!validFormat.hasMatch(qty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("La cantidad debe iniciar con un número (ej: 2, 500g, 1 taza)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final numberPart =
        int.parse(RegExp(r'^\d+').firstMatch(qty)!.group(0)!);

    if (numberPart > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cantidad es demasiado grande"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ingredients.add(
      IngredientModel(
        name: name,
        quantity: qty,
        categoryId: selectedCategoryId!,
      ),
    );

    ingCtrl.clear();
    qtyCtrl.clear();
    selectedCategoryId = null;
    setState(() {});
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
    setState(() {});
  }

  // ============================
  // GUARDAR CAMBIOS
  // ============================
  Future<void> saveChanges(RecipeViewModel vm) async {
  if (!_formKey.currentState!.validate()) return;

  if (ingredients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Debes agregar al menos un ingrediente"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    await vm.updateRecipe(
      widget.recipe.id,
      nameCtrl.text.trim(),
      stepsCtrl.text.trim(),
      photo,
      ingredients,
    );

    if (!context.mounted) return;

    Navigator.pop(context); // ✅ SOLO SE EJECUTA SI TODO SALE BIEN
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error al actualizar receta: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Receta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ================= NOMBRE =================
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "El nombre es obligatorio";
                  }
                  if (value.trim().length < 3) {
                    return "Mínimo 3 caracteres";
                  }
                  if (value.trim().length > 30) {
                    return "Máximo 30 caracteres";
                  }
                  return null;
                },
              ),

              // ================= PREPARACIÓN =================
              TextFormField(
                controller: stepsCtrl,
                decoration: const InputDecoration(labelText: "Preparación"),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "La preparación es obligatoria";
                  }
                  if (value.trim().length < 10) {
                    return "Debe tener mínimo 10 caracteres";
                  }
                  return null;
                },
              ),

              const Divider(),

              // ================= INGREDIENTE =================
              TextField(
                controller: ingCtrl,
                decoration: const InputDecoration(labelText: "Ingrediente"),
              ),

              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]+[a-zA-Z\s]*$'),
                  ),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              // ================= CATEGORÍA =================
              DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              decoration: const InputDecoration(labelText: "Categoría"),
              items: vm.categories.map((CategoryModel cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
              },
            ),


              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: addIngredient,
                child: const Text("Agregar Ingrediente"),
              ),

              // ================= LISTA =================
              Expanded(
                child: ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (_, i) {
                    final e = ingredients[i];
                    final catName = vm.categories
                        .firstWhere((c) => c.id == e.categoryId)
                        .name;

                    return ListTile(
                      title: Text(e.name),
                      subtitle: Text("${e.quantity} - $catName"),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeIngredient(i),
                      ),
                    );
                  },
                ),
              ),

              // ================= GUARDAR CAMBIOS =================
              ElevatedButton(
                onPressed: () => saveChanges(vm),
                child: const Text("GUARDAR CAMBIOS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
