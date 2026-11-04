import 'package:flutter/material.dart';

import '../theme.dart';

class ListingStatusBadge extends StatelessWidget {
  const ListingStatusBadge({
    super.key,
    required this.saleStatus,
    this.compact = false,
  });

  final String saleStatus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (saleStatus) {
      'partially_sold' => (
          'Partially sold',
          Icons.timelapse,
          AppColors.accentDark,
        ),
      'fully_sold' || 'sold' => (
          'Out of stock',
          Icons.remove_shopping_cart_outlined,
          const Color(0xFF667085),
        ),
      _ => ('Available', Icons.check_circle_outline, AppColors.success),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
