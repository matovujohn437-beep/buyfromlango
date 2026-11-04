import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../models/chat_thread.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/listing_provider.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import 'chat_screen.dart';

class ThreadsScreen extends ConsumerWidget {
  const ThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Messages'),
        bottomNavigationBar: MarketplaceNavigationBar(selectedIndex: 1),
        body: Center(child: Text('Sign in to view your messages.')),
      );
    }

    final threads = ref.watch(watchedChatThreadsProvider(user.id));
    return Scaffold(
      appBar: const CustomAppBar(title: 'Messages'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 900,
        child: threads.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load your conversations: $error'),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(watchedChatThreadsProvider(user.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'No conversations yet',
                  message:
                      'Open a listing and message its seller to get started.',
                  imagePath: AppAssets.emptyChat,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _ThreadTile(
                    thread: items[index],
                    currentUserId: user.id,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({
    required this.thread,
    required this.currentUserId,
  });

  final ChatThreadModel thread;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId =
        thread.buyerId == currentUserId ? thread.sellerId : thread.buyerId;
    final otherUser = ref.watch(listingSellerProvider(otherUserId));
    final title = otherUser.when(
      data: (profile) {
        final name = profile?.fullName?.trim();
        return name == null || name.isEmpty ? 'Farmer' : name;
      },
      loading: () => 'Loading conversation…',
      error: (_, __) => 'Conversation',
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: ProfileAvatar(
          imageUrl: otherUser.valueOrNull?.avatarUrl,
          radius: 22,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: FutureBuilder<String>(
          future: ref.read(chatServiceProvider).getThreadContextTitle(thread),
          builder: (context, snapshot) => Text(
            snapshot.data ?? 'Loading conversation…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/chat/${thread.id}',
          extra: ChatRouteData(otherUserName: title),
        ),
      ),
    );
  }
}
