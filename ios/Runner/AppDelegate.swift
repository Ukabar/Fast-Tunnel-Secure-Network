import Flutter
import GoogleMobileAds
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.publisherPrivacyPersonalizationState = .disabled
    requestConfiguration.setPublisherFirstPartyIDEnabled(false)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
