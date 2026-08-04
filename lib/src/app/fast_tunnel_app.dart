import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/providers/ad_providers.dart';
import '../features/settings/application/settings_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FastTunnelApp extends ConsumerStatefulWidget {
  const FastTunnelApp({super.key});

  @override
  ConsumerState<FastTunnelApp> createState() => _FastTunnelAppState();
}

class _FastTunnelAppState extends ConsumerState<FastTunnelApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appOpenControllerProvider.notifier);
    if (state == AppLifecycleState.paused) {
      controller.onBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(controller.onResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'Fast Tunnel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.when(
        data: (settings) => settings.themeMode,
        error: (error, stackTrace) => ThemeMode.dark,
        loading: () => ThemeMode.dark,
      ),
      routerConfig: router,
    );
  }
}
