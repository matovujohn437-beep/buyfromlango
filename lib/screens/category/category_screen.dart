import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../models/listing_detail_route_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/listing_provider.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/listing_status_badge.dart';
import '../../widgets/listing_time_ago.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/listing/job_service_card.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoriesProvider);
    final feed = ref.watch(categoryListingFeedProvider(categoryId));
    final user = ref.watch(currentUserProvider);
    final category = categoryState.valueOrNull
        ?.where((item) => item.id == categoryId)
        .firstOrNull;
    final title = category?.labelEn ?? 'Marketplace';

    return Scaffold(
      appBar: CustomAppBar(title: title),
      bottomNavigationBar: MarketplaceNavigationBar(
        activeCategoryId: categoryId,
      ),
      floatingActionButton: user == null ||
              category == null ||
              feed.isShowingCachedData
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<bool>(
                  '/listing/new?category=${Uri.encodeComponent(categoryId)}',
                );
                if (created == true) {
                  await ref
                      .read(categoryListingFeedProvider(categoryId).notifier)
                      .refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text('Post ${category.labelEn}'),
            ),
      body: ResponsiveContent(
        maxWidth: 1120,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < 450 &&
                feed.hasMore &&
                !feed.isLoadingMore &&
                !feed.isLoading) {
              ref
                  .read(categoryListingFeedProvider(categoryId).notifier)
                  .loadNextPage();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(categoryListingFeedProvider(categoryId).notifier)
                .refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CategoryHeader(
                          category: category,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          onChanged: (value) => ref
                              .read(
                                categoryListingFeedProvider(categoryId)
                                    .notifier,
                              )
                              .setSearchQuery(value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search $title',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (categoryState.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Could not load categories: ${categoryState.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (categoryState.isLoading && category == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (category == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('This marketplace category is unavailable.'),
                    ),
                  )
                else if (feed.isLoading && feed.listings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (feed.error != null && feed.listings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CategoryError(
                      message: 'Could not load listings: ${feed.error}',
                      onRetry: () => ref
                          .read(
                              categoryListingFeedProvider(categoryId).notifier)
                          .refresh(),
                    ),
                  )
                else if (feed.listings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 44,
                              color: AppColors.primary.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No ${title.toLowerCase()} listings yet',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Check back soon or be the first to post.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    sliver: SliverList.builder(
                      itemCount: feed.listings.length,
                      itemBuilder: (context, index) {
                        final listing = feed.listings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: categoryId == 'jobs' ||
                                  categoryId == 'services'
                              ? JobServiceCard(listing: listing)
                              : _CategoryListingCard(
                                  listing: listing,
                                  currentUserId: user?.id,
                                  onChanged: () => ref
                                      .read(
                                        categoryListingFeedProvider(categoryId)
                                            .notifier,
                                      )
                                      .refresh(),
                                ),
                        );
                      },
                    ),
                  ),
                  if (feed.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (feed.error != null)
                    SliverToBoxAdapter(
                      child: _CategoryError(
                        message: 'Could not load more listings: ${feed.error}',
                        onRetry: () => ref
                            .read(categoryListingFeedProvider(categoryId)
                                .notifier)
                            .loadNextPage(),
                      ),
                    ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
  });

  final Category? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
            ),
            alignment: Alignment.center,
            child: category == null
                ? const Icon(Icons.category_outlined, color: Colors.white)
                : SvgPicture.asset(
                    AppAssets.categoryIconForName(category!.iconName),
                    width: 30,
                    height: 30,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    placeholderBuilder: (_) => const Icon(
                      Icons.category_outlined,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.labelEn ?? 'Explore',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _categorySubtitle(category?.id),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categorySubtitle(String? id) => switch (id) {
        'crops' || 'produce' => 'Fresh crops and produce from nearby farmers.',
        'livestock' => 'Healthy animals and trusted local sellers.',
        'services' => 'Vet care, transport, ploughing, irrigation, and more.',
        'supplies' => 'Find farm drugs, fertilizers, seeds, and inputs.',
        'equipment' ||
        'machinery' =>
          'Browse hoes, tractors, mills, and farm machinery.',
        'jobs' => 'Local work opportunities across the community.',
        'cooperatives' => 'Connect with farmer groups and cooperatives.',
        _ => 'Discover trusted listings from your community.',
      };
}

class _CategoryListingCard extends ConsumerWidget {
  const _CategoryListingCard({
    required this.listing,
    required this.currentUserId,
    required this.onChanged,
  });

  final ListingModel listing;
  final String? currentUserId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = currentUserId != null && currentUserId == listing.userId;
    final media = ref.watch(listingMediaProvider(listing.id)).valueOrNull;
    final imageUrl = primaryListingImageUrl(listing, media);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/listing/${listing.id}',
          extra: ListingDetailRouteData(
            primaryImageUrl: imageUrl,
            heroTag: listingHeroTag(listing.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Hero(
                tag: listingHeroTag(listing.id),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: ProductAvatar(
                    categoryId: listing.categoryId,
                    itemName: listing.title,
                    imageUrl: imageUrl,
                    assetName: imageUrl?.startsWith('assets/') == true
                        ? imageUrl
                        : null,
                    size: 88,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ListingStatusBadge(
                          saleStatus: listing.saleStatus,
                          compact: true,
                        ),
                        ListingTimeAgo(
                          createdAt: listing.createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      listing.priceUgx == null
                          ? 'Price negotiable'
                          : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (listing.quantity?.isNotEmpty == true ||
                        listing.unit?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          [listing.quantity, listing.unit]
                              .whereType<String>()
                              .where((value) => value.isNotEmpty)
                              .join(' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  tooltip: 'Manage listing',
                  onSelected: (action) async {
                    if (action == 'edit') {
                      final updated = await context.push<bool>(
                        '/listing/new',
                        extra: listing,
                      );
                      if (updated == true) onChanged();
                    } else if (action == 'remove') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Remove listing?'),
                          content: const Text(
                            'This will hide the listing from the marketplace.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ref
                            .read(listingServiceProvider)
                            .removeListing(listing.id);
                        onChanged();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not remove listing: $error'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child:
                      Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
