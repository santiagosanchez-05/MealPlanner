import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/recipe_viewmodel.dart';
import 'edit_recipe_page.dart';
import '../model/recipe_model.dart';
import '../../categories/model/category_model.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  @override
  void initState() {
    super.initState();
    final vm = Provider.of<RecipeViewModel>(context, listen: false);

    // ✅ SIEMPRE cargar ingredientes al entrar
    vm.loadIngredients(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    // ✅ SIEMPRE obtener la receta DESDE el ViewModel
    final recipe =
        vm.recipes.firstWhere((r) => r.id == widget.recipeId);

    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FOTO =================
            if (recipe.photo != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    recipe.photo!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ================= PREPARACIÓN =================
            const Text(
              "Preparación",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(recipe.steps), // ✅ AHORA SÍ SE ACTUALIZA

            const SizedBox(height: 20),

            // ================= INGREDIENTES =================
            const Text(
              "Ingredientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            vm.ingredients.isEmpty
                ? const Center(child: Text("No hay ingredientes"))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vm.ingredients.length,
                    itemBuilder: (_, i) {
                      final ing = vm.ingredients[i];

                      final catName = vm.categories
                          .firstWhere(
                            (c) => c.id == ing.categoryId,
                            orElse: () =>
                                CategoryModel(id: '', name: 'Sin categoría'),
                          )
                          .name;

                      return ListTile(
                        title: Text(ing.name),
                        subtitle:
                            Text("${ing.quantity} - $catName"),
                      );
                    },
                  ),

            const SizedBox(height: 20),

            // ================= EDITAR =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditRecipePage(recipe: recipe),
                  ),
                );

                if (updated == true) {
                  await vm.loadRecipes();                    // refresca nombre + pasos
                  await vm.loadIngredients(widget.recipeId); // refresca ingredientes
                  if (mounted) setState(() {});              // 🔥 fuerza UI en caliente
                }
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

