import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/category_viewmodel.dart';

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CategoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Categoría")),
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

                await vm.addCategory(nameCtrl.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}
