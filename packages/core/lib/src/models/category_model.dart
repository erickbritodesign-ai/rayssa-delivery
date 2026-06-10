import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.isActive = true,
    this.imageUrl,
    this.subtitle,
    this.showOnHome = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final String? imageUrl;
  final String? subtitle;
  final bool showOnHome;

  factory CategoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      sortOrder: data['sortOrder'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
      subtitle: data['subtitle'] as String?,
      showOnHome: data['showOnHome'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'subtitle': subtitle,
      'showOnHome': showOnHome,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isActive,
    String? imageUrl,
    String? subtitle,
    bool? showOnHome,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      subtitle: subtitle ?? this.subtitle,
      showOnHome: showOnHome ?? this.showOnHome,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sortOrder,
        isActive,
        imageUrl,
        subtitle,
        showOnHome,
      ];
}
