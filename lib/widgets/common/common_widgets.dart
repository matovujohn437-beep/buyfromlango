import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_assets.dart';
import '../../theme.dart';
import 'asset_image.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}

class Badge extends StatelessWidget {
  const Badge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.iconPath,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SvgPicture.asset(
                  iconPath!,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.all(0),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.soft,
        ),
        child: child,
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.size,
  });

  final String? imageUrl;
  final double radius;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final finalSize = size ?? radius * 2;
    final hasImage = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('http');
    final hasAsset = imageUrl != null && imageUrl!.startsWith('assets/');
    return ClipOval(
      child: SizedBox(
        width: finalSize,
        height: finalSize,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Image.asset(
                  AppAssets.placeholderAvatar,
                  fit: BoxFit.cover,
                ),
                errorWidget: (_, __, ___) => Image.asset(
                  AppAssets.placeholderAvatar,
                  fit: BoxFit.cover,
                ),
              )
            : hasAsset
                ? AssetImageFallback(
                    asset: imageUrl!,
                    width: finalSize,
                    height: finalSize,
                    fit: BoxFit.cover,
                  )
                : Image.asset(AppAssets.placeholderAvatar, fit: BoxFit.cover),
      ),
    );
  }
}

class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.currency = 'UGX',
  });

  final num price;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$currency ${price.toString()}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    this.rating = 5,
    this.count = 0,
  });

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, color: AppColors.accent, size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '($count)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.imagePath,
  });

  final String title;
  final String? message;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final image = imagePath ?? AppAssets.emptyListings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image.endsWith('.svg'))
              SvgPicture.asset(image, width: 180, height: 180)
            else
              Image.asset(image, width: 180, height: 180, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.errorState,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: PrimaryButton(label: 'Retry', onPressed: onRetry),
              ),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.signal_wifi_connected_no_internet_4,
              color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Cached data will be shown when available.',
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer(
      {super.key, this.height = 120, this.width = double.infinity});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderAsset = AppAssets.placeholderAvatar,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImageFallback(
        asset: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => AssetImageFallback(
        asset: placeholderAsset,
        width: width,
        height: height,
        fit: fit,
      ),
      errorWidget: (_, __, ___) => AssetImageFallback(
        asset: placeholderAsset,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
