import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsPrivacyStatus {
  const AdsPrivacyStatus({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
    this.errorMessage,
  });

  const AdsPrivacyStatus.unavailable({this.errorMessage})
    : canRequestAds = false,
      privacyOptionsRequired = false;

  final bool canRequestAds;
  final bool privacyOptionsRequired;
  final String? errorMessage;
}

abstract class AdsPrivacyService {
  Future<AdsPrivacyStatus> prepareForAds();

  Future<void> showPrivacyOptions();
}

class UmpAdsPrivacyService implements AdsPrivacyService {
  Future<AdsPrivacyStatus>? _preparation;

  @override
  Future<AdsPrivacyStatus> prepareForAds() {
    return _preparation ??= _prepareForAds();
  }

  @override
  Future<void> showPrivacyOptions() {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(StateError(error.message));
      }
    });
    return completer.future;
  }

  Future<AdsPrivacyStatus> _prepareForAds() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const AdsPrivacyStatus.unavailable();
    }

    FormError? updateError;
    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updateCompleter.complete,
      (error) {
        updateError = error;
        updateCompleter.complete();
      },
    );
    await updateCompleter.future;

    FormError? formError;
    if (updateError == null) {
      final formCompleter = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((error) {
        formError = error;
        formCompleter.complete();
      });
      await formCompleter.future;
    }

    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    final optionsStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    final error = updateError ?? formError;
    return AdsPrivacyStatus(
      canRequestAds: canRequestAds,
      privacyOptionsRequired:
          optionsStatus == PrivacyOptionsRequirementStatus.required,
      errorMessage: error?.message,
    );
  }
}
