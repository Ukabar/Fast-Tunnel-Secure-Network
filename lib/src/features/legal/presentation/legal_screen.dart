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
Privacy Policy for Fast Tunnel

Last Updated: August 2026

Fast Tunnel provides a simple interface for managing network sessions, diagnostic tests, and locations. This Privacy Policy explains how information may be handled when you use the app.

Fast Tunnel is not currently a VPN service. It does not claim to encrypt, reroute, protect, mask, or anonymize your internet traffic.

Network Diagnostics

When you start a test, the app may contact lightweight HTTPS endpoints to measure latency, jitter, request failure rate, DNS resolution, and HTTPS reachability. These diagnostic requests are used to calculate the network score shown in the app.

Public IP Lookup

The app may request your current public IP address from a third-party endpoint, such as api.ipify.org, and display it as an informational diagnostic value. This lookup does not change, hide, or mask your IP address.

Local Data

Fast Tunnel may store completed test history, favorite locations, appearance settings, test accuracy settings, onboarding status, and advertising display counters locally on your device using local app storage.

Advertising

Fast Tunnel includes Google Mobile Ads. When advertising is enabled, Google and its advertising partners may process device, advertising, and interaction information according to their own privacy policies, consent requirements, and applicable law. Fast Tunnel also uses a remote advertising configuration to control ad placement and availability.

No Accounts

Fast Tunnel does not require you to create an account to use its current core features.

Permissions and External Services

The current app uses internet access for network diagnostics, public IP lookup, advertising, and remote ad configuration. No analytics or crash reporting SDK is intentionally integrated in the current source repository.

Your Choices

You can clear locally stored test history from the app settings. You can also remove locally stored app data by deleting the app from your device. Advertising choices may be available through your device settings, Google settings, or regional consent prompts.

Changes

This Privacy Policy may be updated when the app, third-party services, or legal requirements change. The updated version will be made available in the app or through the app's support channels.

Contact

For privacy questions, contact Zyverio support through the support email listed for Fast Tunnel.
''';

const _termsOfUse = '''
Terms of Use for Fast Tunnel

Last Updated: August 2026

Fast Tunnel provides its currently implemented network session, location, and diagnostic functionality. By using the app, you agree to use it lawfully and responsibly.

Current Functionality

Fast Tunnel can run user-triggered network diagnostics, display diagnostic results, show selected locations, save favorite locations, and store completed test history locally on your device.

No VPN Service

Fast Tunnel is not currently a VPN service. It does not guarantee encryption, anonymity, IP masking, traffic protection, or rerouting of all device traffic. Displayed locations must be understood as app locations or session selections, not VPN servers, unless a future version clearly implements and describes server-based functionality.

Diagnostic Results

Results are estimates based on network conditions, endpoint availability, DNS checks, HTTPS reachability, and public IP lookup availability at the time of the test. Results may vary and are provided for informational use.

Third-Party Services

The app may use third-party services for advertising, diagnostic endpoints, public IP lookup, app distribution, and related platform services. Those services may be subject to their own terms and policies.

Availability and Changes

Fast Tunnel is provided subject to reasonable availability limitations. Features, locations, diagnostics, advertising behavior, and app availability may change in future versions.

Acceptable Use

You must not use Fast Tunnel in a way that violates applicable laws, interferes with services, abuses diagnostic endpoints, or attempts to reverse engineer or misuse the app.

Disclaimer

The app is provided as a lightweight utility. To the maximum extent permitted by law, Zyverio is not responsible for network provider issues, third-party service outages, diagnostic inaccuracies, or losses resulting from reliance on diagnostic results.
''';
