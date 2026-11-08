import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing.dart';
import '../../models/listing_detail_route_data.dart';
import '../../providers/listing_provider.dart';
import '../../theme.dart';
import '../product_avatar.dart';
import '../listing_time_ago.dart';

class JobServiceCard extends ConsumerWidget {
  const JobServiceCard({
    super.key,
    required this.listing,
  });

  final ListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(listingSellerProvider(listing.userId));
    final media = ref.watch(listingMediaProvider(listing.id)).valueOrNull;
    final imageUrl = primaryListingImageUrl(listing, media);
    final isJob = listing.categoryId == 'jobs';
    final accent = isJob ? AppColors.primaryDark : AppColors.accent;
    final workerCount = listing.workersNeeded;

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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Hero(
                  tag: listingHeroTag(listing.id),
                  child: ProductAvatar(
                    categoryId: listing.categoryId,
                    itemName: listing.title,
                    imageUrl: imageUrl,
                    assetName: imageUrl?.startsWith('assets/') == true
                        ? imageUrl
                        : null,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TypePill(
                          label: isJob ? 'JOB OPPORTUNITY' : 'FARM SERVICE',
                          color: accent,
                        ),
                        seller.when(
                          data: (profile) => _TypePill(
                            label: switch (profile?.accountType) {
                              'cooperative' => 'Co-op',
                              'individual' => 'Individual',
                              _ => 'Seller',
                            },
                            color: AppColors.textSecondary,
                            soft: true,
                          ),
                          loading: () => const _TypePill(
                            label: 'Seller',
                            color: AppColors.textSecondary,
                            soft: true,
                          ),
                          error: (error, stackTrace) => const _TypePill(
                            label: 'Seller details unavailable',
                            color: AppColors.textSecondary,
                            soft: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (listing.serviceType?.isNotEmpty == true &&
                        listing.serviceType != listing.title) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        listing.serviceType!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 17, color: accent),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${isJob ? 'Positions' : 'Workers needed'}: ${workerCount ?? 0}',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (listing.districtName?.isNotEmpty == true)
                          _MetaLabel(
                            icon: Icons.location_on_outlined,
                            label: listing.districtName!,
                          ),
                        ListingTimeAgo(
                          createdAt: listing.createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.color,
    this.soft = false,
  });

  final String label;
  final Color color;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color:
            soft ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
