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
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
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
        ],
      ),
      body: SafeArea(
        child: history.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.history_outlined,
                  title: 'No sessions yet',
                  body:
                      'Completed, failed, and cancelled sessions appear here.',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const AdaptiveBannerAdWidget(
                    screenId: AdScreenIds.history,
                  );
                }
                final item = items[index];
                return _SessionHistoryTile(
                  item: item,
                  onOpen: () => context.push('/history/${item.id}'),
                  onDelete: () => ref
                      .read(sessionHistoryControllerProvider.notifier)
                      .delete(item.id),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: items.length + 1,
            );
          },
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.all(16),
            child: AppErrorState(
              title: 'Storage unavailable',
              body: 'Session history could not be loaded from local storage.',
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
      appBar: AppBar(title: const Text('Session Record')),
      body: SafeArea(
        child: item == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.history_outlined,
                  title: 'Session not found',
                  body: 'This session record is no longer stored locally.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RecordFact(label: 'Status', value: item.stateLabel),
                  _RecordFact(label: 'Location', value: item.location),
                  _RecordFact(
                    label: 'Started',
                    value: formatTimestamp(item.startedAt),
                  ),
                  _RecordFact(
                    label: 'Ended',
                    value: formatTimestamp(item.endedAt),
                  ),
                  _RecordFact(
                    label: 'Duration',
                    value: formatSessionDuration(item.duration),
                  ),
                  if (item.sessionIdentifier != null)
                    _RecordFact(
                      label: 'Session ID',
                      value: item.sessionIdentifier!,
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(sessionHistoryControllerProvider.notifier)
                          .delete(item.id);
                      if (context.mounted) context.pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete record'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final SessionHistoryEntry item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const CircleAvatar(child: Icon(Icons.power_settings_new)),
        title: Text(
          item.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.stateLabel} • ${formatTimestamp(item.startedAt)} • ${formatSessionDuration(item.duration)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'Delete session',
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
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
