import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import 'app_logo_badge.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title = 'Buy From Lango',
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final metadata = user?.userMetadata;
    final avatarUrl =
        metadata?['avatar_url']?.toString() ?? metadata?['picture']?.toString();
    final parsedAvatarUrl =
        avatarUrl == null ? null : Uri.tryParse(avatarUrl.trim());
    final safeAvatarUrl = parsedAvatarUrl != null &&
            parsedAvatarUrl.scheme == 'https' &&
            parsedAvatarUrl.host.isNotEmpty
        ? parsedAvatarUrl.toString()
        : null;

    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const AppLogoBadge(size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (user != null)
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: safeAvatarUrl == null
                  ? const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : ClipOval(
                      child: Image.network(
                        safeAvatarUrl,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          )
        else ...[
          IconButton(
            tooltip: 'Sign In',
            onPressed: () => context.push('/sign-in'),
            icon: const Icon(Icons.login),
          ),
          IconButton(
            tooltip: 'Sign Up',
            onPressed: () => context.push('/sign-up'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ],
    );
  }
}
