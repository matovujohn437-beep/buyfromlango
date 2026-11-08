import 'package:flutter/material.dart';

import '../theme.dart';

enum AppToastType { success, error, info }

abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final color = switch (type) {
      AppToastType.success => AppColors.success,
      AppToastType.error => AppColors.error,
      AppToastType.info => AppColors.primary,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          content: Row(
            children: [
              Icon(
                switch (type) {
                  AppToastType.success => Icons.check_circle_outline,
                  AppToastType.error => Icons.error_outline,
                  AppToastType.info => Icons.info_outline,
                },
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
