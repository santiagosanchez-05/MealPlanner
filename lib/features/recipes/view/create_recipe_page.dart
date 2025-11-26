import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/ingredient_model.dart';
import '../viewmodel/recipe_viewmodel.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final nameCtrl = TextEditingController();
  final stepsCtrl = TextEditingController();

  final ingCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final catCtrl = TextEditingController();

  Uint8List? photo;
  List<IngredientModel> ingredients = [];

  void addIngredient() {
    ingredients.add(
      IngredientModel(
        name: ingCtrl.text,
        quantity: qtyCtrl.text,
        category: catCtrl.text,
      ),
    );

    ingCtrl.clear();
    qtyCtrl.clear();
    catCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Receta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: stepsCtrl, decoration: const InputDecoration(labelText: "Preparación")),

            const Divider(),

            TextField(controller: ingCtrl, decoration: const InputDecoration(labelText: "Ingrediente")),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Cantidad")),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: "Categoría")),

            ElevatedButton(
              onPressed: addIngredient,
              child: const Text("Agregar Ingrediente"),
            ),

            Expanded(
              child: ListView(
                children: ingredients
                    .map((e) => ListTile(
                          title: Text(e.name),
                          subtitle: Text("${e.quantity} - ${e.category}"),
                        ))
                    .toList(),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                await vm.addRecipe(
                  nameCtrl.text,
                  stepsCtrl.text,
                  photo,
                  ingredients,
                );
                Navigator.pop(context);
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }
}
