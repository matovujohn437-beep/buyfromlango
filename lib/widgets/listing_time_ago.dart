import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ListingTimeAgo extends StatelessWidget {
  const ListingTimeAgo({
    super.key,
    required this.createdAt,
    this.style,
  });

  final DateTime? createdAt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final timestamp = createdAt;
    if (timestamp == null) return const SizedBox.shrink();
    return Text(
      timeago.format(timestamp.toLocal()),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}
