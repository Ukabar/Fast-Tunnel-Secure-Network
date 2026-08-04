import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_components.dart';
import '../application/tunnel_providers.dart';

class MockTunnelDebugScreen extends ConsumerWidget {
  const MockTunnelDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(tunnelStateProvider)
        .when(
          data: (state) => state,
          error: (error, stackTrace) =>
              ref.watch(tunnelServiceProvider).current,
          loading: () => ref.watch(tunnelServiceProvider).current,
        );
    final service = ref.watch(tunnelServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connection Debug')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!kDebugMode)
              const AppErrorState(
                title: 'Debug unavailable',
                body: 'Connection controls are compiled for debug builds only.',
              )
            else ...[
              const Text(
                'These controls affect only the simulated connection flow. They do not modify networking, DNS, routing, or public IP.',
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable failure simulation'),
                subtitle: const Text('The next connect attempt will fail.'),
                value: state.failureSimulationEnabled,
                onChanged: service.setFailureSimulationEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Random failures'),
                subtitle: const Text('Adds a 25% mock failure chance.'),
                value: state.randomFailuresEnabled,
                onChanged: service.setRandomFailuresEnabled,
              ),
              const Divider(),
              _DelaySlider(
                title: 'Preparing delay',
                value: state.prepareDelay,
                onChanged: (duration) =>
                    service.setDelays(prepareDelay: duration),
              ),
              _DelaySlider(
                title: 'Connecting delay',
                value: state.connectDelay,
                onChanged: (duration) =>
                    service.setDelays(connectDelay: duration),
              ),
              _DelaySlider(
                title: 'Disconnecting delay',
                value: state.disconnectDelay,
                onChanged: (duration) =>
                    service.setDelays(disconnectDelay: duration),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: service.reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset mock state'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DelaySlider extends StatelessWidget {
  const _DelaySlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final seconds = value.inMilliseconds / 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${seconds.toStringAsFixed(1)}s'),
        Slider(
          value: seconds.clamp(0.0, 5.0),
          min: 0,
          max: 5,
          divisions: 10,
          onChanged: (value) =>
              onChanged(Duration(milliseconds: (value * 1000).round())),
        ),
      ],
    );
  }
}
