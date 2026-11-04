import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/product_catalog.dart';
import '../theme.dart';

class ProductAvatar extends StatelessWidget {
  const ProductAvatar({
    super.key,
    required this.categoryId,
    this.itemName,
    this.imageUrl,
    this.imageBytes,
    this.assetName,
    this.size = 52,
  });

  final String? categoryId;
  final String? itemName;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? assetName;
  final double size;

  IconData get _icon {
    switch (itemName?.trim().toLowerCase()) {
      case 'egg':
      case 'eggs':
        return Icons.breakfast_dining;
      case 'milk':
        return Icons.local_drink;
      case 'beef':
      case 'pork':
        return Icons.restaurant;
      case 'tractor':
      case 'tractors':
        return Icons.agriculture;
      case 'water pump':
      case 'sprayer':
      case 'sprayers':
        return Icons.construction;
    }

    return switch (categoryId) {
      'crops' || 'produce' => Icons.agriculture,
      'livestock' => Icons.pets,
      'services' => Icons.miscellaneous_services,
      'jobs' => Icons.work_outline,
      'supplies' => Icons.inventory_2_outlined,
      'equipment' => Icons.construction_outlined,
      'cooperatives' => Icons.groups_outlined,
      _ => Icons.shopping_basket_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    final parsedUrl = trimmedUrl == null || trimmedUrl.isEmpty
        ? null
        : Uri.tryParse(trimmedUrl);
    final image = imageBytes != null
        ? Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackIcon(),
          )
        : assetName != null
            ? Image.asset(
                assetName!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
              )
            : parsedUrl != null &&
                    parsedUrl.scheme == 'https' &&
                    parsedUrl.host.isNotEmpty
                ? Image.network(
                    parsedUrl.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  )
                : _fallbackIcon();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: image,
        ),
      ),
    );
  }

  Widget _fallbackIcon() => Icon(
        _icon,
        color: AppColors.primary,
        size: size * 0.52,
      );
}

String? productCategoryId({
  String? categoryId,
  String? itemName,
}) {
  final normalizedCategory = categoryId?.trim();
  return normalizedCategory == null || normalizedCategory.isEmpty
      ? productCategoryForItem(itemName)
      : normalizedCategory;
}
