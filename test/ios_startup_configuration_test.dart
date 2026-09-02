import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Info.plist contains a valid iOS AdMob application id', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<key>GADApplicationIdentifier</key>'));
    expect(infoPlist, contains('ca-app-pub-7416708332505708~4826573381'));
    expect(
      infoPlist,
      isNot(contains('ca-app-pub-3940256099942544~3347511713')),
    );
  });

  test('iOS advertising stays non-personalized without ATT', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final mainDart = File('lib/main.dart').readAsStringSync();

    expect(
      appDelegate,
      contains('publisherPrivacyPersonalizationState = .disabled'),
    );
    expect(appDelegate, contains('setPublisherFirstPartyIDEnabled(false)'));
    expect(appDelegate, isNot(contains('AppTrackingTransparency')));
    expect(appDelegate, isNot(contains('ATTrackingManager')));
    expect(infoPlist, isNot(contains('NSUserTrackingUsageDescription')));
    expect(infoPlist, contains('<key>GADDelayAppMeasurementInit</key>'));
    expect(
      infoPlist,
      contains('<key>GADDelayAppMeasurementInit</key>\n\t<true/>'),
    );
    expect(mainDart, isNot(contains('MobileAdsInitializer')));
  });

  test('iOS Runner has no special networking capability or extension', () {
    final iosFiles = Directory('ios')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.swift') ||
              file.path.endsWith('.m') ||
              file.path.endsWith('.h') ||
              file.path.endsWith('.plist') ||
              file.path.endsWith('.pbxproj') ||
              file.path.endsWith('.xcconfig'),
        )
        .toList();
    final source = iosFiles.map((file) => file.readAsStringSync()).join('\n');

    expect(
      Directory('ios')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.entitlements')),
      isEmpty,
    );
    expect(source, isNot(contains('NetworkExtension')));
    expect(source, isNot(contains('NEVPNManager')));
    expect(source, isNot(contains('NEPacketTunnelProvider')));
    expect(source, isNot(contains('com.apple.developer.networking.vpn.api')));
    expect(
      source,
      isNot(contains('com.apple.developer.networking.networkextension')),
    );
    expect(source, isNot(contains('CODE_SIGN_ENTITLEMENTS')));
  });
}
