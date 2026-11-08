import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/product_avatar.dart';
import '../../widgets/post_metadata.dart';
import '../../constants/product_catalog.dart';
import '../../models/market_price.dart';
import '../../providers/location_provider.dart';
import '../../providers/market_price_provider.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';

class PriceBoardScreen extends ConsumerStatefulWidget {
  const PriceBoardScreen({super.key});

  @override
  ConsumerState<PriceBoardScreen> createState() => _PriceBoardScreenState();
}

class _PriceBoardScreenState extends ConsumerState<PriceBoardScreen> {
  int? _districtId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(districtsProvider);
    final prices = ref.watch(marketPricesProvider(_districtId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Price Board'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search crops',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() => _searchQuery = ''),
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: DropdownButtonFormField<int>(
                initialValue: _districtId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'District',
                  errorText: districts.hasError
                      ? 'Could not load district options.'
                      : null,
                  suffixIcon: districts.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All districts'),
                  ),
                  ...?districts.valueOrNull?.map(
                    (district) => DropdownMenuItem<int>(
                      value: district.id,
                      child: Text(district.name),
                    ),
                  ),
                ],
                selectedItemBuilder: (context) => [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('All districts'),
                  ),
                  ...?districts.valueOrNull?.map(
                    (district) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(district.name),
                    ),
                  ),
                ],
                onChanged: districts.hasError
                    ? null
                    : (districtId) => setState(() => _districtId = districtId),
              ),
            ),
            Expanded(
              child: prices.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'We could not load market prices. Check your connection '
                        'and try again.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(marketPricesProvider(_districtId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) => _MarketPriceList(
                  prices: items
                      .where(
                        (price) => price.itemName
                            .toLowerCase()
                            .contains(_searchQuery.trim().toLowerCase()),
                      )
                      .toList(),
                  searchQuery: _searchQuery,
                  onRefresh: () => ref.refresh(
                    marketPricesProvider(_districtId).future,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketPriceList extends StatelessWidget {
  const _MarketPriceList({
    required this.prices,
    required this.searchQuery,
    required this.onRefresh,
  });

  final List<MarketPriceModel> prices;
  final String searchQuery;
  final Future<List<MarketPriceModel>> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: prices.isEmpty ? 1 : prices.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (prices.isEmpty) {
            return SizedBox(
              height: 240,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    searchQuery.trim().isEmpty
                        ? 'No market prices are available for this district yet.'
                        : 'No crops match "${searchQuery.trim()}".',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final price = prices[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ProductAvatar(
                        categoryId: productCategoryForItem(price.itemName),
                        size: 48,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price.itemName,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            PostMetadata(
                              location: price.districtName,
                              showOrigin: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _MarketPriceHighlight(
                        price: price.marketPriceUgx,
                        changePercent: price.priceChangePercent,
                        trend: price.trend,
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg * 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PriceColumn(
                          label: 'Farm Gate',
                          value: price.farmGatePriceUgx,
                        ),
                      ),
                      Expanded(
                        child: _PriceColumn(
                          label: 'Wholesale',
                          value: price.wholesalePriceUgx,
                        ),
                      ),
                      Expanded(
                        child: _PriceColumn(
                          label: 'Retail',
                          value: price.retailPriceUgx,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarketPriceHighlight extends StatelessWidget {
  const _MarketPriceHighlight({
    required this.price,
    required this.changePercent,
    required this.trend,
  });

  final num? price;
  final num changePercent;
  final MarketPriceTrend trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Market / kg',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            price == null ? 'N/A' : _formatUgx(price!),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: price == null
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (price != null) _PriceChange(value: changePercent, trend: trend),
        ],
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.value});

  final String label;
  final num? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value == null ? 'N/A' : _formatUgx(value!),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PriceChange extends StatelessWidget {
  const _PriceChange({required this.value, required this.trend});

  final num value;
  final MarketPriceTrend trend;

  @override
  Widget build(BuildContext context) {
    final isUp = trend == MarketPriceTrend.rising;
    final isDown = trend == MarketPriceTrend.falling;
    final color = isUp
        ? AppColors.success
        : isDown
            ? AppColors.terracotta
            : AppColors.textSecondary;
    final icon = isUp
        ? Icons.arrow_upward
        : isDown
            ? Icons.arrow_downward
            : Icons.remove;
    final label = switch (trend) {
      MarketPriceTrend.rising => 'Rising',
      MarketPriceTrend.falling => 'Falling',
      MarketPriceTrend.stable => 'Stable',
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label ${value.abs().toStringAsFixed(2)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _formatUgx(num value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return 'UGX $grouped';
}
