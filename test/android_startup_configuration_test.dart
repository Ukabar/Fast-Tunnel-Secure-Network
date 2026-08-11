import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest contains a valid AdMob application id', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android:name="com.google.android.gms.ads.APPLICATION_ID"'),
    );
    expect(manifest, contains('ca-app-pub-3940256099942544~3347511713'));
    expect(manifest, isNot(contains('REPLACE_WITH_REAL_ANDROID_ADMOB_APP_ID')));
  });
}
