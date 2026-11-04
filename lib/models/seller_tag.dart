import 'package:flutter/material.dart';

class SellerTag {
  const SellerTag({
    required this.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  static const all = [
    SellerTag(
      key: 'maize_bulk_buyer',
      label: 'Maize Bulk Buyer',
      icon: Icons.grain,
      backgroundColor: Color(0xFFFFF1CC),
      foregroundColor: Color(0xFF795600),
    ),
    SellerTag(
      key: 'coffee_retailer',
      label: 'Coffee Retailer',
      icon: Icons.coffee,
      backgroundColor: Color(0xFFEFE1D4),
      foregroundColor: Color(0xFF69452E),
    ),
    SellerTag(
      key: 'repeat_buyer',
      label: 'Repeat Buyer',
      icon: Icons.replay_rounded,
      backgroundColor: Color(0xFFDDF1E2),
      foregroundColor: Color(0xFF24643A),
    ),
    SellerTag(
      key: 'follow_up',
      label: 'Follow up',
      icon: Icons.schedule_rounded,
      backgroundColor: Color(0xFFE4ECF7),
      foregroundColor: Color(0xFF36577F),
    ),
    SellerTag(
      key: 'priority',
      label: 'Priority',
      icon: Icons.star_outline_rounded,
      backgroundColor: Color(0xFFF7E2E4),
      foregroundColor: Color(0xFF8A3E46),
    ),
    SellerTag(
      key: 'new_contact',
      label: 'New contact',
      icon: Icons.waving_hand_outlined,
      backgroundColor: Color(0xFFECE5F5),
      foregroundColor: Color(0xFF59447A),
    ),
  ];

  static SellerTag? byKey(String key) {
    for (final tag in all) {
      if (tag.key == key) return tag;
    }
    return null;
  }
}
