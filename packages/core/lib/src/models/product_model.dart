import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    this.isActive = true,
    this.isFeatured = false,
    this.featuredOrder = 0,
    this.featuredBadgeLabel,
    this.featuredImageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final bool isActive;
  final bool isFeatured;
  final int featuredOrder;
  final String? featuredBadgeLabel;
  final String? featuredImageUrl;

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      categoryId: data['categoryId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      featuredOrder: (data['featuredOrder'] as num?)?.toInt() ?? 0,
      featuredBadgeLabel: data['featuredBadgeLabel'] as String?,
      featuredImageUrl: data['featuredImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'featuredOrder': featuredOrder,
      'featuredBadgeLabel': featuredBadgeLabel,
      'featuredImageUrl': featuredImageUrl,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    bool? isAvailable,
    bool? isActive,
    bool? isFeatured,
    int? featuredOrder,
    String? featuredBadgeLabel,
    String? featuredImageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredOrder: featuredOrder ?? this.featuredOrder,
      featuredBadgeLabel: featuredBadgeLabel ?? this.featuredBadgeLabel,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    categoryId,
    imageUrl,
    isAvailable,
    isActive,
    isFeatured,
    featuredOrder,
    featuredBadgeLabel,
    featuredImageUrl,
  ];
}
