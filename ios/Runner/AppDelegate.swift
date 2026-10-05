import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    excludeSupportDirectoryFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// De lokale database staat in Application Support. Die map hoort niet in
  /// iCloud- of computerback-ups: de sleutel blijft in de Keychain van dit
  /// toestel en de gegevens komen terug via de eigen synchronisatie.
  private func excludeSupportDirectoryFromBackup() {
    let fileManager = FileManager.default
    guard var url = try? fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ) else { return }
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? url.setResourceValues(values)
  }
}
