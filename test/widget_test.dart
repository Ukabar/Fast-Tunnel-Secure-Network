import 'package:fast_tunnel_network_test/src/app/fast_tunnel_app.dart';
import 'package:fast_tunnel_network_test/src/features/legal/presentation/about_screen.dart';
import 'package:fast_tunnel_network_test/src/features/locations/domain/planned_location.dart';
import 'package:fast_tunnel_network_test/src/features/public_ip/application/public_ip_providers.dart';
import 'package:fast_tunnel_network_test/src/features/public_ip/data/public_ip_service.dart';
import 'package:fast_tunnel_network_test/src/features/public_ip/domain/public_ip_result.dart';
import 'package:fast_tunnel_network_test/src/features/tunnel/application/tunnel_providers.dart';
import 'package:fast_tunnel_network_test/src/features/tunnel/domain/tunnel_service.dart';
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

  testWidgets('home screen is tunnel-only', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Fast Tunnel'), findsWidgets);
    expect(find.text('Tunnel Status'), findsOneWidget);
    expect(find.text('Not Connected'), findsOneWidget);
    expect(find.text('Current Public IP'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.textContaining('Diagnostics'), findsNothing);
    expect(find.textContaining('Network Test'), findsNothing);
  });

  testWidgets('bottom navigation contains four primary destinations', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Locations'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Diagnose'), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('connect, cancel, retry, and active labels work', (tester) async {
    final service = MockTunnelService();
    await service.setDelays(
      prepareDelay: const Duration(milliseconds: 500),
      connectDelay: const Duration(milliseconds: 500),
      disconnectDelay: Duration.zero,
    );
    await _pumpApp(tester, tunnelService: service);

    await tester.tap(find.text('Connect'));
    await _pumpFrame(tester, const Duration(milliseconds: 100));
    expect(find.text('Preparing…'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await service.cancel();
    await _pumpFrame(tester);
    expect(find.text('Connection Cancelled'), findsOneWidget);

    await tester.tap(find.text('Connect'));
    await _pumpFrame(tester, const Duration(milliseconds: 600));
    expect(find.text('Connecting…'), findsOneWidget);
    await _pumpFrame(tester, const Duration(milliseconds: 700));
    expect(find.text('Session Active'), findsWidgets);
    expect(find.text('Disconnect'), findsWidgets);
  });

  testWidgets('simulated failure and retry are visible', (tester) async {
    final service = MockTunnelService();
    await service.setDelays(
      prepareDelay: Duration.zero,
      connectDelay: Duration.zero,
      disconnectDelay: Duration.zero,
    );
    await service.setFailureSimulationEnabled(true);
    await _pumpApp(tester, tunnelService: service);

    await tester.tap(find.text('Connect'));
    await _pumpFrame(tester);
    expect(find.text('Connection Failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await service.setFailureSimulationEnabled(false);
    await service.retry(_location);
    await _pumpFrame(tester);
    expect(find.text('Session Active'), findsWidgets);
  });

  testWidgets('session timer appears while active', (tester) async {
    final service = MockTunnelService();
    await service.setDelays(
      prepareDelay: Duration.zero,
      connectDelay: Duration.zero,
      disconnectDelay: Duration.zero,
    );
    await _pumpApp(tester, tunnelService: service);

    await tester.tap(find.text('Connect'));
    await _pumpFrame(tester);
    expect(find.text('Elapsed time'), findsOneWidget);
  });

  testWidgets('locations are searchable and sorted alphabetically', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Locations').last);
    await _pumpFrame(tester);

    expect(find.text('⭐ Favorites'), findsOneWidget);
    expect(find.text('🌍 All Locations'), findsOneWidget);
    expect(find.text('Argentina'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Tokyo');
    await _pumpFrame(tester);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Tokyo'), findsWidgets);
    expect(find.text('Argentina'), findsNothing);
  });

  testWidgets('about screen contains simulation disclosure', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await _pumpFrame(tester);

    expect(find.text('Simulation mode'), findsOneWidget);
    expect(
      find.text(
        'Connection states are simulated and device traffic is not routed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('normal UI hides internal and unsupported claims', (
    tester,
  ) async {
    await _pumpApp(tester);

    for (final claim in [
      'Demo',
      'MockTunnelService',
      'Prototype',
      'Latency',
      'Jitter',
      'DNS',
      'HTTPS',
      'Failure rate',
      'Quality score',
      'Protected',
      'Encrypted',
      'Anonymous',
      'IP Hidden',
      'Secure Connection',
      'Traffic Protected',
      'VPN Active',
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
}

const _location = PlannedLocation(
  id: 'us-nyc',
  country: 'United States',
  city: 'New York',
  flag: 'US',
  countryCode: 'US',
  region: 'North America',
);

Future<void> _pumpApp(
  WidgetTester tester, {
  TunnelService? tunnelService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        publicIpServiceProvider.overrideWithValue(const _FakePublicIpService()),
        if (tunnelService != null)
          tunnelServiceProvider.overrideWithValue(tunnelService),
      ],
      child: const FastTunnelApp(),
    ),
  );
  await _pumpFrame(tester, const Duration(seconds: 1));
}

Future<void> _pumpFrame(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 400),
]) async {
  await tester.pump(duration);
}

class _FakePublicIpService implements PublicIpService {
  const _FakePublicIpService();

  @override
  Future<PublicIpResult> fetchPublicIp() async {
    return const PublicIpResult.available('203.0.113.10');
  }
}
