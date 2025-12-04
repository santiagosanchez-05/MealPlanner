import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/category_viewmodel.dart';
import 'create_category_page.dart';
import 'edit_category_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  void initState() {
    super.initState();
    final vm = Provider.of<CategoryViewModel>(context, listen: false);
    vm.loadCategories(); // ✅ CARGA GARANTIZADA
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CategoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Categorías")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateCategoryPage(),
            ),
          );
        },
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.categories.isEmpty
              ? const Center(child: Text("No hay categorías registradas"))
              : ListView.builder(
                  itemCount: vm.categories.length,
                  itemBuilder: (_, i) {
                    final cat = vm.categories[i];

                    return ListTile(
                      title: Text(cat.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✏️ EDITAR
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditCategoryPage(category: cat),
                                ),
                              );
                            },
                          ),

                          // 🗑 ELIMINAR CON VALIDACIÓN + CONFIRM
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                // ✅ 1. Validar si está en uso
                                final used =
                                    await vm.isCategoryUsed(cat.id);

                                if (used) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No se puede eliminar: la categoría está en uso",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // ✅ 2. Mostrar confirmación
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                        const Text("Eliminar categoría"),
                                    content: const Text(
                                      "¿Estás seguro de eliminar esta categoría?\nEsta acción no se puede deshacer.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  ),
                                );

                                // ✅ 3. Eliminación final
                                if (confirm == true) {
                                  await vm.deleteCategory(cat.id);

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Categoría eliminada correctamente",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // ✅ ERROR CONTROLADO
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text("Error al eliminar: $e"),
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
