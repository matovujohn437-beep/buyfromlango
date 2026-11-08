import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    (
      image: 'assets/illustrations/onboarding_0.png',
      title: 'Welcome to Buy From Lango',
      description: 'Connect directly with local farmers.',
    ),
    (
      image: 'assets/illustrations/onboarding_1.png',
      title: 'Sell Your Harvest',
      description: 'No brokers, no middlemen. Keep 100% of your profits.',
    ),
    (
      image: 'assets/illustrations/onboarding_2.png',
      title: 'Buy Fresh & Local',
      description: 'Browse listings from verified farmers in your district.',
    ),
    (
      image: 'assets/illustrations/onboarding_3.png',
      title: 'Works on Any Phone',
      description:
          "Smartphone or feature phone? We've got you covered with our SMS gateway.",
    ),
    (
      image: 'assets/illustrations/onboarding_4.png',
      title: 'Know the Real Prices',
      description:
          'Check daily market, farm gate, and retail prices before you trade.',
    ),
    (
      image: 'assets/illustrations/onboarding_5.png',
      title: 'Reveal Contacts Safely',
      description: "Request a seller's number securely via SMS.",
    ),
    (
      image: 'assets/illustrations/onboarding_6.png',
      title: 'Services & Jobs',
      description:
          'Find tractor operators, herders, and farm labor instantly.',
    ),
    (
      image: 'assets/illustrations/onboarding_7.png',
      title: 'Ready to Grow?',
      description:
          'Join thousands of farmers transforming agriculture in Northern Uganda.',
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
      context.go('/home');
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
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemBuilder: (context, index) {
          final page = _pages[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(page.image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x12000000),
                      Color(0x4D000000),
                      Color(0xB3000000),
                    ],
                    stops: [0, 0.38, 1],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 600;
                    final veryCompact = constraints.maxHeight < 380;
                    return Stack(
                      children: [
                        if (index < _pages.length - 1)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(veryCompact ? 4 : 12),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => context.go('/home'),
                                child: const Text('Skip'),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  veryCompact
                                      ? 12
                                      : compact
                                          ? 16
                                          : 24,
                                  veryCompact ? 0 : 8,
                                  veryCompact
                                      ? 12
                                      : compact
                                          ? 16
                                          : 24,
                                  veryCompact
                                      ? 0
                                      : compact
                                          ? 8
                                          : 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _GlassPanel(
                                      compact: compact,
                                      veryCompact: veryCompact,
                                      title: page.title,
                                      description: page.description,
                                    ),
                                    SizedBox(
                                      height: veryCompact
                                          ? 4
                                          : compact
                                              ? 14
                                              : 22,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _pages.length,
                                        (pageIndex) => AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOut,
                                          width: pageIndex == _currentPage
                                              ? 24
                                              : 7,
                                          height: 7,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pageIndex == _currentPage
                                                ? const Color(0xFFF5B800)
                                                : Colors.white.withValues(
                                                    alpha: 0.5,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: veryCompact
                                          ? 4
                                          : compact
                                              ? 14
                                              : 24,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        onPressed: _next,
                                        child: Text(
                                          _currentPage == _pages.length - 1
                                              ? 'Get Started'
                                              : 'Next',
                                        ),
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
            ],
          );
        },
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.compact,
    required this.veryCompact,
    required this.title,
    required this.description,
  });

  final bool compact;
  final bool veryCompact;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const ValueKey('onboarding-glass-panel'),
          width: double.infinity,
          padding: veryCompact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : EdgeInsets.all(compact ? 14 : 22),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            border: Border.all(
              color: const Color(0xA6F5B800),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: veryCompact ? 1.06 : 1.12,
                ),
              ),
              SizedBox(height: veryCompact ? 4 : 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
