import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.isActive = true,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final String? imageUrl;

  factory CategoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      sortOrder: data['sortOrder'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'imageUrl': imageUrl,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isActive,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, isActive, imageUrl];
}
