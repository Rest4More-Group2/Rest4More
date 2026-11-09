import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import SwiftUI
import UserNotifications

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

        registerNotificationChannel(messenger: controller.binaryMessenger)

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
                let args = call.arguments as? [String: Any]
                let isBlocking = args?["isBlocking"] as? Bool ?? false
                // Een moment geeft zijn eigen selectie mee. Met `momentSelection`
                // geldt alleen die keuze: heeft het moment geen eigen keuze, dan
                // wordt er niets geblokkeerd (geen terugval op de gedeelde lijst).
                // Zonder moment geldt de oude gedeelde selectie.
                let given = args?["selection"] as? FlutterStandardTypedData
                let momentOnly = args?["momentSelection"] as? Bool ?? false
                self.applyBlocking(isBlocking, selectionData: given?.data, momentOnly: momentOnly)
                result(nil)
            case "getBlocking":
                result(UserDefaults.standard.bool(forKey: "isBlocking"))
            case "setTagSelection":
                // De eigen appkeuze van het Tag-moment, voor tag-links die de
                // blokkade starten zonder dat Flutter draait.
                let given = (call.arguments as? [String: Any])?["selection"] as? FlutterStandardTypedData
                if let data = given?.data {
                    UserDefaults.standard.set(data, forKey: "tagSelection")
                } else {
                    UserDefaults.standard.removeObject(forKey: "tagSelection")
                }
                result(nil)
            case "grantUnblock":
                // iOS kent de namen van de gekozen apps niet, dus de hele blokkade
                // pauzeert even. Daarna zet reapplyIfExpired hem terug.
                let minutes = (call.arguments as? [String: Any])?["minutes"] as? Int ?? 0
                guard minutes >= 1, minutes <= 15 else {
                    result(FlutterError(code: "bad_request", message: "1-15 minutes required", details: nil))
                    return
                }
                UserDefaults.standard.set(Date().timeIntervalSince1970 + Double(minutes * 60), forKey: "unblockUntil")
                let store = ManagedSettingsStore()
                store.shield.applications = nil
                store.shield.applicationCategories = nil
                result(nil)
            case "reapplyIfExpired":
                self.reapplyIfExpired()
                result(nil)
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
                let args = call.arguments as? [String: Any]
                // Met `returnSelection` bewaart Flutter de selectie per moment;
                // zonder blijft het oude gedeelde gedrag (UserDefaults).
                let returnSelection = args?["returnSelection"] as? Bool ?? false
                var initial: FamilyActivitySelection? = nil
                if returnSelection {
                    initial = FamilyActivitySelection()
                    if let given = args?["selection"] as? FlutterStandardTypedData,
                       let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: given.data) {
                        initial = decoded
                    }
                }
                let hostingController = UIHostingController(rootView: AppPickerHostView(initial: initial, onDone: { selection in
                    let data = try? PropertyListEncoder().encode(selection)
                    if !returnSelection, let data = data {
                        UserDefaults.standard.set(data, forKey: "blockedSelection")
                    }
                    rootVC.dismiss(animated: false) {
                        if returnSelection, let data = data {
                            // De tellingen laten Flutter weten of er echt iets gekozen is.
                            result([
                                "selection": FlutterStandardTypedData(bytes: data),
                                "apps": selection.applicationTokens.count,
                                "categories": selection.categoryTokens.count,
                                "websites": selection.webDomainTokens.count,
                            ])
                        } else {
                            result(nil)
                        }
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
        // Alleen de apps van het Tag-moment; zonder eigen keuze blokkeert dit niets.
        applyBlocking(newState, selectionData: UserDefaults.standard.data(forKey: "tagSelection"), momentOnly: true)
        channel?.invokeMethod("blockingChanged", arguments: newState)
    }

    /// Single place that stores and applies the blocking state, used by both
    /// the `setBlocking` channel call and tag links. A moment can pass its own
    /// selection; `momentOnly` stops it falling back to the shared list.
    private func applyBlocking(_ isBlocking: Bool, selectionData: Data? = nil, momentOnly: Bool = false) {
        UserDefaults.standard.set(isBlocking, forKey: "isBlocking")
        // Een nieuwe of beëindigde blokkade begint schoon: een eerdere tijdelijke
        // vrijgave geldt daar niet meer.
        UserDefaults.standard.removeObject(forKey: "unblockUntil")

        let store = ManagedSettingsStore()
        if isBlocking {
            let stored = selectionData ?? (momentOnly ? nil : UserDefaults.standard.data(forKey: "blockedSelection"))
            // Bewaar wat er nu geblokkeerd is, om na een tijdelijke vrijgave terug te zetten.
            if let stored = stored {
                UserDefaults.standard.set(stored, forKey: "activeSelection")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeSelection")
            }
            if let data = stored,
               let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            } else {
                // Niets gekozen: laat geen oude blokkade van een ander moment staan.
                store.shield.applications = nil
                store.shield.applicationCategories = nil
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "activeSelection")
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        }
    }

    /// Zet de blokkade terug als een tijdelijke vrijgave voorbij is. Flutter
    /// roept dit aan zodra de app weer naar voren komt en tijdens een sessie.
    /// Een app kan op iOS niet zelf wakker worden om dit op de seconde te doen;
    /// dat vergt een DeviceActivity-extensie.
    private func reapplyIfExpired() {
        let until = UserDefaults.standard.double(forKey: "unblockUntil")
        guard until > 0, Date().timeIntervalSince1970 >= until else { return }
        guard UserDefaults.standard.bool(forKey: "isBlocking") else {
            UserDefaults.standard.removeObject(forKey: "unblockUntil")
            return
        }
        applyBlocking(true, selectionData: UserDefaults.standard.data(forKey: "activeSelection"), momentOnly: true)
    }

    /// Toestemming voor meldingen (zie notification_permission.dart). Vraagt
    /// alleen bij "request"; iOS laat het venster maar een keer zien, daarna
    /// is "denied" definitief en kan het alleen via Instellingen.
    private func registerNotificationChannel(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "rest4more/notifications", binaryMessenger: messenger)
        let center = UNUserNotificationCenter.current()

        func currentStatus(_ done: @escaping (String) -> Void) {
            center.getNotificationSettings { settings in
                let status: String
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    status = "granted"
                case .denied:
                    status = "blocked"
                case .notDetermined:
                    status = "notDetermined"
                @unknown default:
                    status = "notDetermined"
                }
                DispatchQueue.main.async { done(status) }
            }
        }

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "status":
                currentStatus { result($0) }
            case "request":
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                    currentStatus { result($0) }
                }
            case "openSettings":
                guard let url = URL(string: UIApplication.openNotificationSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else {
                    result(false)
                    return
                }
                UIApplication.shared.open(url) { opened in result(opened) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
