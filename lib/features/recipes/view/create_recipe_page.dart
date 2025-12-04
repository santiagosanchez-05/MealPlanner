import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/ingredient_model.dart';
import '../../categories/model/category_model.dart';
import '../viewmodel/recipe_viewmodel.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final stepsCtrl = TextEditingController();
  final ingCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  String? selectedCategoryId;
  Uint8List? photo;
  List<IngredientModel> ingredients = [];

  @override
  void initState() {
    super.initState();
    Provider.of<RecipeViewModel>(context, listen: false).loadCategories();
  }

  void addIngredient() {
    final name = ingCtrl.text.trim();
    final qty = qtyCtrl.text.trim();

    if (name.isEmpty || qty.isEmpty || selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa ingrediente, cantidad y categoría")),
      );
      return;
    }

    final validFormat = RegExp(r'^\d+(\s?[a-zA-Z]+)?$');
    if (!validFormat.hasMatch(qty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cantidad inválida")),
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

  Future<void> saveRecipe(RecipeViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agrega al menos un ingrediente")),
      );
      return;
    }

    await vm.addRecipe(
      nameCtrl.text.trim(),
      stepsCtrl.text.trim(),
      photo,
      ingredients,
    );

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Receta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v == null || v.isEmpty ? "Obligatorio" : null,
              ),

              TextFormField(
                controller: stepsCtrl,
                decoration: const InputDecoration(labelText: "Preparación"),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.length < 10 ? "Mínimo 10 caracteres" : null,
              ),

              const Divider(),

              TextField(
                controller: ingCtrl,
                decoration: const InputDecoration(labelText: "Ingrediente"),
              ),

              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: "Cantidad"),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]+[a-zA-Z\s]*$'),
                  ),
                ],
              ),

              DropdownButtonFormField<String>(
                initialValue: selectedCategoryId,
                decoration: const InputDecoration(labelText: "Categoría"),
                items: vm.categories.map((CategoryModel cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  selectedCategoryId = value;
                }),
              ),

              ElevatedButton(
                onPressed: addIngredient,
                child: const Text("Agregar Ingrediente"),
              ),

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
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: () => saveRecipe(vm),
                child: const Text("GUARDAR"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
