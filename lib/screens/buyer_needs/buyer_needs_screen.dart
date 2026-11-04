import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/buyer_need.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buyer_need_provider.dart';
import '../../providers/home_provider.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/post_metadata.dart';
import '../../widgets/listing_time_ago.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_screen.dart';

class BuyerNeedsScreen extends ConsumerWidget {
  const BuyerNeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final needs = ref.watch(activeBuyerNeedsProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Buyer Demands',
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.push('/chats'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'See what buyers are looking for and connect with them.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: needs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'We could not load buyer demands. Check your connection '
                        'and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(activeBuyerNeedsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const Center(
                        child: Text('There are no active buyer demands yet.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          100,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _BuyerNeedCard(
                          need: items[index],
                          currentUserId: user?.id,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MarketplaceNavigationBar(
        selectedIndex: 3,
        showCategoryShortcuts: false,
        onDestinationSelected: (index) =>
            _navigate(context, ref, index, fromHome: false),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          if (Supabase.instance.client.auth.currentSession == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to post a buyer demand.'),
                ),
              );
            if (context.mounted) context.push('/sign-in');
            return;
          }
          final created = await context.push<bool>('/buyer-needs/new');
          if (created == true) {
            ref.invalidate(activeBuyerNeedsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Post a Demand'),
      ),
    );
  }

  void _navigate(
    BuildContext context,
    WidgetRef ref,
    int index, {
    required bool fromHome,
  }) {
    switch (index) {
      case 0:
        if (context.canPop()) {
          context.pop();
        } else {
          ref.read(showHomeHeroSectionProvider.notifier).state = true;
          context.go('/home');
        }
      case 1:
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      case 2:
        context.go('/profile');
      case 3:
        if (fromHome) context.go('/buyer-needs');
    }
  }
}

class _BuyerNeedCard extends ConsumerStatefulWidget {
  const _BuyerNeedCard({
    required this.need,
    required this.currentUserId,
  });

  final BuyerNeedModel need;
  final String? currentUserId;

  @override
  ConsumerState<_BuyerNeedCard> createState() => _BuyerNeedCardState();
}

class _BuyerNeedCardState extends ConsumerState<_BuyerNeedCard> {
  bool _showContact = false;
  bool _loadingContact = false;
  String? _phone;

  BuyerNeedModel get need => widget.need;

  String get _location => [
        need.parishName,
        need.subcountyName,
        need.districtName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

  Future<void> _revealContact() async {
    if (widget.currentUserId == null) {
      context.push('/sign-in');
      return;
    }
    if (widget.currentUserId == need.userId) {
      setState(() => _showContact = !_showContact);
      return;
    }
    setState(() => _loadingContact = true);
    try {
      final phone =
          await ref.read(buyerNeedServiceProvider).getContactPhone(need.id);
      if (mounted) {
        setState(() {
          _phone = phone;
          _showContact = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not load the contact details. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  Future<void> _startChat() async {
    final userId = widget.currentUserId;
    if (userId == null) {
      context.push('/sign-in');
      return;
    }
    try {
      final thread =
          await ref.read(buyerNeedServiceProvider).getOrCreateContactThread(
                needId: need.id,
                requesterId: need.userId,
                responderId: userId,
              );
      if (!mounted) return;
      await context.push(
        '/chat/${thread.id}',
        extra: ChatRouteData(otherUserName: need.contactPerson),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('We could not start a conversation. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId == need.userId;
    final quantity = [
      need.quantity?.toString(),
      need.unit,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductAvatar(
                  categoryId: productCategoryId(
                    categoryId: need.categoryId,
                    itemName: need.itemName,
                  ),
                  itemName: need.itemName,
                  imageUrl: need.itemImageUrl,
                  size: 64,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        need.itemName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (quantity.isNotEmpty) Text('Looking for $quantity'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => context.push('/seller/${need.userId}'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BuyerNeedAvatar(url: need.posterAvatarUrl),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      need.posterName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  if (need.posterIsVerified) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    const Icon(
                                      Icons.verified,
                                      size: 17,
                                      color: AppColors.verifiedBadge,
                                      semanticLabel: 'Verified',
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                need.posterAccountType == 'cooperative'
                                    ? 'Co-op'
                                    : 'Individual',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (need.proposedPriceUgx != null)
                  Text(
                    'UGX ${need.proposedPriceUgx!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Contact: ${need.contactPerson}'),
            if (need.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(need.notes!),
            ],
            const SizedBox(height: AppSpacing.sm),
            PostMetadata(
              location: _location,
              createdVia: need.createdVia,
            ),
            ListingTimeAgo(
              createdAt: need.createdAt,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_showContact && widget.currentUserId != null) ...[
              if (_phone != null && _phone!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: SelectableText(_phone!)),
                    IconButton(
                      tooltip: 'Call buyer',
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'tel', path: _phone)),
                      icon: const Icon(Icons.call_outlined),
                    ),
                  ],
                )
              else
                const Text('No phone number is available for this request.'),
              if (!isOwner)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Message buyer'),
                  ),
                ),
            ] else if (widget.currentUserId == null)
              TextButton.icon(
                onPressed: _revealContact,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Sign in to contact the buyer'),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _loadingContact ? null : _revealContact,
                  icon: _loadingContact
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.contact_phone_outlined),
                  label: Text(isOwner ? 'Contact details' : 'Contact buyer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuyerNeedAvatar extends StatelessWidget {
  const _BuyerNeedAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final parsed = url == null ? null : Uri.tryParse(url!.trim());
    final safeUrl =
        parsed != null && parsed.scheme == 'https' && parsed.host.isNotEmpty
            ? parsed.toString()
            : null;
    return CircleAvatar(
      backgroundColor: AppColors.primaryLight,
      child: safeUrl == null
          ? const Icon(
              Icons.person_outline,
              color: AppColors.primary,
            )
          : ClipOval(
              child: Image.network(
                safeUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}
