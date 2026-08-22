import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';

class VpnComingSoonCard extends StatelessWidget {
  const VpnComingSoonCard({super.key});

  static const cardKey = Key('vpn-coming-soon-card');
  static const buttonKey = Key('vpn-coming-soon-button');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const LeadingIcon(icon: Icons.shield_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text('VPN', style: theme.textTheme.titleLarge)),
                const StatusBadge(
                  label: 'Coming Soon',
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Fast and private VPN connectivity is planned for a future update.',
            ),
            const SizedBox(height: 8),
            Text(
              'VPN is not available in this version.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: buttonKey,
              onPressed: null,
              icon: const Icon(Icons.schedule_outlined),
              label: const Text('Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}
