import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/utils/ad_screen_ids.dart';
import '../../../core/ads/widgets/adaptive_banner_ad_widget.dart';
import '../../../core/widgets/app_components.dart';
import '../../history/application/history_providers.dart';
import '../../locations/application/locations_providers.dart';
import '../../tunnel/application/tunnel_providers.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final locations = ref.watch(plannedLocationsProvider);
    final tunnelState = ref
        .watch(tunnelStateProvider)
        .when(
          data: (state) => state,
          error: (error, stackTrace) =>
              ref.watch(tunnelServiceProvider).current,
          loading: () => ref.watch(tunnelServiceProvider).current,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: settings.when(
          data: (settings) {
            final selectedLocationId =
                locations.any(
                  (location) => location.id == settings.preferredLocationId,
                )
                ? settings.preferredLocationId!
                : locations.first.id;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionHeader(title: 'Appearance'),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(selection.first),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Preferred Location'),
                DropdownButtonFormField<String>(
                  initialValue: selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final location in locations)
                      DropdownMenuItem(
                        value: location.id,
                        child: Text(
                          '${location.flag} ${location.city}, ${location.country}',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setPreferredLocation(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Connection'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Connection animation'),
                  subtitle: const Text('Animate the main session button'),
                  value: settings.connectionAnimationEnabled,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setConnectionAnimationEnabled(value),
                ),
                Text(tunnelState.message),
                const Divider(height: 28),
                const SectionHeader(title: 'Advertising'),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.campaign_outlined),
                  title: Text('Advertising'),
                  subtitle: Text('Ads help support continued development.'),
                ),
                if (kDebugMode)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Developer controls'),
                    subtitle: const Text(
                      'Failure simulation and delay controls',
                    ),
                    onTap: () => context.push('/debug/mock-tunnel'),
                  ),
                const Divider(height: 28),
                const SectionHeader(title: 'Local Data'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear session history'),
                  onTap: () async {
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: 'Clear session history?',
                      body: 'This removes locally stored session records.',
                      confirmLabel: 'Clear',
                    );
                    if (confirmed) {
                      await ref
                          .read(sessionHistoryControllerProvider.notifier)
                          .clear();
                    }
                  },
                ),
                const Divider(height: 28),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () => context.push('/about'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () => context.push('/privacy'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms of Use'),
                  onTap: () => context.push('/terms'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Future Features'),
                  onTap: () => context.push('/premium'),
                ),
                const SizedBox(height: 12),
                const Text('App version 1.0.0+1'),
                const SizedBox(height: 12),
                const AdaptiveBannerAdWidget(screenId: AdScreenIds.settings),
              ],
            );
          },
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.all(16),
            child: AppErrorState(
              title: 'Settings unavailable',
              body: 'Settings could not be loaded from local storage.',
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(lines: 8),
          ),
        ),
      ),
    );
  }
}
