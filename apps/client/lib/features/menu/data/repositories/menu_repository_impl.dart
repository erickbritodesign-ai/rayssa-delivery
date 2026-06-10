import 'package:rayssa_client/features/menu/data/datasources/menu_remote_datasource.dart';
import 'package:rayssa_client/features/menu/domain/repositories/menu_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._datasource);

  final MenuRemoteDatasource _datasource;

  @override
  Stream<List<CategoryModel>> watchCategories() =>
      _datasource.watchCategories();

  @override
  Stream<List<HomeBannerModel>> watchHomeBanners() =>
      _datasource.watchHomeBanners();

  @override
  Stream<List<ProductModel>> watchProducts({String? categoryId}) =>
      _datasource.watchProducts(categoryId: categoryId);
}
