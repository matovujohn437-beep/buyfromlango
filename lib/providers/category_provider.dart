import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/category_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) => CategoryService());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryServiceProvider).getCategories();
});

final listingCatalogProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryServiceProvider).getListingCatalog();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.read(categoryServiceProvider).watchCategories();
});
