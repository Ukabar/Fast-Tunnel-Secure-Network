import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/utils/ad_screen_ids.dart';
import '../../../core/ads/widgets/adaptive_banner_ad_widget.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_components.dart';
import '../application/history_providers.dart';
import '../domain/session_history_entry.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Clear test history?',
                body: 'This removes locally stored network test results.',
                confirmLabel: 'Clear',
              );
              if (confirmed) {
                await ref
                    .read(sessionHistoryControllerProvider.notifier)
                    .clear();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: history.when(
          data: (items) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const AdaptiveBannerAdWidget(screenId: AdScreenIds.history),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.history_outlined,
                    title: 'No tests yet',
                    body: 'Completed network tests appear here.',
                  )
                else
                  for (final item in items) ...[
                    _TestHistoryTile(
                      item: item,
                      onOpen: () => context.push('/history/${item.id}'),
                      onDelete: () => ref
                          .read(sessionHistoryControllerProvider.notifier)
                          .delete(item.id),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          },
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.all(16),
            child: AppErrorState(
              title: 'Storage unavailable',
              body: 'Test history could not be loaded from local storage.',
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

class SessionHistoryDetailsScreen extends ConsumerWidget {
  const SessionHistoryDetailsScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryControllerProvider);
    final item = history.when(
      data: (items) {
        for (final entry in items) {
          if (entry.id == entryId) return entry;
        }
        return null;
      },
      error: (error, stackTrace) => null,
      loading: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Test Result')),
      body: SafeArea(
        child: item == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.history_outlined,
                  title: 'Result not found',
                  body: 'This test result is no longer stored locally.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ResultOverview(item: item),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Measured details'),
                  _RecordFact(
                    label: 'Average Latency',
                    value: _ms(item.averageLatencyMs),
                  ),
                  _RecordFact(
                    label: 'Minimum Latency',
                    value: _ms(item.minimumLatencyMs),
                  ),
                  _RecordFact(
                    label: 'Maximum Latency',
                    value: _ms(item.maximumLatencyMs),
                  ),
                  _RecordFact(label: 'Jitter', value: _ms(item.jitterMs)),
                  _RecordFact(
                    label: 'Request Failure Rate',
                    value: item.failureRateLabel,
                  ),
                  _RecordFact(
                    label: 'DNS',
                    value: item.dnsSucceeded
                        ? 'Resolved (${item.dnsAddressCount} addresses)'
                        : 'Unavailable',
                  ),
                  _RecordFact(label: 'HTTPS', value: item.httpsStatus),
                  _RecordFact(
                    label: 'Current Public IP',
                    value: item.publicIp ?? 'Unavailable',
                  ),
                  _RecordFact(
                    label: 'Test Endpoint',
                    value: '${item.endpointProvider} • ${item.endpointRegion}',
                  ),
                  _RecordFact(
                    label: 'Test Time',
                    value: formatTimestamp(item.completedAt),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Run Again'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(sessionHistoryControllerProvider.notifier)
                          .delete(item.id);
                      if (context.mounted) context.pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete result'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TestHistoryTile extends StatelessWidget {
  const _TestHistoryTile({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final SessionHistoryEntry item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        leading: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            item.score.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text('${item.scoreLabel} network quality'),
        subtitle: Text(
          '${formatTimestamp(item.completedAt)} | Avg ${_ms(item.averageLatencyMs)} | Jitter ${_ms(item.jitterMs)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'Delete result',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _RecordFact extends StatelessWidget {
  const _RecordFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(label),
          subtitle: Text(value),
        ),
      ),
    );
  }
}

class _ResultOverview extends StatelessWidget {
  const _ResultOverview({required this.item});

  final SessionHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1598BC), Color(0xFF1266F1)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
            ),
            child: Text(
              item.score.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NETWORK SCORE',
                  style: TextStyle(
                    color: Color(0xFFD4F5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.scoreLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  formatTimestamp(item.completedAt),
                  style: const TextStyle(color: Color(0xFFD4E6F4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _ms(int? value) => value == null ? 'Unavailable' : '$value ms';
