import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Tunnel'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 62),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simple Network Sessions',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fast Tunnel provides a simple interface for managing network sessions, diagnostic tests, and locations.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _InfoRow(
            icon: Icons.speed_outlined,
            title: 'Network diagnostics',
            body:
                'Results are calculated from HTTPS timing, DNS resolution, and reachability checks.',
          ),
          const _InfoRow(
            icon: Icons.public_outlined,
            title: 'Current public IP',
            body:
                'The app can retrieve your current public IP as an informational diagnostic value.',
          ),
          const _InfoRow(
            icon: Icons.storage_outlined,
            title: 'Local history',
            body:
                'Completed test results and app preferences are stored locally on this device.',
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeadingIcon(icon: icon),
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
        ),
      ),
    );
  }
}
