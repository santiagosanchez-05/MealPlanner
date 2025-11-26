import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/recipe_viewmodel.dart';
import 'recipe_detail_page.dart';
import 'create_recipe_page.dart';

class RecipeListPage extends StatelessWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<RecipeViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Recetas")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRecipePage()),
          );
        },
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vm.recipes.length,
              itemBuilder: (_, i) {
  final recipe = vm.recipes[i];

  return ListTile(
    leading: recipe.photo != null
        ? Image.memory(recipe.photo!, width: 50, fit: BoxFit.cover)
        : const Icon(Icons.fastfood),

    title: Text(recipe.name),
    subtitle: Text(
      recipe.steps,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),

    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 👁 BOTÓN DETALLE
        IconButton(
  icon: const Icon(Icons.visibility, color: Colors.blue),
  onPressed: () async {
    await vm.loadIngredients(recipe.id);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(
          recipeId: recipe.id,
          name: recipe.name,
          steps: recipe.steps,
          photo: recipe.photo,
        ),
      ),
    );
  },
),


        // 🗑 BOTÓN ELIMINAR
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            vm.delete(recipe.id);
          },
        ),
      ],
    ),
  );
},

            ),
    );
  }
}
