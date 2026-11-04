import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_assets.dart';
import '../../models/listing.dart';
import '../../models/listing_detail_route_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/listing_provider.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/listing_location_filters.dart';
import '../../widgets/listing_status_badge.dart';
import '../../widgets/listing_time_ago.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/post_metadata.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/responsive_layout.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _ListingView { cards, thumbnails, list, table }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  _ListingView _listingView = _ListingView.cards;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 500) {
      ref.read(listingFeedProvider.notifier).loadNextPage();
    }
    return false;
  }

  void _hideHeroSection() {
    ref.read(showHomeHeroSectionProvider.notifier).state = false;
  }

  void _syncHeroSectionWithFilters() {
    final feed = ref.read(listingFeedProvider);
    final hasFilters = feed.searchQuery.trim().isNotEmpty ||
        feed.categoryId != null ||
        feed.districtId != null ||
        feed.subcountyId != null ||
        feed.parishId != null;
    final shouldShowHero = !hasFilters;
    ref.read(showHomeHeroSectionProvider.notifier).state = shouldShowHero;
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(listingFeedProvider.notifier)
      ..setSearchQuery('')
      ..setCategory(null)
      ..setLocationFilters(
        clearDistrict: true,
        clearSubcounty: true,
        clearParish: true,
      );
    ref.read(showHomeHeroSectionProvider.notifier).state = true;
  }

  void _goHome() {
    _clearFilters();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(listingFeedProvider);
    final showHeroSection = ref.watch(showHomeHeroSectionProvider);
    final user = ref.watch(currentUserProvider);
    final selectedCategory = feed.categoryId;

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          IconButton(
            tooltip: 'Price Board',
            onPressed: () => context.push('/price-board'),
            icon: const Icon(Icons.trending_up),
          ),
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.push('/chats'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              _hideHeroSection();
              FocusScope.of(context).requestFocus(_searchFocusNode);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(listingFeedProvider.notifier).refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          onTap: _hideHeroSection,
                          onChanged: (value) {
                            ref
                                .read(listingFeedProvider.notifier)
                                .setSearchQuery(value);
                            _syncHeroSectionWithFilters();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search item name',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty &&
                                    showHeroSection
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                      ref
                                          .read(listingFeedProvider.notifier)
                                          .setSearchQuery('');
                                      _syncHeroSectionWithFilters();
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListingLocationFilters(
                        districtId: feed.districtId,
                        subcountyId: feed.subcountyId,
                        parishId: feed.parishId,
                        onDistrictChanged: (id) {
                          ref
                              .read(listingFeedProvider.notifier)
                              .setLocationFilters(
                                districtId: id,
                                clearDistrict: id == null,
                                clearSubcounty: true,
                                clearParish: true,
                              );
                          _syncHeroSectionWithFilters();
                        },
                        onSubcountyChanged: (id) {
                          ref
                              .read(listingFeedProvider.notifier)
                              .setLocationFilters(
                                subcountyId: id,
                                clearSubcounty: id == null,
                                clearParish: true,
                              );
                          _syncHeroSectionWithFilters();
                        },
                        onParishChanged: (id) {
                          ref
                              .read(listingFeedProvider.notifier)
                              .setLocationFilters(
                                parishId: id,
                                clearParish: id == null,
                              );
                          _syncHeroSectionWithFilters();
                        },
                      ),
                    ),
                    if (showHeroSection) ...[
                      const SliverToBoxAdapter(child: _BannerSection()),
                      SliverToBoxAdapter(
                        child: _CategorySection(
                          selectedCategory: selectedCategory,
                          onCategoryTap: (categoryId) {
                            ref
                                .read(listingFeedProvider.notifier)
                                .setCategory(categoryId);
                            _syncHeroSectionWithFilters();
                          },
                          onAllTap: () {
                            ref
                                .read(listingFeedProvider.notifier)
                                .setCategory(null);
                            _syncHeroSectionWithFilters();
                          },
                        ),
                      ),
                    ],
                    if (selectedCategory != null ||
                        feed.districtId != null ||
                        feed.subcountyId != null ||
                        feed.parishId != null ||
                        feed.searchQuery.trim().isNotEmpty)
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear filters'),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _ListingsHeading(
                        title: selectedCategory != null ||
                                feed.districtId != null ||
                                feed.subcountyId != null ||
                                feed.parishId != null ||
                                feed.searchQuery.trim().isNotEmpty
                            ? 'Filtered listings'
                            : 'Latest listings',
                        selectedView: _listingView,
                        onViewSelected: (view) {
                          setState(() => _listingView = view);
                        },
                      ),
                    ),
                    if (feed.isLoading && feed.listings.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (feed.error != null && feed.listings.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          message: 'Could not load listings: ${feed.error}',
                          onRetry: () => ref
                              .read(listingFeedProvider.notifier)
                              .loadNextPage(),
                        ),
                      )
                    else if (feed.filteredListings.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('No matching listings yet.')),
                      )
                    else
                      ..._listingSlivers(feed.filteredListings),
                    if (feed.listings.isNotEmpty) ...[
                      if (feed.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (feed.error != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: _ErrorState(
                              message:
                                  'Could not load more listings: ${feed.error}',
                              onRetry: () => ref
                                  .read(listingFeedProvider.notifier)
                                  .loadNextPage(),
                            ),
                          ),
                        ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],
                ),
              ),
            ),
          );
          return content;
        },
      ),
      bottomNavigationBar: MarketplaceNavigationBar(
        selectedIndex: 1,
        showCategoryShortcuts: showHeroSection,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              if (context.canPop()) {
                context.pop();
              } else {
                _goHome();
              }
            case 1:
              _goHome();
            case 2:
              context.go('/profile');
            case 3:
              context.go('/buyer-needs');
          }
        },
      ),
      floatingActionButton: user == null || feed.isShowingCachedData
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<bool>('/listing/new');
                if (created == true && mounted) {
                  await ref.read(listingFeedProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create post'),
            ),
    );
  }

  List<Widget> _listingSlivers(List<ListingModel> listings) {
    final width = MediaQuery.sizeOf(context).width;
    final cardColumns = width >= ResponsiveBreakpoints.wide
        ? 4
        : width >= ResponsiveBreakpoints.expanded
            ? 3
            : 2;
    final thumbnailColumns = width >= ResponsiveBreakpoints.wide
        ? 5
        : width >= ResponsiveBreakpoints.expanded
            ? 4
            : 3;
    switch (_listingView) {
      case _ListingView.cards:
        final firstRowCount =
            listings.length < cardColumns ? listings.length : cardColumns;
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              itemCount: firstRowCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cardColumns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 156,
              ),
              itemBuilder: (context, index) =>
                  _ListingCard(listing: listings[index]),
            ),
          ),
          if (listings.length > firstRowCount)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                itemCount: listings.length - firstRowCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cardColumns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 156,
                ),
                itemBuilder: (context, index) => _ListingCard(
                  listing: listings[index + firstRowCount],
                ),
              ),
            ),
        ];
      case _ListingView.thumbnails:
        final firstRowCount = listings.length < thumbnailColumns
            ? listings.length
            : thumbnailColumns;
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              itemCount: firstRowCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: thumbnailColumns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 120,
              ),
              itemBuilder: (context, index) =>
                  _ListingThumbnail(listing: listings[index]),
            ),
          ),
          if (listings.length > firstRowCount)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                itemCount: listings.length - firstRowCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: thumbnailColumns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 120,
                ),
                itemBuilder: (context, index) => _ListingThumbnail(
                  listing: listings[index + firstRowCount],
                ),
              ),
            ),
        ];
      case _ListingView.list:
        final firstBatchCount = listings.length < 2 ? listings.length : 2;
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: firstBatchCount,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ListingListTile(listing: listings[index]),
              ),
            ),
          ),
          if (listings.length > firstBatchCount)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: listings.length - firstBatchCount,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListingListTile(
                    listing: listings[index + firstBatchCount],
                  ),
                ),
              ),
            ),
        ];
      case _ListingView.table:
        return [
          SliverToBoxAdapter(
            child: _ListingTable(listings: listings),
          ),
        ];
    }
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection();

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  static const _slides = [
    (
      image: AppAssets.listingCrop,
      eyebrow: 'FRESH FROM THE FARM',
      title: 'Bring home the harvest.',
      subtitle: 'Find fresh produce from farmers in your community.',
    ),
    (
      image: AppAssets.listingLivestock,
      eyebrow: 'LIVESTOCK & MORE',
      title: 'Find your next healthy stock.',
      subtitle: 'Explore livestock listings from local sellers.',
    ),
    (
      image: AppAssets.listingService,
      eyebrow: 'FARM SERVICES',
      title: 'Get the right help for your farm.',
      subtitle: 'Find vets, transport, ploughing and irrigation.',
    ),
    (
      image: AppAssets.listingCrop,
      eyebrow: 'FARM SUPPLIES',
      title: 'Everything for a productive season.',
      subtitle: 'Browse trusted drugs, fertilizers and farm inputs.',
    ),
    (
      image: AppAssets.listingService,
      eyebrow: 'EQUIPMENT & MACHINERY',
      title: 'Tools to get more done.',
      subtitle: 'Find hoes, tractors, mills and farm machinery.',
    ),
  ];

  late final PageController _pageController;
  late final Timer _autoPlayTimer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_activeIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: PageView.builder(
                  clipBehavior: Clip.hardEdge,
                  physics: const ClampingScrollPhysics(),
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _activeIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetImageFallback(
                          asset: slide.image,
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x14000000),
                                Color(0x74000000),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 16,
                                sigmaY: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  13,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.32),
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      slide.eyebrow,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            letterSpacing: 1.3,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      slide.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      slide.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            height: 1.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < _slides.length; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: index == _activeIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _activeIndex
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.onAllTap,
  });

  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onAllTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      loading: () => const SizedBox(height: 48),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text('Could not load categories: $error'),
      ),
      data: (items) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            _CategoryBadge(
              label: 'All',
              selected: selectedCategory == null,
              onTap: onAllTap,
            ),
            for (final category in items)
              _CategoryBadge(
                label: category.labelEn,
                iconPath: AppAssets.categoryIconForName(category.iconName),
                selected: selectedCategory == category.id,
                onTap: () => onCategoryTap(category.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconPath,
  });

  final String label;
  final String? iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      avatar: iconPath == null
          ? null
          : SvgPicture.asset(
              iconPath!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                selected ? AppColors.primary : AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
    );
  }
}

class _ListingsHeading extends StatelessWidget {
  const _ListingsHeading({
    required this.title,
    required this.selectedView,
    required this.onViewSelected,
  });

  final String title;
  final _ListingView selectedView;
  final ValueChanged<_ListingView> onViewSelected;

  @override
  Widget build(BuildContext context) {
    const viewOptions = [
      (_ListingView.cards, Icons.grid_view_rounded, 'Cards'),
      (_ListingView.thumbnails, Icons.apps_rounded, 'Thumbnails'),
      (_ListingView.list, Icons.view_list_rounded, 'List'),
      (_ListingView.table, Icons.table_rows_rounded, 'Table'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final (view, icon, label) in viewOptions)
            IconButton(
              tooltip: label,
              visualDensity: VisualDensity.compact,
              onPressed: () => onViewSelected(view),
              style: IconButton.styleFrom(
                backgroundColor: selectedView == view
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                foregroundColor: selectedView == view
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              icon: Icon(icon, size: 20),
            ),
        ],
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _primaryListingImage(
      listing,
      ref.watch(listingMediaProvider(listing.id)).valueOrNull,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openListing(context, listing, imageUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(
              listing: listing,
              width: double.infinity,
              height: 64,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: _ListingText(listing: listing, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingThumbnail extends ConsumerWidget {
  const _ListingThumbnail({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _primaryListingImage(
      listing,
      ref.watch(listingMediaProvider(listing.id)).valueOrNull,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openListing(context, listing, imageUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ListingImage(
                listing: listing,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: _ListingText(listing: listing, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingListTile extends ConsumerWidget {
  const _ListingListTile({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _primaryListingImage(
      listing,
      ref.watch(listingMediaProvider(listing.id)).valueOrNull,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openListing(context, listing, imageUrl),
        child: SizedBox(
          height: 144,
          child: Row(
            children: [
              _ListingImage(listing: listing, width: 84, height: 76),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _ListingText(listing: listing),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingText extends StatelessWidget {
  const _ListingText({required this.listing, this.compact = false});

  final ListingModel listing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          listing.title,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: compact
              ? Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
              : Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          listing.priceUgx == null
              ? 'Price negotiable'
              : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : null,
              ),
        ),
        if (!compact &&
            (listing.quantity?.isNotEmpty == true ||
                listing.unit?.isNotEmpty == true))
          Text(
            [listing.quantity, listing.unit]
                .whereType<String>()
                .where((value) => value.isNotEmpty)
                .join(' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              ListingStatusBadge(
                saleStatus: listing.saleStatus,
                compact: true,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ListingTimeAgo(
                  createdAt: listing.createdAt,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          PostMetadata(
          location: listing.districtName,
          createdVia: listing.createdVia,
        ),
      ],
    );
  }
}

class _ListingImage extends ConsumerWidget {
  const _ListingImage({
    required this.listing,
    this.width,
    this.height,
  });

  final ListingModel listing;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(listingMediaProvider(listing.id));
    return SizedBox(
      width: width,
      height: height,
      child: media.when(
        loading: () => _hero(
          _avatar(imageUrl: listing.imageUrl),
        ),
        error: (_, __) => _hero(
          _avatar(imageUrl: listing.imageUrl),
        ),
        data: (mediaItems) {
          final imageUrl = listing.imageUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return _hero(
              _avatar(
                imageUrl:
                    imageUrl.startsWith('assets/') ? null : imageUrl,
                assetName: imageUrl.startsWith('assets/') ? imageUrl : null,
              ),
            );
          }
          final image = mediaItems
              .where((item) => item.mediaType == 'image')
              .firstOrNull;
          if (image == null) {
            return _hero(_avatar(imageUrl: listing.imageUrl));
          }
          if (image.mediaUrl.startsWith('assets/')) {
            return _hero(
              _avatar(assetName: image.mediaUrl),
            );
          }
          return _hero(_avatar(imageUrl: image.mediaUrl));
        },
      ),
    );
  }

  Widget _hero(Widget child) => Hero(
        tag: listingHeroTag(listing.id),
        child: child,
      );

  Widget _avatar({String? imageUrl, String? assetName}) {
    final size = height == null ? 72.0 : height!.clamp(48.0, 96.0);
    return Center(
      child: ProductAvatar(
        categoryId: listing.categoryId,
        itemName: listing.title,
        imageUrl: imageUrl,
        assetName: assetName,
        size: size,
      ),
    );
  }
}

String? _primaryListingImage(
  ListingModel listing,
  List<ListingMediaModel>? media,
) {
  final imageUrl = listing.imageUrl?.trim();
  if (imageUrl?.isNotEmpty == true) return imageUrl;
  return media
      ?.where((item) => item.mediaType == 'image')
      .map((item) => item.mediaUrl)
      .firstOrNull;
}

void _openListing(
  BuildContext context,
  ListingModel listing,
  String? primaryImageUrl,
) {
  context.push(
    '/listing/${listing.id}',
    extra: ListingDetailRouteData(
      primaryImageUrl: primaryImageUrl,
      heroTag: listingHeroTag(listing.id),
    ),
  );
}

class _ListingTable extends StatelessWidget {
  const _ListingTable({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 76,
        columns: const [
          DataColumn(label: Text('Listing')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('Price')),
        ],
        rows: [
          for (final listing in listings)
            DataRow(
              onSelectChanged: (_) => context.push('/listing/${listing.id}'),
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Row(
                      children: [
                        _ListingImage(
                          listing: listing,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              PostMetadata(
                                location: listing.districtName,
                                createdVia: listing.createdVia,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    [listing.quantity, listing.unit]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .isEmpty
                        ? '—'
                        : [listing.quantity, listing.unit]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' '),
                  ),
                ),
                DataCell(
                  Text(listing.priceUgx == null
                      ? 'Negotiable'
                      : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
