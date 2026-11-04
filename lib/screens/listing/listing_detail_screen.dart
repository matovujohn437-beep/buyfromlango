import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../constants/app_assets.dart';
import '../../models/listing.dart';
import '../../models/listing_detail_route_data.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../supabase_config.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/listing_status_badge.dart';
import '../../widgets/listing_time_ago.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.routeData,
  });

  final int listingId;
  final ListingDetailRouteData? routeData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingDetailProvider(listingId));
    final user = ref.watch(currentUserProvider);
    final item = listing.valueOrNull;
    final media = listing.valueOrNull?.isCachedOffline == true
        ? const AsyncData<List<ListingMediaModel>>([])
        : ref.watch(listingMediaProvider(listingId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Listing Details',
        actions: [
          if (item != null && user?.id == item.userId)
            IconButton(
              tooltip: 'Edit listing',
              onPressed: () async {
                final saved =
                    await context.push<bool>('/listing/$listingId/edit');
                if (saved == true) {
                  ref
                    ..invalidate(listingDetailProvider(listingId))
                    ..invalidate(listingMediaProvider(listingId));
                }
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 1100,
        padding: EdgeInsets.zero,
        child: listing.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: 'Could not load listing: $error',
            onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
          ),
          data: (item) => _ListingContent(
            listing: item,
            media: media,
            routeData: routeData,
          ),
        ),
      ),
    );
  }
}

class _ListingContent extends ConsumerWidget {
  const _ListingContent({
    required this.listing,
    required this.media,
    required this.routeData,
  });

  final ListingModel listing;
  final AsyncValue<List<ListingMediaModel>> media;
  final ListingDetailRouteData? routeData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = listing.isCachedOffline
        ? const AsyncData<ProfileModel?>(null)
        : ref.watch(listingSellerProvider(listing.userId));
    final user = ref.watch(currentUserProvider);
    final categories = ref.watch(categoriesProvider);
    final primaryImageUrl = routeData?.primaryImageUrl ?? listing.imageUrl;
    final heroTag = routeData?.heroTag ?? listingHeroTag(listing.id);

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxWidth >= 840
                      ? 220.0
                      : constraints.maxWidth >= 600
                          ? 190.0
                          : 150.0;
                  return SizedBox(
                    height: height,
                    child: media.when(
                      loading: () => _primaryImage(
                        primaryImageUrl,
                        listing.categoryId,
                        heroTag,
                      ),
                      error: (error, _) => primaryImageUrl != null
                          ? _primaryImage(
                              primaryImageUrl,
                              listing.categoryId,
                              heroTag,
                            )
                          : listing.isCachedOffline
                              ? _primaryImage(
                                  null,
                                  listing.categoryId,
                                  heroTag,
                                )
                              : _MediaError(error: error),
                      data: (mediaItems) {
                        final primaryIndex = mediaItems.indexWhere(
                          (item) =>
                              item.mediaType == 'image' &&
                              item.mediaUrl == primaryImageUrl,
                        );
                        if (mediaItems.isEmpty) {
                          return _primaryImage(
                            primaryImageUrl,
                            listing.categoryId,
                            heroTag,
                          );
                        }
                        final firstImageIndex = mediaItems.indexWhere(
                          (item) => item.mediaType == 'image',
                        );
                        final initialIndex = primaryIndex >= 0
                            ? primaryIndex
                            : firstImageIndex >= 0
                                ? firstImageIndex
                                : 0;
                        final orderedMedia = [
                          mediaItems[initialIndex],
                          ...mediaItems.where(
                            (item) =>
                                !identical(item, mediaItems[initialIndex]),
                          ),
                        ];
                        return PageView.builder(
                          itemCount: orderedMedia.length,
                          itemBuilder: (context, index) => _ListingMediaView(
                            media: orderedMedia[index],
                            fallbackAsset: AppAssets.listingImageForCategory(
                              listing.categoryId,
                            ),
                            heroTag: index == 0 ? heroTag : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          listing.priceUgx == null
                              ? 'Negotiable'
                              : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (listing.isFeatured)
                          const Icon(Icons.star, color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ListingStatusBadge(saleStatus: listing.saleStatus),
                        if (listing.districtName?.isNotEmpty == true)
                          _CompactDetail(
                            icon: Icons.location_on_outlined,
                            label: listing.districtName!,
                          ),
                        ListingTimeAgo(
                          createdAt: listing.createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (listing.workersNeeded != null &&
                        listing.workersNeeded! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  listing.categoryId == 'jobs'
                                      ? 'Hiring ${listing.workersNeeded} ${listing.workersNeeded == 1 ? 'worker' : 'workers'}'
                                      : '${listing.workersNeeded} ${listing.workersNeeded == 1 ? 'worker' : 'workers'} needed for this service',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (user?.id == listing.userId)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _SellerSaleStatusControl(listing: listing),
                      ),
                    if (user != null &&
                        user.id != listing.userId &&
                        !listing.isCachedOffline)
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _reportListing(context, listing, user.id),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text('Report listing'),
                          ),
                          TextButton.icon(
                            onPressed: () => _blockSeller(
                              context,
                              listing.userId,
                            ),
                            icon: const Icon(Icons.block_outlined, size: 18),
                            label: const Text('Block poster'),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        categories.when(
                          data: (items) {
                            final category = items
                                .where((item) => item.id == listing.categoryId)
                                .firstOrNull;
                            return category == null
                                ? const SizedBox.shrink()
                                : Chip(
                                    avatar: const Icon(
                                      Icons.category_outlined,
                                      size: 17,
                                    ),
                                    label: Text(category.labelEn),
                                  );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (listing.isNegotiable)
                          const Chip(
                            avatar: Icon(Icons.swap_horiz, size: 17),
                            label: Text('Negotiable'),
                          ),
                        if (listing.quantity?.isNotEmpty == true ||
                            listing.unit?.isNotEmpty == true)
                          Chip(
                            avatar: const Icon(
                              Icons.inventory_2_outlined,
                              size: 17,
                            ),
                            label: Text(
                              [
                                listing.quantity,
                                listing.unit,
                              ]
                                  .whereType<String>()
                                  .where((value) => value.isNotEmpty)
                                  .join(' '),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (listing.isCachedOffline)
                      const Text(
                        'Poster details are available when you reconnect.',
                      )
                    else
                      seller.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, _) =>
                            Text('Could not load poster profile: $error'),
                        data: (profile) => _SellerCard(
                          profile: profile,
                          profileId: listing.userId,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      listing.description?.trim().isNotEmpty == true
                          ? listing.description!
                          : 'The poster has not added a description.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (listing.isCachedOffline)
          const OfflineBanner()
        else if (user == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Sign in to contact the poster or make an offer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else if (user.id == listing.userId)
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/chats'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Reply to buyers in Messages'),
                  ),
                ),
              ),
            ),
          )
        else
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ContactRequestButton(
                      listingId: listing.id,
                      buyerId: user.id,
                      sellerId: listing.userId,
                      listingTitle: listing.title,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _makeOffer(context, ref, user.id),
                      icon: const Icon(Icons.local_offer_outlined),
                      label: const Text('Make an Offer'),
                    ),
                    if (listing.priceUgx != null)
                      FilledButton.tonalIcon(
                        onPressed: () => _buyNow(context, ref, user.id),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Buy Now'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _reportListing(
    BuildContext context,
    ListingModel listing,
    String reporterId,
  ) async {
    const reasons = [
      'Suspected scam',
      'Misleading listing',
      'Incorrect price or quantity',
      'Prohibited or unsafe item',
      'Other',
    ];
    final detailsController = TextEditingController();
    var reason = reasons.first;
    try {
      final report = await showDialog<(String, String)>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Report listing'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: [
                    for (final value in reasons)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => reason = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: detailsController,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional details (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  (reason, detailsController.text.trim()),
                ),
                child: const Text('Submit report'),
              ),
            ],
          ),
        ),
      );
      if (report == null) return;
      await SupabaseConfig.client.from('reports').insert({
        'reporter_id': reporterId,
        'target_listing_id': listing.id,
        'target_user_id': listing.userId,
        'reason': report.$1,
        'details': report.$2.isEmpty ? null : report.$2,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thank you. Your report was submitted.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit report: $error')),
        );
      }
    } finally {
      detailsController.dispose();
    }
  }

  Future<void> _blockSeller(
    BuildContext context,
    String sellerId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block this poster?'),
        content: const Text(
          'You will not be able to start a new chat with this poster.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block poster'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;
      await SupabaseConfig.client.from('blocks').insert({
        'blocker_id': userId,
        'blocked_user_id': sellerId,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poster blocked.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not block poster: $error')),
        );
      }
    }
  }

  Future<void> _makeOffer(
    BuildContext context,
    WidgetRef ref,
    String buyerId,
  ) async {
    if (buyerId == listing.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot make an offer on your own listing.')),
      );
      return;
    }
    final offer = await showModalBottomSheet<_OfferDetails>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MakeOfferSheet(listing: listing),
    );
    if (offer == null || !context.mounted) return;

    try {
      await ref.read(orderServiceProvider).createOrder({
        'listing_id': listing.id,
        'buyer_id': buyerId,
        'seller_id': listing.userId,
        'agreed_price_ugx': offer.price,
        'agreed_quantity': offer.quantity,
        'notes': offer.note,
        'status': 'negotiating',
        'type': 'offer',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your offer has been sent.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send your offer: $error')),
        );
      }
    }
  }

  Future<void> _buyNow(
    BuildContext context,
    WidgetRef ref,
    String buyerId,
  ) async {
    if (buyerId == listing.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot order your own listing.')),
      );
      return;
    }
    final price = listing.priceUgx;
    if (price == null || price <= 0) return;
    final quantity = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BuyNowSheet(listing: listing, pricePerUnit: price),
    );
    if (quantity == null || !context.mounted) return;

    final total = price * quantity;
    try {
      await ref.read(orderServiceProvider).createOrder({
        'listing_id': listing.id,
        'buyer_id': buyerId,
        'seller_id': listing.userId,
        'agreed_price_ugx': total,
        'agreed_quantity': quantity.toString(),
        'status': 'agreed',
        'type': 'order',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your order has been placed.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place your order: $error')),
        );
      }
    }
  }
}

class _ContactRequestButton extends ConsumerStatefulWidget {
  const _ContactRequestButton({
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.listingTitle,
  });

  final int listingId;
  final String buyerId;
  final String sellerId;
  final String listingTitle;

  @override
  ConsumerState<_ContactRequestButton> createState() =>
      _ContactRequestButtonState();
}

class _ContactRequestButtonState extends ConsumerState<_ContactRequestButton> {
  bool _isSending = false;

  Future<void> _requestContact() async {
    setState(() => _isSending = true);
    try {
      await ref.read(orderServiceProvider).requestSellerContact(
            listingId: widget.listingId,
            buyerId: widget.buyerId,
            sellerId: widget.sellerId,
            listingTitle: widget.listingTitle,
          );
      ref.invalidate(ordersProvider(widget.buyerId));
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Request sent. The seller can share their number from Orders.',
              ),
            ),
          );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request seller contact: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: _isSending ? null : _requestContact,
        icon: _isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.phone_callback_outlined),
        label: const Text('Request Seller’s Phone Number'),
      );
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.profile, required this.profileId});

  final ProfileModel? profile;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final name = profile?.isAnonymous == true
        ? 'Anonymous poster'
        : profile?.fullName?.trim();
    final displayName =
        name == null || name.isEmpty ? 'Poster name not provided' : name;
    final avatar = profile?.avatarUrl;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            profile == null ? null : () => context.push('/seller/$profileId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: profile?.isAnonymous == true ? null : avatar,
                radius: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (profile?.isVerified == true) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    if (profile?.districtName?.isNotEmpty == true)
                      Text(
                        profile!.districtName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (profile != null) ...[
                Tooltip(
                  message: profile?.isFeaturePhoneUser == true
                      ? 'Feature phone user'
                      : 'Smartphone app user',
                  child: Icon(
                    profile?.isFeaturePhoneUser == true
                        ? Icons.sms_outlined
                        : Icons.smartphone_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingMediaView extends StatefulWidget {
  const _ListingMediaView({
    required this.media,
    required this.fallbackAsset,
    this.heroTag,
  });

  final ListingMediaModel media;
  final String fallbackAsset;
  final String? heroTag;

  @override
  State<_ListingMediaView> createState() => _ListingMediaViewState();
}

class _ListingMediaViewState extends State<_ListingMediaView> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.media.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.mediaUrl),
      )
        ..addListener(_updateVideoState)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((Object error) {
          if (mounted) setState(() => _error = error);
        });
    } else if (widget.media.mediaType == 'audio') {
      _audioPlayer = AudioPlayer();
    }
  }

  @override
  void dispose() {
    _videoController
      ?..removeListener(_updateVideoState)
      ..dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ListingMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.mediaUrl == widget.media.mediaUrl &&
        oldWidget.media.mediaType == widget.media.mediaType) {
      return;
    }
    _videoController
      ?..removeListener(_updateVideoState)
      ..dispose();
    _audioPlayer?.dispose();
    _videoController = null;
    _audioPlayer = null;
    _error = null;
    if (widget.media.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.mediaUrl),
      )
        ..addListener(_updateVideoState)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((Object error) {
          if (mounted) setState(() => _error = error);
        });
    } else if (widget.media.mediaType == 'audio') {
      _audioPlayer = AudioPlayer();
    }
  }

  void _updateVideoState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _mediaActions(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(height: AppSpacing.xs),
              const Text('Could not load media'),
              TextButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (widget.media.mediaType == 'document') {
      final fileName =
          Uri.tryParse(widget.media.mediaUrl)?.pathSegments.lastOrNull ??
              'Listing document';
      return _mediaActions(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 44,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  Uri.decodeComponent(fileName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton.icon(
                onPressed: _openMedia,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open document'),
              ),
            ],
          ),
        ),
      );
    }
    if (widget.media.mediaType == 'video') {
      final controller = _videoController!;
      if (!controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return _mediaActions(
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  IconButton.filled(
                    tooltip: controller.value.isPlaying
                        ? 'Pause video'
                        : 'Play video',
                    onPressed: () async {
                      try {
                        if (controller.value.isPlaying) {
                          await controller.pause();
                        } else {
                          await controller.play();
                        }
                      } catch (error) {
                        if (mounted) setState(() => _error = error);
                      }
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (widget.media.mediaType == 'audio') {
      final player = _audioPlayer!;
      return _mediaActions(
        ColoredBox(
          color: AppColors.primary.withValues(alpha: 0.08),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: AppSpacing.sm),
                const Text('Seller voice note'),
                IconButton.filled(
                  tooltip:
                      player.playing ? 'Pause audio note' : 'Play audio note',
                  onPressed: () async {
                    try {
                      if (player.playing) {
                        await player.pause();
                      } else {
                        await player.setUrl(widget.media.mediaUrl);
                        await player.play();
                      }
                    } catch (error) {
                      if (mounted) setState(() => _error = error);
                    }
                    if (mounted) setState(() {});
                  },
                  icon: Icon(player.playing ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final Widget image = widget.media.mediaUrl.startsWith('assets/')
        ? AssetImageFallback(
            asset: widget.media.mediaUrl,
            fit: BoxFit.cover,
          )
        : CachedNetworkImage(
            imageUrl: widget.media.mediaUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => AssetImageFallback(
              asset: widget.fallbackAsset,
              fit: BoxFit.cover,
            ),
            errorWidget: (_, __, ___) => AssetImageFallback(
              asset: widget.fallbackAsset,
              fit: BoxFit.cover,
            ),
          );
    final preview = GestureDetector(
      onTap: () => _showImagePreview(context),
      child: image,
    );
    return _mediaActions(
      widget.heroTag == null
          ? preview
          : Hero(tag: widget.heroTag!, child: preview),
    );
  }

  Widget _mediaActions(Widget child) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (!widget.media.mediaUrl.startsWith('assets/'))
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Open or download media',
                  onPressed: _openMedia,
                  color: Colors.white,
                  icon: const Icon(Icons.download_outlined),
                ),
              ),
            ),
        ],
      );

  Future<void> _openMedia() async {
    try {
      final uri = Uri.parse(widget.media.mediaUrl);
      if (!uri.hasScheme ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No app could open this media.');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open media: $error')),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: widget.media.mediaUrl.startsWith('assets/')
                    ? AssetImageFallback(
                        asset: widget.media.mediaUrl,
                        fit: BoxFit.contain,
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.media.mediaUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    if (widget.media.mediaType == 'video') {
      final previous = _videoController;
      if (previous != null) {
        await previous.dispose();
      }
      if (!mounted) return;
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.mediaUrl),
      )
        ..addListener(_updateVideoState)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((Object error) {
          if (mounted) setState(() => _error = error);
        });
    } else if (widget.media.mediaType == 'audio') {
      final player = _audioPlayer!;
      try {
        await player.setUrl(widget.media.mediaUrl);
        await player.play();
      } catch (error) {
        if (mounted) setState(() => _error = error);
      }
    }
  }
}

Widget _primaryImage(
  String? imageUrl,
  String categoryId,
  String heroTag,
) {
  final fallback = AppAssets.listingImageForCategory(categoryId);
  final Widget image = imageUrl == null || imageUrl.isEmpty
      ? AssetImageFallback(asset: fallback, fit: BoxFit.cover)
      : imageUrl.startsWith('assets/')
          ? AssetImageFallback(asset: imageUrl, fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  AssetImageFallback(asset: fallback, fit: BoxFit.cover),
              errorWidget: (_, __, ___) =>
                  AssetImageFallback(asset: fallback, fit: BoxFit.cover),
            );
  return Hero(tag: heroTag, child: image);
}

class _CompactDetail extends StatelessWidget {
  const _CompactDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _SellerSaleStatusControl extends ConsumerWidget {
  const _SellerSaleStatusControl({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canChangeStatus = listing.editCount < 1;
    return Row(
      children: [
        const Icon(Icons.tune, size: 17),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue:
                listing.isFullySold ? 'fully_sold' : listing.saleStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sales availability',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'available',
                child: Text('Available'),
              ),
              DropdownMenuItem(
                value: 'partially_sold',
                child: Text('Partially sold'),
              ),
              DropdownMenuItem(
                value: 'fully_sold',
                child: Text('Fully sold'),
              ),
            ],
            onChanged: canChangeStatus
                ? (value) => _updateStatus(context, ref, value)
                : null,
          ),
        ),
        if (!canChangeStatus)
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs),
            child: Tooltip(
              message: 'This listing has used its one allowed edit.',
              child: Icon(Icons.lock_outline, size: 18),
            ),
          ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String? newStatus,
  ) async {
    if (newStatus == null || newStatus == listing.saleStatus) return;
    if (listing.editCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit a listing once.')),
      );
      return;
    }
    if (newStatus == 'fully_sold') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mark as fully sold?'),
          content: const Text(
            'This listing will no longer appear in public results. '
            'Changing its status uses your one allowed listing edit.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mark fully sold'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await ref.read(listingServiceProvider).updateListing(
        listing.id,
        {'sale_status': newStatus},
      );
      await ref.read(listingServiceProvider).clearCachedListings();
      ref
        ..invalidate(listingDetailProvider(listing.id))
        ..invalidate(listingFeedProvider)
        ..invalidate(categoryListingFeedProvider(listing.categoryId))
        ..invalidate(sellerCatalogListingsProvider(listing.userId))
        ..invalidate(profileListingsProvider(listing.userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing status updated.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update listing status: $error')),
        );
      }
    }
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Could not load listing photos: $error'));
  }
}

class _OfferDetails {
  const _OfferDetails({required this.price, this.quantity, this.note});

  final num price;
  final String? quantity;
  final String? note;
}

class _MakeOfferSheet extends StatefulWidget {
  const _MakeOfferSheet({required this.listing});

  final ListingModel listing;

  @override
  State<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<_MakeOfferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _OfferDetails(
        price: num.parse(_priceController.text.trim()),
        quantity: _quantityController.text.trim().isEmpty
            ? null
            : _quantityController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Make an offer',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Your price (UGX)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final price = num.tryParse(value?.trim() ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a price greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Message (optional)'),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submit,
                child: const Text('Send offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyNowSheet extends StatefulWidget {
  const _BuyNowSheet({
    required this.listing,
    required this.pricePerUnit,
  });

  final ListingModel listing;
  final num pricePerUnit;

  @override
  State<_BuyNowSheet> createState() => _BuyNowSheetState();
}

class _BuyNowSheetState extends State<_BuyNowSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final available = widget.listing.remainingQuantity;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buy now',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Price: UGX ${widget.pricePerUnit.toStringAsFixed(0)}'
                '${widget.listing.unit == null ? '' : ' per ${widget.listing.unit}'}',
              ),
              if (available != null) Text('Available: ${available.toString()}'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: widget.listing.unit,
                ),
                onChanged: (_) => setSheetState(() {}),
                validator: (value) {
                  final quantity = num.tryParse(value?.trim() ?? '');
                  if (quantity == null || quantity <= 0) {
                    return 'Enter a quantity greater than zero.';
                  }
                  if (available != null && quantity > available) {
                    return 'Quantity exceeds available stock.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Total: UGX ${((num.tryParse(_quantityController.text) ?? 0) * widget.pricePerUnit).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    num.parse(_quantityController.text.trim()),
                  );
                },
                child: const Text('Confirm order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
}
