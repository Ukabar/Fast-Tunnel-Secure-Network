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
            Text(
              isPrivacy ? _privacyPolicy : _termsOfUse,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

enum LegalPageKind { privacy, terms }

const _privacyPolicy = '''
Fast Tunnel v1.0 is a private connection interface build.

Current version does not provide an active VPN.

Current version does not tunnel traffic.

Current version does not encrypt traffic.

Version 1.0 does not route internet traffic and does not inspect browsing content.

The app may look up your current public IP to display it as informational status.

Session history, selected location, favorites, and settings are stored locally on your device.

Google Mobile Ads may be used when advertising is enabled. Google may process device and advertising-related data to load, measure, and serve ads.

Ad personalization depends on user consent, Google settings, and regional legal requirements.

This placeholder policy requires legal review before publication.
''';

const _termsOfUse = '''
Fast Tunnel v1.0 provides a simulated connection interface for private testing.

The app does not guarantee availability, privacy, anonymity, encryption, or traffic routing.

Future native connection functionality is planned but is not included in version 1.0.
''';
