import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/providers/ad_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_components.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/session_history_entry.dart';
import '../../public_ip/application/public_ip_providers.dart';
import '../application/tunnel_providers.dart';
import '../domain/tunnel_service.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tunnelState = ref
        .watch(tunnelStateProvider)
        .when(
          data: (state) => state,
          error: (error, stackTrace) =>
              ref.watch(tunnelServiceProvider).current,
          loading: () => ref.watch(tunnelServiceProvider).current,
        );
    final publicIp = ref.watch(currentPublicIpProvider);
    final state = tunnelState;
    final session = state.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF123A5C), Color(0xFF07111F)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF36C5F0), Color(0xFF1266F1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF36C5F0,
                          ).withValues(alpha: 0.38),
                          blurRadius: 44,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_moon_outlined,
                      color: Colors.white,
                      size: 72,
                      semanticLabel: 'Session status shield',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.displayStatus,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (session == null)
                const EmptyState(
                  icon: Icons.power_off_outlined,
                  title: 'No active session',
                  body: 'Start a session from Home to view details.',
                )
              else ...[
                _SessionFact(
                  label: 'Elapsed time',
                  value: formatSessionDuration(
                    DateTime.now().difference(session.startedAt),
                  ),
                ),
                _SessionFact(
                  label: 'Selected location',
                  value: '${session.city}, ${session.country}',
                ),
                _SessionFact(label: 'Session ID', value: session.id),
                _SessionFact(
                  label: 'Current public IP',
                  value: publicIp.when(
                    data: (result) => result.ip ?? 'Unavailable',
                    error: (error, stackTrace) => 'Unavailable',
                    loading: () => 'Looking up...',
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: state.hasDemoSession
                    ? () => _endSession(state.session!)
                    : null,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('End Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _endSession(TunnelSession session) async {
    final endedAt = DateTime.now();
    await ref.read(tunnelServiceProvider).disconnect();
    await ref
        .read(sessionHistoryControllerProvider.notifier)
        .save(
          SessionHistoryEntry(
            id: '${endedAt.microsecondsSinceEpoch}-${session.locationId}',
            location: '${session.city}, ${session.country}',
            startedAt: session.startedAt,
            endedAt: endedAt,
            finalState: SessionFinalState.completed,
            sessionIdentifier: session.id,
          ),
        );
    unawaited(
      ref
          .read(interstitialControllerProvider.notifier)
          .recordCompletedSession(
            sessionId: session.id,
            tunnelActive: ref
                .read(tunnelServiceProvider)
                .current
                .hasDemoSession,
          ),
    );
  }
}

class _SessionFact extends StatelessWidget {
  const _SessionFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
