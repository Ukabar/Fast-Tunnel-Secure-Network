import 'package:flutter/material.dart';

// Developer note: this placeholder legal text must be reviewed by qualified
// counsel before publication in any app store or public distribution channel.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  final LegalPageKind kind;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = kind == LegalPageKind.privacy;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? 'Privacy Policy' : 'Terms of Use'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isPrivacy ? _privacyPolicy : _termsOfUse,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LegalPageKind { privacy, terms }

const _privacyPolicy = '''
Fast Tunnel v1.0 is a network and internet testing utility.

Current version does not provide VPN functionality.

The app does not establish a system-level VPN connection.

The app does not route device traffic through a VPN, proxy, or traffic tunnel.

Network tests are initiated by the user.

The app may contact lightweight diagnostic endpoints to measure latency, DNS resolution, HTTPS reachability, and request failure rate.

The app may look up your current public IP from a third-party endpoint to display it as an informational diagnostic value.

Completed test history and settings are stored locally on your device.

Google Mobile Ads may be used when advertising is enabled. Google may process device and advertising-related data to load, measure, and serve ads.

Ad personalization depends on user consent, Google settings, and regional legal requirements.

This placeholder policy requires legal review before publication.
''';

const _termsOfUse = '''
Fast Tunnel v1.0 provides user-triggered network diagnostics.

The app does not provide VPN functionality, anonymous browsing, traffic routing, or traffic protection.

Diagnostic results are estimates based on HTTPS timing, DNS checks, reachability checks, and public IP lookup availability at the time of the test.
''';
