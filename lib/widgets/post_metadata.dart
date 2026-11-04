import 'package:flutter/material.dart';

import '../theme.dart';

class PostMetadata extends StatelessWidget {
  const PostMetadata({
    super.key,
    this.location,
    this.createdVia = 'app',
    this.showOrigin = true,
  });

  final String? location;
  final String? createdVia;
  final bool showOrigin;

  @override
  Widget build(BuildContext context) {
    final locationText = location?.trim();
    final isSms = createdVia == 'sms' || createdVia == 'ussd';
    final originMessage = switch (createdVia) {
      'sms' => 'Posted via SMS',
      'ussd' => 'Posted via USSD',
      _ => 'Posted via mobile app',
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (locationText != null && locationText.isNotEmpty)
          Tooltip(
            message: locationText,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        if (showOrigin)
          Tooltip(
            message: originMessage,
            child: Icon(
              isSms ? Icons.sms_outlined : Icons.smartphone,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
