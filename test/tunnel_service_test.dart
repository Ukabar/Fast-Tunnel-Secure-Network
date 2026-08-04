import 'dart:async';

import 'package:fast_tunnel_network_test/src/features/locations/domain/planned_location.dart';
import 'package:fast_tunnel_network_test/src/features/tunnel/domain/tunnel_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mock tunnel service connects and disconnects without networking',
    () async {
      final service = MockTunnelService();
      await service.setDelays(
        prepareDelay: Duration.zero,
        connectDelay: Duration.zero,
        disconnectDelay: Duration.zero,
      );

      await service.connect(_location);

      expect(service.current.status, TunnelStatus.connected);
      expect(service.current.session?.id, startsWith('FT-'));

      await service.disconnect();

      expect(service.current.status, TunnelStatus.disconnected);
      expect(service.current.session, isNull);
    },
  );

  test('mock tunnel service supports cancellation', () async {
    final service = MockTunnelService();
    await service.setDelays(
      prepareDelay: const Duration(seconds: 2),
      connectDelay: Duration.zero,
      disconnectDelay: Duration.zero,
    );

    unawaited(service.connect(_location));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await service.cancel();

    expect(service.current.status, TunnelStatus.cancelled);
  });

  test(
    'mock tunnel service ignores duplicate connect attempts while busy',
    () async {
      final service = MockTunnelService();
      await service.setDelays(
        prepareDelay: const Duration(milliseconds: 100),
        connectDelay: Duration.zero,
        disconnectDelay: Duration.zero,
      );

      unawaited(service.connect(_location));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await service.connect(
        const PlannedLocation(
          id: 'gb-lon',
          country: 'United Kingdom',
          city: 'London',
          flag: 'GB',
          countryCode: 'GB',
          region: 'Europe',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 140));

      expect(service.current.session?.locationId, 'us-nyc');
    },
  );
}

const _location = PlannedLocation(
  id: 'us-nyc',
  country: 'United States',
  city: 'New York',
  flag: 'US',
  countryCode: 'US',
  region: 'North America',
);
