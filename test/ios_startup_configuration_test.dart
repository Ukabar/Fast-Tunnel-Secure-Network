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
}
