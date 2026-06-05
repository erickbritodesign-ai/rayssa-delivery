import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/menu/data/datasources/menu_remote_datasource.dart';
import 'package:rayssa_client/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:rayssa_client/features/menu/domain/repositories/menu_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(MenuRemoteDatasource());
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(menuRepositoryProvider).watchCategories();
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  return ref.watch(menuRepositoryProvider).watchProducts(categoryId: categoryId);
});
