import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/recipe_viewmodel.dart';
import 'edit_recipe_page.dart';
import '../model/recipe_model.dart';
import '../../categories/model/category_model.dart';

class RecipeDetailPage extends StatelessWidget {
  final String recipeId;
  final String name;
  final String steps;
  final Uint8List? photo;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    required this.name,
    required this.steps,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    // ✅ Crear objeto completo para enviar al Edit
    final recipe = RecipeModel(
      id: recipeId,
      name: name,
      steps: steps,
      photo: photo,
      ingredients: vm.ingredients,
    );

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FOTO =================
            if (photo != null)
              Center(
                child: Image.memory(
                  photo!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // ================= PREPARACIÓN =================
            const Text(
              "Preparación",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(steps),

            const SizedBox(height: 20),

            // ================= INGREDIENTES =================
            const Text(
              "Ingredientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: vm.ingredients.isEmpty
                  ? const Center(child: Text("No hay ingredientes"))
                  : ListView.builder(
                      itemCount: vm.ingredients.length,
                      itemBuilder: (_, i) {
                        final ing = vm.ingredients[i];

                        // ✅ Buscar nombre de la categoría por ID
                        final catName = vm.categories
                            .firstWhere(
                              (c) => c.id == ing.categoryId,
                              orElse: () =>
                                  CategoryModel(id: '', name: 'Sin categoría'),
                            )
                            .name;

                        return ListTile(
                          leading:
                              const Icon(Icons.circle, size: 10),
                          title: Text(ing.name),
                          subtitle: Text("${ing.quantity} - $catName"),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),

            // ================= BOTÓN EDITAR =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditRecipePage(recipe: recipe),
                    ),
                  );
                },
                child: const Text("EDITAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
