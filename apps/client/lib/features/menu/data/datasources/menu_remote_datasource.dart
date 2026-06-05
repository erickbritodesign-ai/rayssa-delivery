import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayssa_core/rayssa_core.dart';

class MenuRemoteDatasource {
  MenuRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection(FirestoreCollections.categorias)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.id, doc.data()))
          .toList();

      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  Stream<List<ProductModel>> watchProducts({String? categoryId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.produtos)
        .where('isActive', isEqualTo: true)
        .where('isAvailable', isEqualTo: true);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
          .toList();

      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }
}