import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/app/router.dart';
import 'package:void_app/core/theme/app_theme.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';

class VoidApp extends ConsumerStatefulWidget {
  const VoidApp({super.key});

  @override
  ConsumerState<VoidApp> createState() => _VoidAppState();
}

class _VoidAppState extends ConsumerState<VoidApp> {
  @override
  void initState() {
    super.initState();
    // Trigger non-blocking local-first background metadata sync on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaSyncServiceProvider).syncAllMediaItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'VOID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: appRouter,
    );
  }
}
