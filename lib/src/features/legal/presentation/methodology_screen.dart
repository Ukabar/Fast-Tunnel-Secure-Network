import 'package:flutter/material.dart';

import '../../../core/widgets/app_components.dart';

class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Methodology')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _MethodCard(
              icon: Icons.speed_outlined,
              title: 'Network Score',
              body:
                  'Fast Tunnel calculates the score from real diagnostic measurements: latency 45%, jitter 25%, request failure rate 20%, and DNS/HTTPS reachability 10%.',
            ),
            const SizedBox(height: 12),
            const _MethodCard(
              icon: Icons.query_stats_outlined,
              title: 'Latency and jitter',
              body:
                  'Latency is measured with repeated lightweight HTTPS requests. Jitter is the average variation between successful latency samples.',
            ),
            const SizedBox(height: 12),
            const _MethodCard(
              icon: Icons.language_outlined,
              title: 'Reachability',
              body:
                  'DNS resolution and HTTPS reachability are checked directly. The app does not route traffic, modify DNS, or change your public IP.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeadingIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
