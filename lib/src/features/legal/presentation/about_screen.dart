import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Tunnel v1.0'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tunnel interface build', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            'Fast Tunnel provides a focused interface for selecting a location and managing a connection session.',
          ),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.info_outline,
            title: 'Simulation mode',
            body:
                'Connection states are simulated and device traffic is not routed.',
          ),
          _InfoRow(
            icon: Icons.public_outlined,
            title: 'Location control',
            body:
                'Favorite and preferred locations are stored locally on this device.',
          ),
          _InfoRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Private local data',
            body:
                'Session records and app preferences remain local unless you export or back them up separately.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
