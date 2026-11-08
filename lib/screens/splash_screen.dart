import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.splashBackground, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x26000000),
                  Color(0xB3000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                key: const ValueKey('splash-branding'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.agriculture_outlined,
                    color: Colors.white,
                    size: 76,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Buy From Lango',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Market · Connect · Grow',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
