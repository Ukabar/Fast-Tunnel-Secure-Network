import 'dart:io';

import 'package:fast_tunnel_network_test/src/app/fast_tunnel_app.dart';
import 'package:fast_tunnel_network_test/src/core/ads/controllers/ads_controller.dart';
import 'package:fast_tunnel_network_test/src/core/ads/controllers/interstitial_controller.dart';
import 'package:fast_tunnel_network_test/src/core/ads/providers/ad_providers.dart';
import 'package:fast_tunnel_network_test/src/core/ads/widgets/adaptive_banner_ad_widget.dart';
import 'package:fast_tunnel_network_test/src/features/legal/presentation/about_screen.dart';
import 'package:fast_tunnel_network_test/src/features/legal/presentation/legal_screen.dart';
import 'package:fast_tunnel_network_test/src/features/network_test/application/network_test_providers.dart';
import 'package:fast_tunnel_network_test/src/features/network_test/data/network_test_service.dart';
import 'package:fast_tunnel_network_test/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings_onboarding_completed': true,
    });
  });

  testWidgets('home shows network test dashboard', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Fast Tunnel'), findsWidgets);
    expect(find.text('Internet Test'), findsOneWidget);
    expect(find.text('Network Test'), findsOneWidget);
    expect(find.text('Start Test'), findsOneWidget);
    expect(find.text('Current Public IP'), findsOneWidget);
  });

  testWidgets('bottom navigation contains current destinations only', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Home'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Locations'), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('start test flow completes with real metric labels', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Start Test'));
    await tester.pump();
    expect(find.text('Cancel Test'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Network Score'), 300);

    expect(find.text('Test Again'), findsOneWidget);
    expect(find.text('Network Score'), findsOneWidget);
    expect(find.text('Average Latency'), findsOneWidget);
    expect(find.text('Jitter'), findsOneWidget);
    expect(find.text('Failure Rate'), findsOneWidget);
    expect(find.text('DNS'), findsOneWidget);
    expect(find.text('HTTPS'), findsOneWidget);
  });

  testWidgets('successful test completion requests one interstitial', (
    tester,
  ) async {
    final interstitial = _RecordingInterstitialController();
    await _pumpApp(tester, interstitial: interstitial);

    await tester.tap(find.text('Start Test'));
    await tester.pump();
    expect(interstitial.completedTestIds, isEmpty);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(interstitial.completedTestIds, hasLength(1));
    expect(interstitial.completedTestIds.single, startsWith('NT-'));
  });

  testWidgets('home does not present VPN or security claims', (tester) async {
    await _pumpApp(tester);

    for (final claim in [
      'VPN',
      'Secure Network',
      'encrypted connection',
      'hide your IP',
      'anonymous browsing',
      'private browsing',
    ]) {
      expect(find.textContaining(claim, findRichText: true), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel test does not save history', (tester) async {
    await _pumpApp(tester, client: _SlowDiagnosticsClient());

    await tester.tap(find.text('Start Test'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Cancel Test'));
    await tester.pumpAndSettle();

    expect(find.text('Test cancelled'), findsWidgets);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No tests yet'), findsOneWidget);
  });

  testWidgets('about screen describes network testing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pump();

    expect(find.text('Internet & Network Test'), findsOneWidget);
    expect(find.textContaining('on-demand diagnostic checks'), findsOneWidget);
    expect(find.textContaining('VPN'), findsNothing);
    expect(find.textContaining('Secure Network'), findsNothing);
  });

  testWidgets('legal pages describe the current diagnostic functionality', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(kind: LegalPageKind.privacy)),
    );
    await tester.pump();

    expect(find.textContaining('on-demand diagnostics'), findsOneWidget);
    expect(find.textContaining('Google Mobile Ads'), findsOneWidget);
    expect(find.textContaining('read-only lookup'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(kind: LegalPageKind.terms)),
    );
    await tester.pump();

    expect(
      find.textContaining('user-triggered network diagnostics'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not alter device network settings'),
      findsOneWidget,
    );
  });

  testWidgets('production UI has no connection or security claims', (
    tester,
  ) async {
    await _pumpApp(tester);

    for (final claim in [
      'Connect',
      'Disconnect',
      'Tunnel Status',
      'Session Active',
      'VPN Active',
      'Protected',
      'Encrypted',
      'Anonymous',
      'Secure Connection',
      'Traffic Protected',
      'MockTunnelService',
    ]) {
      expect(find.textContaining(claim), findsNothing);
    }
  });

  testWidgets('narrow screen layout does not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('primary tabs remain usable on a small Android layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);
    expect(tester.takeException(), isNull, reason: 'Home overflowed');

    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    expect(find.text('Test History'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'History overflowed');

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings keeps the banner, history action, and About only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    final banner = find.byType(AdaptiveBannerAdWidget);
    final clearHistory = find.text('Clear test history');
    expect(banner, findsOneWidget);
    expect(clearHistory, findsOneWidget);
    expect(
      tester.getTopLeft(banner).dy,
      lessThan(tester.getTopLeft(clearHistory).dy),
    );

    final settingsList = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    await tester.drag(settingsList, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsNWidgets(2));
    expect(find.text('Methodology'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms of Use'), findsNothing);
    expect(find.text('Information'), findsNothing);
    expect(find.textContaining('1.0.0+2'), findsNothing);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  NetworkDiagnosticsClient? client,
  InterstitialController? interstitial,
}) async {
  final interstitialController =
      interstitial ?? _RecordingInterstitialController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adsControllerProvider.overrideWith(_DisabledAdsController.new),
        interstitialControllerProvider.overrideWith(
          () => interstitialController,
        ),
        networkTestServiceProvider.overrideWithValue(
          NetworkTestService(
            client: client ?? _FakeDiagnosticsClient(),
            timeout: const Duration(milliseconds: 300),
          ),
        ),
      ],
      child: const FastTunnelApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

class _DisabledAdsController extends AdsController {
  @override
  Future<AdsState> build() async => AdsState.disabled();
}

class _RecordingInterstitialController extends InterstitialController {
  final completedTestIds = <String>[];

  @override
  Future<InterstitialAdDebugState> build() async {
    return const InterstitialAdDebugState(
      completedSessionCounter: 0,
      dailyCount: 0,
      lastShownAt: null,
    );
  }

  @override
  Future<void> recordCompletedTest({required String testId}) async {
    completedTestIds.add(testId);
  }
}

class _FakeDiagnosticsClient implements NetworkDiagnosticsClient {
  @override
  Future<({String body, int statusCode})> get(
    Uri uri, {
    required Duration timeout,
  }) async {
    if (uri.host == 'api.ipify.org') {
      return (statusCode: 200, body: '{"ip":"203.0.113.10"}');
    }
    return (statusCode: 204, body: '');
  }

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    return [InternetAddress('93.184.216.34')];
  }
}

class _SlowDiagnosticsClient extends _FakeDiagnosticsClient {
  @override
  Future<({String body, int statusCode})> get(
    Uri uri, {
    required Duration timeout,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return super.get(uri, timeout: timeout);
  }
}
