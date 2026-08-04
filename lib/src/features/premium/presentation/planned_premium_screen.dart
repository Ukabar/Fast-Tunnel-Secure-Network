import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_components.dart';
import '../../settings/application/settings_providers.dart';

class PlannedPremiumScreen extends ConsumerWidget {
  const PlannedPremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notify = settings.when(
      data: (settings) => settings.notifyForPlannedPremium,
      error: (error, stackTrace) => false,
      loading: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Future Premium Features')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'These future Fast Tunnel features are not purchasable in v1.0. No subscriptions, billing, or prices are included.',
            ),
            const SizedBox(height: 16),
            for (final item in const [
              'Additional locations',
              'Automatic location selection',
              'Favorite location synchronization',
              'Custom connection profiles',
              'Priority location access',
            ])
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(item),
                  trailing: const PlannedFeatureBadge(),
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: notify,
              title: const Text('Notify me later'),
              subtitle: const Text(
                'Local preference only; no subscription is created.',
              ),
              onChanged: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setNotifyForPlannedPremium(value),
            ),
          ],
        ),
      ),
    );
  }
}
