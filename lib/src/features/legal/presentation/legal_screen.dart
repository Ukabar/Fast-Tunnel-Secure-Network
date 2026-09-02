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

Fast Tunnel is an internet and network testing utility. This Privacy Policy explains how information may be handled when you use its on-demand diagnostics.

Network Diagnostics

When you start a test, the app may contact lightweight HTTPS endpoints to measure latency, jitter, request failure rate, DNS resolution, and HTTPS reachability. These diagnostic requests are used to calculate the network score shown in the app.

Public IP Lookup

The app may request your current public IP address from a third-party endpoint, such as api.ipify.org, and display it as an informational diagnostic value. This is a read-only lookup and does not modify device network settings.

Local Data

Fast Tunnel may store completed test history, appearance settings, test accuracy settings, onboarding status, and advertising display counters locally on your device using local app storage.

Advertising

Fast Tunnel includes Google Mobile Ads and Google's User Messaging Platform. Advertising is not requested until the applicable privacy flow has completed and Google reports that ads can be requested. On iOS, Fast Tunnel requests non-personalized ads, disables Google's publisher first-party identifier and ad personalization, does not request App Tracking Transparency permission, and does not access the IDFA.

Google and its advertising partners may still process information needed to deliver and measure non-personalized or limited ads, including IP-derived approximate location, app- or SDK-scoped identifiers, ads viewed, ad interactions, performance information, and fraud-prevention signals. This information is subject to Google's privacy terms and the choices presented through Google's consent flow.

No Accounts

Fast Tunnel does not require you to create an account to use its current core features.

Permissions and External Services

The current app uses internet access for network diagnostics, public IP lookup, advertising, and remote ad configuration. No analytics or crash reporting SDK is intentionally integrated in the current source repository.

Your Choices

You can clear locally stored test history from the app settings. You can also remove locally stored app data by deleting the app from your device. When required for your region, the Settings screen provides a Privacy choices entry for reviewing or changing advertising choices.

Changes

This Privacy Policy may be updated when the app, third-party services, or legal requirements change. The updated version will be made available in the app or through the app's support channels.

Contact

For privacy questions, contact Zyverio support through the support email listed for Fast Tunnel.
''';

const _termsOfUse = '''
Terms of Use for Fast Tunnel

Last Updated: August 2026

Fast Tunnel provides user-triggered internet and network diagnostic functionality. By using the app, you agree to use it lawfully and responsibly.

Current Functionality

Fast Tunnel can run user-triggered network diagnostics, display measured results and the current public IP returned by a lookup service, and store completed test history locally on your device. These diagnostic checks are read-only and the app does not alter device network settings.

Diagnostic Results

Results are estimates based on network conditions, endpoint availability, DNS checks, HTTPS reachability, and public IP lookup availability at the time of the test. Results may vary and are provided for informational use.

Third-Party Services

The app may use third-party services for advertising, diagnostic endpoints, public IP lookup, app distribution, and related platform services. Those services may be subject to their own terms and policies.

Availability and Changes

Fast Tunnel is provided subject to reasonable availability limitations. Diagnostics, advertising behavior, and app availability may change in future versions.

Acceptable Use

You must not use Fast Tunnel in a way that violates applicable laws, interferes with services, abuses diagnostic endpoints, or attempts to reverse engineer or misuse the app.

Disclaimer

The app is provided as a lightweight utility. To the maximum extent permitted by law, Zyverio is not responsible for network provider issues, third-party service outages, diagnostic inaccuracies, or losses resulting from reliance on diagnostic results.
''';
