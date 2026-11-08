import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/home_provider.dart';
import '../theme.dart';

class MarketplaceNavigationBar extends ConsumerWidget {
  const MarketplaceNavigationBar({
    super.key,
    this.selectedIndex = 1,
    this.activeCategoryId,
    this.onDestinationSelected,
    this.showCategoryShortcuts = true,
  });

  final int selectedIndex;
  final String? activeCategoryId;
  final ValueChanged<int>? onDestinationSelected;
  final bool showCategoryShortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCategoryShortcuts)
              SizedBox(
                height: 58,
                child: categories.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (items) => ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final category = items[index];
                      return _CategoryShortcut(
                        category: category,
                        isActive: category.id == activeCategoryId,
                        onTap: () => context.go(
                          '/category/${Uri.encodeComponent(category.id)}',
                        ),
                      );
                    },
                  ),
                ),
              ),
            SizedBox(
              height: 84,
              child: ColoredBox(
                color: AppColors.primary,
                child: Row(
                  children: [
                    _NavigationDestination(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      selected: selectedIndex == 0,
                      onTap: () => _selectDestination(context, ref, 0),
                    ),
                    _NavigationDestination(
                      icon:
                          selectedIndex == 1 ? Icons.home : Icons.home_outlined,
                      label: 'Home',
                      selected: selectedIndex == 1,
                      onTap: () => _selectDestination(context, ref, 1),
                    ),
                    _NavigationDestination(
                      icon: selectedIndex == 2
                          ? Icons.person
                          : Icons.person_outline,
                      label: 'Profile',
                      selected: selectedIndex == 2,
                      onTap: () => _selectDestination(context, ref, 2),
                    ),
                    _NavigationDestination(
                      icon: selectedIndex == 3
                          ? Icons.shopping_basket
                          : Icons.shopping_basket_outlined,
                      label: 'Buyer Demands',
                      selected: selectedIndex == 3,
                      onTap: () => _selectDestination(context, ref, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) {
    if (onDestinationSelected case final onSelect?) {
      onSelect(index);
      return;
    }
    switch (index) {
      case 0:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      case 1:
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      case 2:
        context.go('/profile');
      case 3:
        context.go('/buyer-needs');
    }
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.primary : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                selected ? AppColors.accent : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final Category category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? Colors.white : AppColors.primaryDark;
    return Center(
      child: Material(
        color: isActive ? AppColors.accent : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.categoryIconForName(category.iconName),
                  width: 19,
                  height: 19,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  placeholderBuilder: (_) => Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  category.labelEn,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
