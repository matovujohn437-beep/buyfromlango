import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: AssetImageFallback(
                      asset: page.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55000000),
                            Color(0x08000000),
                            Color(0xD9000000),
                          ],
                          stops: [0, 0.34, 1],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.28),
                          ),
                          onPressed: () => context.go('/sign-in'),
                          child: const Text('Log in'),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            MediaQuery.sizeOf(context).height < 600
                                ? AppSpacing.sm
                                : AppSpacing.xl,
                            AppSpacing.xl,
                            MediaQuery.sizeOf(context).height < 600
                                ? AppSpacing.md
                                : AppSpacing.xxl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: (MediaQuery.sizeOf(context).height < 600
                                        ? Theme.of(context).textTheme.titleLarge
                                        : Theme.of(context)
                                            .textTheme
                                            .headlineSmall)
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height < 600
                                        ? AppSpacing.xs
                                        : AppSpacing.sm,
                              ),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: (MediaQuery.sizeOf(context).height < 600
                                        ? Theme.of(context).textTheme.bodyMedium
                                        : Theme.of(context).textTheme.bodyLarge)
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height < 600
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
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.chip),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height < 600
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
                              if (MediaQuery.sizeOf(context).height >= 440) ...[
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height < 600
                                          ? AppSpacing.xs
                                          : AppSpacing.sm,
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
