import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/responsive_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    (
      image: AppAssets.onboarding1,
      title: 'Welcome to Buy From Lango',
      description:
          'Your marketplace for agricultural produce, services, jobs and more.',
    ),
    (
      image: AppAssets.onboarding2,
      title: 'Easy, secure and local',
      description:
          'Use SMS, mobile app or phone. Find what you need and connect with confidence.',
    ),
    (
      image: AppAssets.onboarding3,
      title: 'Grow together',
      description:
          'Reach local buyers, discover opportunities and grow your business.',
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      context.go('/sign-up');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final veryCompact = constraints.maxHeight < 360;
          final compact = constraints.maxHeight < 600;
          final imageHeight = veryCompact
              ? 68.0
              : (constraints.maxHeight *
                      (constraints.maxHeight < 600 ? 0.30 : 0.46))
                  .clamp(110.0, 420.0);
          return PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Column(
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: SizedBox.expand(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: AppColors.surfaceVariant),
                              AssetImageFallback(
                                asset: page.image,
                                fit: BoxFit.contain,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x55000000),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              SafeArea(
                                bottom: false,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            Colors.black.withValues(alpha: 0.4),
                                      ),
                                      onPressed: () => context.go('/sign-in'),
                                      child: const Text('Log in'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.surface,
                      child: ResponsiveContent(
                        maxWidth: 680,
                        padding: EdgeInsets.fromLTRB(
                          veryCompact ? AppSpacing.md : AppSpacing.xl,
                          veryCompact
                              ? 0
                              : compact
                                  ? AppSpacing.sm
                                  : AppSpacing.xl,
                          veryCompact ? AppSpacing.md : AppSpacing.xl,
                          veryCompact
                              ? 0
                              : compact
                                  ? 0
                                  : AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: (veryCompact
                                      ? Theme.of(context).textTheme.titleMedium
                                      : compact
                                          ? Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                          : Theme.of(context)
                                              .textTheme
                                              .headlineSmall)
                                  ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? 2
                                  : compact
                                      ? AppSpacing.xs
                                      : AppSpacing.sm,
                            ),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: (veryCompact
                                      ? Theme.of(context).textTheme.bodySmall
                                      : compact
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge)
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? AppSpacing.xs
                                  : compact
                                      ? AppSpacing.sm
                                      : AppSpacing.xl,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _pages.length,
                                (pageIndex) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: pageIndex == _currentPage ? 22 : 7,
                                  height: 7,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pageIndex == _currentPage
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(
                                            alpha: 0.25,
                                          ),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.chip),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? AppSpacing.xs
                                  : compact
                                      ? AppSpacing.sm
                                      : AppSpacing.xl,
                            ),
                            FilledButton(
                              onPressed: _next,
                              child: Text(
                                _currentPage == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                              ),
                            ),
                            if (constraints.maxHeight >= 440) ...[
                              SizedBox(
                                height: compact ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: () => context.go('/sign-in'),
                                child: const Text(
                                  'Already have an account? Log in',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
