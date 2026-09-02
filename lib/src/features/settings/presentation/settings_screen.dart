import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/utils/ad_screen_ids.dart';
import '../../../core/ads/widgets/adaptive_banner_ad_widget.dart';
import '../../../core/ads/providers/ad_providers.dart';
import '../../../core/widgets/app_components.dart';
import '../../history/application/history_providers.dart';
import '../../network_test/domain/network_test_models.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final privacyOptionsRequired = ref
        .watch(adsControllerProvider)
        .maybeWhen(
          data: (ads) => ads.privacyOptionsRequired,
          orElse: () => false,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: settings.when(
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionHeader(title: 'Appearance'),
                _SettingsPanel(
                  child: _ThemeModeSelector(
                    selected: settings.themeMode,
                    onChanged: (value) => ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(value),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Network Test'),
                _SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<NetworkTestAccuracy>(
                        initialValue: settings.testAccuracy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Test accuracy',
                        ),
                        items: [
                          for (final accuracy in NetworkTestAccuracy.values)
                            DropdownMenuItem(
                              value: accuracy,
                              child: Text(
                                '${accuracy.label} (${accuracy.attempts})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .setTestAccuracy(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Latency uses lightweight HTTPS request timing. DNS, HTTPS reachability, request failures, jitter, and public IP are measured only when you start a test.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AdaptiveBannerAdWidget(screenId: AdScreenIds.settings),
                const SizedBox(height: 16),
                const SectionHeader(title: 'History'),
                _SettingsPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: const LeadingIcon(
                      icon: Icons.delete_sweep_outlined,
                    ),
                    title: const Text('Clear test history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final confirmed = await showConfirmationDialog(
                        context: context,
                        title: 'Clear test history?',
                        body:
                            'This removes locally stored network test results.',
                        confirmLabel: 'Clear',
                      );
                      if (confirmed) {
                        await ref
                            .read(sessionHistoryControllerProvider.notifier)
                            .clear();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (privacyOptionsRequired) ...[
                  const SectionHeader(title: 'Privacy'),
                  _SettingsPanel(
                    padding: EdgeInsets.zero,
                    child: _SettingsLink(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy choices',
                      onTap: () async {
                        try {
                          await ref
                              .read(adsPrivacyServiceProvider)
                              .showPrivacyOptions();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Privacy choices are temporarily unavailable.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const SectionHeader(title: 'About'),
                _SettingsPanel(
                  padding: EdgeInsets.zero,
                  child: _SettingsLink(
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () => context.push('/about'),
                  ),
                ),
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;
        return SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          style: ButtonStyle(
            visualDensity: compact ? VisualDensity.compact : null,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
            ),
          ),
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(compact ? 'Auto' : 'System'),
              icon: compact ? null : const Icon(Icons.brightness_auto_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: const Text('Light'),
              icon: compact ? null : const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: const Text('Dark'),
              icon: compact ? null : const Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.first),
        );
      },
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: LeadingIcon(icon: icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
