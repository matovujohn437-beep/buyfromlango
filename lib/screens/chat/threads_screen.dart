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

class ThreadsScreen extends ConsumerStatefulWidget {
  const ThreadsScreen({super.key});

  @override
  ConsumerState<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends ConsumerState<ThreadsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.inbox_outlined),
                    label: Text('Inbox'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.archive_outlined),
                    label: Text('Archived'),
                  ),
                ],
                selected: {_showArchived},
                onSelectionChanged: (selection) =>
                    setState(() => _showArchived = selection.single),
              ),
            ),
            Expanded(
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
                          onPressed: () => ref.invalidate(
                            watchedChatThreadsProvider(user.id),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  final visibleItems = items
                      .where((thread) =>
                          thread.isArchivedFor(user.id) == _showArchived)
                      .toList();
                  if (visibleItems.isEmpty) {
                    return EmptyState(
                      title: _showArchived
                          ? 'No archived chats'
                          : 'No conversations yet',
                      message: _showArchived
                          ? 'Archived conversations will appear here.'
                          : 'Open a listing and message its seller to get started.',
                      imagePath: AppAssets.emptyChat,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _ThreadTile(
                      thread: visibleItems[index],
                      currentUserId: user.id,
                      isArchived: _showArchived,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({
    required this.thread,
    required this.currentUserId,
    required this.isArchived,
  });

  final ChatThreadModel thread;
  final String currentUserId;
  final bool isArchived;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isArchived ? 'Restore chat' : 'Archive chat',
              visualDensity: VisualDensity.compact,
              onPressed: () => _setArchived(context, ref),
              icon: Icon(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Delete chat',
              visualDensity: VisualDensity.compact,
              color: AppColors.error,
              onPressed: () => _confirmDeleteChat(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        onTap: () => context.push(
          '/chat/${thread.id}',
          extra: ChatRouteData(otherUserName: title),
        ),
      ),
    );
  }

  Future<void> _setArchived(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(chatServiceProvider).setChatArchivedForCurrentUser(
            threadId: thread.id,
            archived: !isArchived,
          );
      ref.invalidate(watchedChatThreadsProvider(currentUserId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isArchived ? 'Chat restored to inbox.' : 'Chat archived.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update chat: $error')),
        );
      }
    }
  }

  Future<void> _confirmDeleteChat(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'This removes the conversation from your inbox. The other participant '
          'can still see it, and new messages will bring it back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(chatServiceProvider).deleteChatForCurrentUser(thread.id);
      ref.invalidate(watchedChatThreadsProvider(currentUserId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat removed from your inbox.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete chat: $error')),
        );
      }
    }
  }
}
