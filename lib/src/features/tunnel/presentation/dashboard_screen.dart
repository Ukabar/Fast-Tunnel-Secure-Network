import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/providers/ad_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_components.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/session_history_entry.dart';
import '../../history/presentation/history_screen.dart';
import '../../locations/application/locations_providers.dart';
import '../../locations/domain/planned_location.dart';
import '../../locations/presentation/locations_screen.dart';
import '../../public_ip/application/public_ip_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/tunnel_providers.dart';
import '../domain/tunnel_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  var _showSplash = true;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    if (_showSplash) return const SplashScreen();

    return settings.when(
      data: (settings) {
        if (!settings.onboardingCompleted) return const OnboardingScreen();
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              LocationsScreen(),
              HistoryScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public),
                label: 'Locations',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => const HomeScreen(),
      loading: () => const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(theme),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TunnelLogo(size: 88),
                  const SizedBox(height: 18),
                  Text(
                    'Fast Tunnel',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicIp = ref.watch(currentPublicIpProvider);
    final tunnelState = ref
        .watch(tunnelStateProvider)
        .when(
          data: (state) => state,
          error: (error, stackTrace) =>
              ref.watch(tunnelServiceProvider).current,
          loading: () => ref.watch(tunnelServiceProvider).current,
        );
    final settings = ref
        .watch(settingsControllerProvider)
        .when(
          data: (settings) => settings,
          error: (error, stackTrace) => null,
          loading: () => null,
        );
    final selectedLocation = _selectedLocation(ref);

    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(Theme.of(context)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
            children: [
              _HomeHeader(location: selectedLocation),
              const SizedBox(height: 16),
              _ConnectionCard(
                location: selectedLocation,
                state: tunnelState,
                animate: settings?.connectionAnimationEnabled ?? true,
                elapsedLabel: tunnelState.session == null
                    ? null
                    : formatSessionDuration(
                        DateTime.now().difference(
                          tunnelState.session!.startedAt,
                        ),
                      ),
                publicIp: publicIp.when(
                  data: (result) => result.ip ?? 'Unavailable',
                  error: (error, stackTrace) => 'Unavailable',
                  loading: () => 'Loading...',
                ),
                onPrimary: () => _handlePrimary(tunnelState, selectedLocation),
                onRetry: () => _retry(selectedLocation),
                onOpenSession: () => context.push('/session'),
                onChangeLocation: () => context.push('/locations'),
                onSettings: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PlannedLocation _selectedLocation(WidgetRef ref) {
    final locations = ref.watch(plannedLocationsProvider);
    final settings = ref
        .watch(settingsControllerProvider)
        .when(
          data: (settings) => settings,
          error: (error, stackTrace) => null,
          loading: () => null,
        );
    return locations.firstWhere(
      (location) => location.id == settings?.preferredLocationId,
      orElse: () => locations.first,
    );
  }

  Future<void> _handlePrimary(
    TunnelState state,
    PlannedLocation location,
  ) async {
    final service = ref.read(tunnelServiceProvider);
    if (state.canCancel) {
      final now = DateTime.now();
      await service.cancel();
      await _saveHistory(
        location: location,
        startedAt: now,
        endedAt: now,
        finalState: SessionFinalState.cancelled,
      );
      return;
    }
    if (state.hasDemoSession) {
      final session = state.session!;
      await service.disconnect();
      await _saveHistory(
        location: location,
        startedAt: session.startedAt,
        endedAt: DateTime.now(),
        finalState: SessionFinalState.completed,
        sessionIdentifier: session.id,
      );
      return;
    }
    await service.connect(location);
    final next = service.current;
    if (next.hasDemoSession && mounted) {
      context.push('/session');
    } else if (next.status == TunnelStatus.failed) {
      final now = DateTime.now();
      await _saveHistory(
        location: location,
        startedAt: now,
        endedAt: now,
        finalState: SessionFinalState.failed,
      );
    }
  }

  Future<void> _retry(PlannedLocation location) async {
    await ref.read(tunnelServiceProvider).retry(location);
  }

  Future<void> _saveHistory({
    required PlannedLocation location,
    required DateTime startedAt,
    required DateTime endedAt,
    required SessionFinalState finalState,
    String? sessionIdentifier,
  }) async {
    await ref
        .read(sessionHistoryControllerProvider.notifier)
        .save(
          SessionHistoryEntry(
            id: '${endedAt.microsecondsSinceEpoch}-${location.id}',
            location: '${location.city}, ${location.country}',
            startedAt: startedAt,
            endedAt: endedAt,
            finalState: finalState,
            sessionIdentifier: sessionIdentifier,
          ),
        );
    if (finalState == SessionFinalState.completed &&
        sessionIdentifier != null) {
      unawaited(
        ref
            .read(interstitialControllerProvider.notifier)
            .recordCompletedSession(
              sessionId: sessionIdentifier,
              tunnelActive: ref
                  .read(tunnelServiceProvider)
                  .current
                  .hasDemoSession,
            ),
      );
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.location});

  final PlannedLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const _TunnelLogo(size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fast Tunnel',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${location.flag} ${location.city}, ${location.country}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({
    required this.location,
    required this.state,
    required this.animate,
    required this.elapsedLabel,
    required this.publicIp,
    required this.onPrimary,
    required this.onRetry,
    required this.onOpenSession,
    required this.onChangeLocation,
    required this.onSettings,
  });

  final PlannedLocation location;
  final TunnelState state;
  final bool animate;
  final String? elapsedLabel;
  final String publicIp;
  final VoidCallback onPrimary;
  final VoidCallback onRetry;
  final VoidCallback onOpenSession;
  final VoidCallback onChangeLocation;
  final VoidCallback onSettings;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final active = state.hasDemoSession;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8840CFFF), Color(0x552465F5), Color(0x3307111F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36C5F0).withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Selected Location'),
            Row(
              children: [
                Text(
                  widget.location.flag,
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.location.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.location.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Tunnel Status'),
            Text(
              state.displayStatus,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              active
                  ? 'Connected to ${widget.location.city}, ${widget.location.country}'
                  : state.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = widget.animate && (active || state.isBusy)
                      ? 1 + (_controller.value * 0.08)
                      : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Semantics(
                  button: true,
                  label: 'Connection button',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _primaryEnabled(state) ? widget.onPrimary : null,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 156,
                        minHeight: 156,
                        maxWidth: 184,
                        maxHeight: 184,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: active
                              ? const [Color(0xFF36C5F0), Color(0xFF4ADE80)]
                              : const [Color(0xFF36C5F0), Color(0xFF1266F1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF36C5F0,
                            ).withValues(alpha: 0.34),
                            blurRadius: 42,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active
                                ? Icons.power_settings_new
                                : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _primaryLabel(state),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (state.canCancel) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: widget.onPrimary,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ],
            if (state.status == TunnelStatus.failed) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
            const SizedBox(height: 24),
            _FactRow(label: 'Current Public IP', value: widget.publicIp),
            if (widget.elapsedLabel != null)
              _FactRow(label: 'Elapsed time', value: widget.elapsedLabel!),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (active)
                  _ShortcutButton(
                    icon: Icons.open_in_new,
                    label: 'Session Details',
                    onPressed: widget.onOpenSession,
                  ),
                _ShortcutButton(
                  icon: Icons.public_outlined,
                  label: 'Change Location',
                  onPressed: widget.onChangeLocation,
                ),
                _ShortcutButton(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onPressed: widget.onSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _primaryEnabled(TunnelState state) {
    return state.status != TunnelStatus.preparing &&
        state.status != TunnelStatus.connecting &&
        state.status != TunnelStatus.disconnecting;
  }

  String _primaryLabel(TunnelState state) {
    return switch (state.status) {
      TunnelStatus.preparing => 'Preparing…',
      TunnelStatus.connecting => 'Connecting…',
      TunnelStatus.disconnecting => 'Disconnecting…',
      TunnelStatus.connected => 'Disconnect',
      _ => 'Connect',
    };
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _TunnelLogo extends StatelessWidget {
  const _TunnelLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF36C5F0), Color(0xFF1266F1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36C5F0).withValues(alpha: 0.34),
            blurRadius: 28,
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, size: size * 0.52, color: Colors.white),
    );
  }
}

BoxDecoration _pageGradient(ThemeData theme) {
  return BoxDecoration(
    color: theme.colorScheme.surface,
    gradient: const RadialGradient(
      center: Alignment.topRight,
      radius: 1.25,
      colors: [Color(0xFF123A5C), Color(0xFF07111F)],
    ),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _OnboardingPage(
        icon: Icons.bolt_rounded,
        title: 'Fast Tunnel',
        body: 'Choose and manage your preferred connection location.',
      ),
      _OnboardingPage(
        icon: Icons.public_outlined,
        title: 'Global Locations',
        body: 'Browse locations and save your favorites.',
      ),
      _OnboardingPage(
        icon: Icons.power_settings_new,
        title: 'Simple Control',
        body: 'Start and end a session from one clear interface.',
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(Theme.of(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _complete,
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => _index = index),
                    children: pages,
                  ),
                ),
                Row(
                  children: [
                    Text('${_index + 1}/${pages.length}'),
                    const Spacer(),
                    FilledButton(
                      onPressed: _index == pages.length - 1
                          ? _complete
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            ),
                      child: Text(
                        _index == pages.length - 1 ? 'Start' : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _complete() async {
    await ref.read(settingsControllerProvider.notifier).completeOnboarding();
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _TunnelLogo(size: 92),
        const SizedBox(height: 28),
        Icon(icon, size: 42, color: theme.colorScheme.primary),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(body, textAlign: TextAlign.center),
      ],
    );
  }
}
