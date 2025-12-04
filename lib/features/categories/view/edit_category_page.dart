import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/category_model.dart';
import '../viewmodel/category_viewmodel.dart';

class EditCategoryPage extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryPage({super.key, required this.category});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  late TextEditingController nameCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.category.name);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CategoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Categoría")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre de categoría",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                await vm.updateCategory(
                  widget.category.id,
                  nameCtrl.text.trim(),
                );

                Navigator.pop(context);
              },
              child: const Text("Guardar cambios"),
            )
          ],
        ),
      ),
    );
  }
}
