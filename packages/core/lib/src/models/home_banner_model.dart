import 'package:equatable/equatable.dart';

class HomeBannerModel extends Equatable {
  const HomeBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.targetType = 'none',
    this.targetId,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetType;
  final String? targetId;
  final int order;
  final bool isActive;

  factory HomeBannerModel.fromFirestore(String id, Map<String, dynamic> data) {
    return HomeBannerModel(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      targetType: data['targetType'] as String? ?? 'none',
      targetId: data['targetId'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'targetType': targetType,
      'targetId': targetId,
      'order': order,
      'isActive': isActive,
    };
  }

  HomeBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? targetType,
    String? targetId,
    int? order,
    bool? isActive,
  }) {
    return HomeBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        imageUrl,
        targetType,
        targetId,
        order,
        isActive,
      ];
}
