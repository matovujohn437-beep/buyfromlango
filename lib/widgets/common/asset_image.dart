import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_assets.dart';

class AssetImageFallback extends StatelessWidget {
  const AssetImageFallback({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: fit,
        width: width,
        height: height,
      );
    }
    return Image.asset(
      asset,
      fit: fit,
      width: width,
      height: height,
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final image = imageUrl == null || imageUrl!.isEmpty
        ? AssetImageFallback(
            asset: AppAssets.placeholderAvatar,
            width: size,
            height: size,
          )
        : imageUrl!.startsWith('assets/')
            ? AssetImageFallback(
                asset: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => AssetImageFallback(
                  asset: AppAssets.placeholderAvatar,
                  width: size,
                  height: size,
                ),
                errorWidget: (_, __, ___) => AssetImageFallback(
                  asset: AppAssets.placeholderAvatar,
                  width: size,
                  height: size,
                ),
              );

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: ClipOval(child: image),
    );
  }
}
