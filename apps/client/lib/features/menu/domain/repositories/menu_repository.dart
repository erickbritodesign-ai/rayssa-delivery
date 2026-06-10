import 'package:rayssa_core/rayssa_core.dart';

abstract class MenuRepository {
  Stream<List<CategoryModel>> watchCategories();
  Stream<List<HomeBannerModel>> watchHomeBanners();
  Stream<List<ProductModel>> watchProducts({String? categoryId});
}
