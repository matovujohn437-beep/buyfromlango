import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing.dart';
import '../../models/listing_detail_route_data.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/seller_tools_provider.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/listing_status_badge.dart';
import '../../widgets/listing_time_ago.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/seller_tag_picker_sheet.dart';
import '../chat/chat_screen.dart';

class SellerCatalogScreen extends ConsumerStatefulWidget {
  const SellerCatalogScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<SellerCatalogScreen> createState() =>
      _SellerCatalogScreenState();
}

class _SellerCatalogScreenState extends ConsumerState<SellerCatalogScreen> {
  bool _contactingSeller = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sellerCatalogProfileProvider(widget.sellerId));
    final listings = ref.watch(sellerCatalogListingsProvider(widget.sellerId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Seller Catalog'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 1100,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CatalogError(
            message: 'Could not load this seller: $error',
            onRetry: () =>
                ref.invalidate(sellerCatalogProfileProvider(widget.sellerId)),
          ),
          data: (seller) {
            if (seller == null) {
              return const Center(child: Text('This seller is unavailable.'));
            }
            final currentUserId = ref.watch(currentUserProvider)?.id;
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                        ? 3
                        : 2;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SellerHeader(
                        seller: seller,
                        isOwnCatalog: currentUserId == seller.id,
                        isContacting: _contactingSeller,
                        onContact: () => _contactSeller(
                          seller: seller,
                          listings: listings.valueOrNull,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Active Listings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      listings.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => _CatalogError(
                          message: 'Could not load listings: $error',
                          onRetry: () => ref.invalidate(
                            sellerCatalogListingsProvider(widget.sellerId),
                          ),
                        ),
                        data: (items) => items.isEmpty
                            ? const EmptyState(
                                title: 'No active products',
                                message:
                                    'This seller currently has no active products.',
                                imagePath:
                                    'assets/illustrations/empty_listings.png',
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  mainAxisExtent: 252,
                                ),
                                itemBuilder: (context, index) =>
                                    _CatalogListingCard(
                                  listing: items[index],
                                  ownerId: currentUserId == seller.id
                                      ? seller.id
                                      : null,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _contactSeller({
    required ProfileModel seller,
    required List<ListingModel>? listings,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      await context.push('/sign-in');
      return;
    }
    if (userId == seller.id || _contactingSeller) return;

    setState(() => _contactingSeller = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final thread = await chatService.getLatestThreadBetweenUsers(
            firstUserId: userId,
            secondUserId: seller.id,
          ) ??
          (listings?.isNotEmpty == true
              ? await chatService.getOrCreateThread(
                  listingId: listings!.first.id,
                  buyerId: userId,
                  sellerId: seller.id,
                )
              : null);

      if (!mounted) return;
      if (thread == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This seller has no active listings to start a new chat.',
            ),
          ),
        );
        return;
      }

      await context.push(
        '/chat/${thread.id}',
        extra: ChatRouteData(
          otherUserName: seller.fullName?.trim().isNotEmpty == true
              ? seller.fullName!.trim()
              : 'Seller',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not contact this seller: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _contactingSeller = false);
    }
  }
}

class _SellerHeader extends StatelessWidget {
  const _SellerHeader({
    required this.seller,
    required this.isOwnCatalog,
    required this.isContacting,
    required this.onContact,
  });

  final ProfileModel seller;
  final bool isOwnCatalog;
  final bool isContacting;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final name = seller.isAnonymous
        ? 'Anonymous seller'
        : seller.fullName?.trim().isNotEmpty == true
            ? seller.fullName!.trim()
            : 'Seller';
    final memberSince = seller.createdAt == null
        ? null
        : '${_monthName(seller.createdAt!.month)} ${seller.createdAt!.year}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 126,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primaryLight,
                        AppColors.accent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -24,
                  top: -45,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x17FFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  right: 56,
                  bottom: -62,
                  child: Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x29FFFFFF),
                        width: 18,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: AppSpacing.lg,
                  top: AppSpacing.md,
                  child: Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'BUY FROM LANGO  /  STOREFRONT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.lg,
                  child: Text(
                    'Good things grow here',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 4,
                    ),
                  ),
                  child: ProfileAvatar(
                    imageUrl: seller.isAnonymous ? null : seller.avatarUrl,
                    radius: 42,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                if (seller.districtName?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(seller.districtName!.trim()),
                    ],
                  ),
                ],
                if (memberSince != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Member since $memberSince',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isOwnCatalog || isContacting ? null : onContact,
                    icon: isContacting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_outlined),
                    label: Text(
                      isOwnCatalog ? 'Your storefront' : 'Chat with Seller',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogListingCard extends ConsumerWidget {
  const _CatalogListingCard({required this.listing, this.ownerId});

  final ListingModel listing;
  final String? ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = [
      listing.quantity,
      listing.unit,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/listing/${listing.id}',
          extra: ListingDetailRouteData(
            primaryImageUrl: listing.imageUrl,
            heroTag: listingHeroTag(listing.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Hero(
                tag: listingHeroTag(listing.id),
                child: ProductAvatar(
                  categoryId: listing.categoryId,
                  itemName: listing.title,
                  imageUrl: listing.imageUrl?.startsWith('assets/') == true
                      ? null
                      : listing.imageUrl,
                  assetName: listing.imageUrl?.startsWith('assets/') == true
                      ? listing.imageUrl
                      : null,
                  size: 82,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (quantity.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quantity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              Text(
                listing.priceUgx == null
                    ? 'Price negotiable'
                    : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ListingStatusBadge(
                saleStatus: listing.saleStatus,
                compact: true,
              ),
              ListingTimeAgo(
                createdAt: listing.createdAt,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (ownerId != null)
                ref.watch(listingTagKeysProvider((ownerId!, listing.id))).when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => Text(
                        'Could not load tags: $error',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                      data: (keys) => SellerTagPills(tagKeys: keys),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

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
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
