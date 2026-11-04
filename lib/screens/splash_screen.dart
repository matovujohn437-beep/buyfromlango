import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../providers/connectivity_provider.dart';
import '../theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_logo_badge.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStatusProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.splashBackground,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, logoConstraints) {
                        final diameter = math
                            .min(
                              logoConstraints.maxWidth * 0.78,
                              logoConstraints.maxHeight * 0.72,
                            )
                            .clamp(0.0, 390.0)
                            .toDouble();
                        return Center(
                          child: AppLogoBadge(
                            size: diameter,
                            plain: true,
                            circular: true,
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: ResponsiveContent(
                      maxWidth: 480,
                      padding: EdgeInsets.zero,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.lg),
                          ),
                          border: Border(
                            top: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          compact ? AppSpacing.sm : AppSpacing.lg,
                          AppSpacing.xl,
                          compact ? AppSpacing.xs : AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (connectivity.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                                child: LinearProgressIndicator(),
                              ),
                            Text(
                              'Empowering Rural Farmers',
                              textAlign: TextAlign.center,
                              style: (compact
                                      ? Theme.of(context).textTheme.titleMedium
                                      : Theme.of(context).textTheme.titleLarge)
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: compact ? AppSpacing.xs : AppSpacing.md,
                            ),
                            FilledButton(
                              onPressed: () => context.push('/onboarding'),
                              child: const Text('Get Started'),
                            ),
                            SizedBox(height: compact ? 0 : AppSpacing.xs),
                            TextButton(
                              onPressed: () => context.go('/home'),
                              child: const Text('Browse marketplace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
