import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/connectivity_provider.dart';
import 'router.dart';
import 'theme.dart';
import 'widgets/common/common_widgets.dart';
import 'widgets/responsive_layout.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Buy From Lango',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      builder: (context, child) => _ConnectivityAwareApp(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _ConnectivityAwareApp extends ConsumerWidget {
  const _ConnectivityAwareApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (connectivity.valueOrNull == false)
          const SafeArea(
            bottom: false,
            child: OfflineBanner(),
          ),
        Expanded(child: ResponsiveAppFrame(child: child)),
      ],
    );
  }
}
