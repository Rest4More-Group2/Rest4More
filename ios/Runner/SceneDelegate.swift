import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import SwiftUI

@available(iOS 16, *)
class SceneDelegate: FlutterSceneDelegate {
    private var channel: FlutterMethodChannel?

    private let tagHost = "tap.bartvangestel.nl"

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("Could not find FlutterViewController")
            return
        }

        let channel = FlutterMethodChannel(name: "com.example.app_blocking_prototype/blocking", binaryMessenger: controller.binaryMessenger)
        self.channel = channel

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "requestAuthorization":
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        result(true)
                    } catch {
                        result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            case "checkAuthorizationStatus":
                let status = AuthorizationCenter.shared.authorizationStatus
                switch status {
                case .notDetermined:
                    result("notDetermined")
                case .denied:
                    result("denied")
                case .approved:
                    result("approved")
                @unknown default:
                    result("notDetermined")
                }
            case "setBlocking":
                let isBlocking = (call.arguments as? [String: Any])?["isBlocking"] as? Bool ?? false
                self.applyBlocking(isBlocking)
                result(nil)
            case "getBlocking":
                result(UserDefaults.standard.bool(forKey: "isBlocking"))
            case "getKnownTags":
                result(UserDefaults.standard.stringArray(forKey: "knownTags") ?? [])
            case "addKnownTag":
                if let args = call.arguments as? [String: Any],
                   let raw = args["uuid"] as? String,
                   let uuid = UUID(uuidString: raw) {
                    var tags = UserDefaults.standard.stringArray(forKey: "knownTags") ?? []
                    let id = uuid.uuidString.lowercased()
                    if !tags.contains(id) { tags.append(id) }
                    UserDefaults.standard.set(tags, forKey: "knownTags")
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_uuid", message: "Not a valid UUID", details: nil))
                }
            case "removeKnownTag":
                if let args = call.arguments as? [String: Any], let raw = args["uuid"] as? String {
                    var tags = UserDefaults.standard.stringArray(forKey: "knownTags") ?? []
                    tags.removeAll { $0 == raw.lowercased() }
                    UserDefaults.standard.set(tags, forKey: "knownTags")
                }
                result(nil)
            case "showAppPicker":
                guard let rootVC = self.window?.rootViewController else {
                    result(nil)
                    return
                }
                let hostingController = UIHostingController(rootView: AppPickerHostView(onDone: {
                    rootVC.dismiss(animated: false) {
                        result(nil)
                    }
                }))
                hostingController.view.backgroundColor = .clear
                hostingController.modalPresentationStyle = .overFullScreen
                rootVC.present(hostingController, animated: false)
            case "openSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Cold start: the app was launched by a tag link.
        if let activity = connectionOptions.userActivities.first(where: {
            $0.activityType == NSUserActivityTypeBrowsingWeb
        }), let url = activity.webpageURL {
            handleTagURL(url)
        }
    }

    // Warm start: the app is already running or suspended.
    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        super.scene(scene, continue: userActivity)
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        handleTagURL(url)
    }

    private func handleTagURL(_ url: URL) {
        guard url.scheme == "https", url.host == tagHost else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, parts[0] == "t",
              let uuid = UUID(uuidString: parts[1]) else { return }

        let id = uuid.uuidString.lowercased()
        let known = UserDefaults.standard.stringArray(forKey: "knownTags") ?? []
        guard known.contains(id) else { return }  // unknown tag: ignore

        let newState = !UserDefaults.standard.bool(forKey: "isBlocking")
        applyBlocking(newState)
        channel?.invokeMethod("blockingChanged", arguments: newState)
    }

    /// Single place that stores and applies the blocking state, used by both
    /// the `setBlocking` channel call and tag links.
    private func applyBlocking(_ isBlocking: Bool) {
        UserDefaults.standard.set(isBlocking, forKey: "isBlocking")

        let store = ManagedSettingsStore()
        if isBlocking {
            if let data = UserDefaults.standard.data(forKey: "blockedSelection"),
               let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }
        } else {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        }
    }
}
