import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'supabase_config.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);

  runApp(const ProviderScope(child: App()));
}
