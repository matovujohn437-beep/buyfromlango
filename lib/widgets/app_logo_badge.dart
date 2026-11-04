import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../providers/home_provider.dart';
import '../theme.dart';

class AppLogoBadge extends ConsumerWidget {
  const AppLogoBadge({
    super.key,
    required this.size,
    this.plain = false,
    this.circular = false,
  });

  final double size;
  final bool plain;
  final bool circular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Go to listings',
      child: InkWell(
        customBorder: circular
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
        onTap: () {
          ref.read(showHomeHeroSectionProvider.notifier).state = true;
          context.go('/home');
        },
        child: Container(
          width: size,
          height: size,
          padding: plain ? EdgeInsets.zero : EdgeInsets.all(size * 0.06),
          decoration: plain
              ? null
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * 0.22),
                  border: Border.all(color: AppColors.accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
          child: circular
              ? ClipOval(
                  child: Image.asset(
                    AppAssets.appLogo,
                  fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.white,
                      child: Icon(
                        Icons.eco,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                )
              : Image.asset(
                  AppAssets.appLogo,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
        ),
      ),
    );
  }
}
