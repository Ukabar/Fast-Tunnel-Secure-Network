import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/ads/utils/ad_screen_ids.dart';
import '../../../core/ads/widgets/adaptive_banner_ad_widget.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_components.dart';
import '../../history/application/history_providers.dart';
import '../../history/presentation/history_screen.dart';
import '../../network_test/application/network_test_providers.dart';
import '../../network_test/domain/network_test_models.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/presentation/settings_screen.dart';

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
    Future<void>.delayed(const Duration(milliseconds: 550), () {
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
            children: const [HomeScreen(), HistoryScreen(), SettingsScreen()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(),
        child: Theme(
          data: AppTheme.dark(),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 88),
                  const SizedBox(height: 18),
                  Text(
                    'Fast Tunnel',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Internet & Network Test',
                    style: TextStyle(color: Color(0xFFB8D4E6)),
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(networkTestControllerProvider);
    final history = ref
        .watch(sessionHistoryControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final latest = history == null || history.isEmpty ? null : history.first;
    final state = progress.maybeWhen(
      data: (value) => value,
      orElse: () => const NetworkTestProgress.idle(),
    );
    final result = state.result;

    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
            children: [
              const _HomeHeader(),
              const SizedBox(height: 16),
              _CurrentIpCard(publicIp: result?.publicIp),
              const SizedBox(height: 16),
              const AdaptiveBannerAdWidget(screenId: AdScreenIds.home),
              const SizedBox(height: 16),
              _TestCard(progress: state),
              if (result != null) ...[
                const SizedBox(height: 16),
                _ResultSummary(result: result),
              ],
              if (result == null && latest != null) ...[
                const SizedBox(height: 16),
                _RecentResultShortcut(
                  title: latest.scoreLabel,
                  score: latest.score,
                  onOpen: () => context.push('/history/${latest.id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentIpCard extends StatelessWidget {
  const _CurrentIpCard({required this.publicIp});

  final String? publicIp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: const Icon(Icons.public_outlined, color: AppPalette.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Public IP',
                  style: TextStyle(color: Color(0xFFB8D4E6), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  publicIp ?? 'Run a test to check this value',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const BrandMark(size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fast Tunnel',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Internet Test',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB8D4E6),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          color: Colors.white,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _TestCard extends ConsumerWidget {
  const _TestCard({required this.progress});

  final NetworkTestProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final running = progress.isRunning;
    final completed = progress.phase == NetworkTestPhase.completed;
    final controller = ref.read(networkTestControllerProvider.notifier);
    final progressValue = progress.totalAttempts == 0
        ? null
        : progress.completedAttempts / progress.totalAttempts;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.testCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.blue.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Network Test',
              style: TextStyle(
                color: Color(0xFFB9E9F7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress.statusLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (progress.message != null) ...[
              const SizedBox(height: 6),
              Text(
                progress.message!,
                style: const TextStyle(color: Color(0xFFC4DBEA)),
              ),
            ],
            const SizedBox(height: 20),
            if (running)
              LinearProgressIndicator(
                value: progressValue,
                color: AppPalette.cyan,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            if (progress.totalAttempts > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${progress.completedAttempts}/${progress.totalAttempts} latency attempts',
                style: const TextStyle(color: Color(0xFFC4DBEA)),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                button: true,
                label: running ? 'Cancel Test' : 'Start network test',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: Ink(
                    width: 158,
                    height: 158,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.brand,
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.cyan.withValues(alpha: 0.34),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: running ? controller.cancel : controller.start,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            running ? Icons.close_rounded : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            running
                                ? 'Cancel Test'
                                : completed
                                ? 'Test Again'
                                : 'Start Test',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
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
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends ConsumerWidget {
  const _ResultSummary({required this.result});

  final NetworkTestResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Network Score',
                    value: '${result.score}',
                    detail: result.scoreLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Current Public IP',
                    value: result.publicIp ?? 'Unavailable',
                    detail: 'Measured value',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetricGrid(result: result),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(networkTestControllerProvider.notifier)
                        .start(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Run Again'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/history'),
                    icon: const Icon(Icons.history),
                    label: const Text('Test History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.result});

  final NetworkTestResult result;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Average Latency', _ms(result.latency.average)),
      ('Minimum Latency', _ms(result.latency.minimum)),
      ('Maximum Latency', _ms(result.latency.maximum)),
      ('Jitter', _ms(result.latency.jitter)),
      ('Failure Rate', '${(result.latency.failureRate * 100).round()}%'),
      ('DNS', result.dns.label),
      ('HTTPS', result.https.label),
      ('Test Time', formatTimestamp(result.completedAt)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricTile(
                  label: metric.$1,
                  value: metric.$2,
                  detail: 'Real test',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentResultShortcut extends StatelessWidget {
  const _RecentResultShortcut({
    required this.title,
    required this.score,
    required this.onOpen,
  });

  final String title;
  final int score;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const CircleAvatar(child: Icon(Icons.speed)),
        title: const Text('Recent Test'),
        subtitle: Text('$title | Network score $score'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _pageGradient() =>
    const BoxDecoration(color: AppPalette.navy, gradient: AppGradients.home);

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
        icon: Icons.speed_rounded,
        title: 'Fast Tunnel',
        body: 'Check your network quality in seconds.',
      ),
      _OnboardingPage(
        icon: Icons.query_stats_rounded,
        title: 'Real Network Metrics',
        body:
            'Measure latency, jitter, request failures, DNS, and HTTPS reachability.',
      ),
      _OnboardingPage(
        icon: Icons.history_rounded,
        title: 'Track Your Results',
        body: 'Review previous tests and compare your network performance.',
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: _pageGradient(),
        child: Theme(
          data: AppTheme.dark(),
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
        const BrandMark(size: 92),
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

String _ms(Duration? duration) {
  return duration == null ? 'Unavailable' : '${duration.inMilliseconds} ms';
}
