import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../service/category_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> categories = [];
  bool isLoading = false;

  Future<void> loadCategories() async {
    isLoading = true;
    notifyListeners();

    final data = await _service.getCategories();
    categories = data.map((e) => CategoryModel.fromJson(e)).toList();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _service.insertCategory(name);
    await loadCategories();
  }

  Future<void> updateCategory(String id, String name) async {
    await _service.updateCategory(id, name);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
    await loadCategories();
  }
  // ✅ VALIDAR SI LA CATEGORÍA ESTÁ EN USO
  Future<bool> isCategoryUsed(String categoryId) async {
    return await _service.isCategoryUsed(categoryId);
  }
}
