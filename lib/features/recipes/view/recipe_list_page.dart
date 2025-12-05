import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/recipe_viewmodel.dart';
import 'recipe_detail_page.dart';
import 'create_recipe_page.dart';
import '../model/recipe_model.dart';  
import 'edit_recipe_page.dart';

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
    // 👁 BOTÓN VER DETALLE
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
            ),

          ),
        );
      },
    ),

    // ✏️ BOTÓN EDITAR
    // ✏️ BOTÓN EDITAR
IconButton(
  icon: const Icon(Icons.edit, color: Colors.orange),
  onPressed: () async {
    // 1️⃣ Cargar ingredientes desde la BD
    await vm.loadIngredients(recipe.id);

    if (!context.mounted) return;

    // 2️⃣ CLONAR la receta con sus ingredientes reales
    final recipeToEdit = RecipeModel(
      id: recipe.id,
      name: recipe.name,
      steps: recipe.steps,
      photo: recipe.photo,
      ingredients: List.from(vm.ingredients), // ✅ AQUÍ ESTÁ LA CLAVE
    );

    // 3️⃣ Enviar receta COMPLETA al edit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRecipePage(
          recipe: recipeToEdit,
        ),
      ),
    );
  },
),


    // 🗑 BOTÓN ELIMINAR
   // 🗑 BOTÓN ELIMINAR CON CONFIRMACIÓN
IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar receta"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar esta receta?\nEsta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    // ✅ Si el usuario confirma
    if (confirm == true) {
      await vm.delete(recipe.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Receta eliminada correctamente"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
