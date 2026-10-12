import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import SwiftUI

@available(iOS 16, *)
class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("Could not find FlutterViewController")
            return
        }

        let channel = FlutterMethodChannel(name: "com.example.app_blocking_prototype/blocking", binaryMessenger: controller.binaryMessenger)

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
                UserDefaults.standard.set(isBlocking, forKey: "isBlocking")

                let store = ManagedSettingsStore()
                if isBlocking {
                    // Een moment geeft zijn eigen selectie mee; zonder valt dit
                    // terug op de oude gedeelde selectie.
                    let blockArgs = call.arguments as? [String: Any]
                    let given = blockArgs?["selection"] as? FlutterStandardTypedData
                    // Met `momentSelection` geldt alleen de keuze van dat moment;
                    // zonder eigen keuze wordt er dan niets geblokkeerd.
                    let momentOnly = blockArgs?["momentSelection"] as? Bool ?? false
                    let stored = given?.data ?? (momentOnly ? nil : UserDefaults.standard.data(forKey: "blockedSelection"))
                    if let data = stored,
                       let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                        store.shield.applications = selection.applicationTokens
                        store.shield.applicationCategories = .specific(selection.categoryTokens)
                    }
                } else {
                    store.shield.applications = nil
                    store.shield.applicationCategories = nil
                }
                result(nil)
            case "showAppPicker":
                guard let rootVC = self.window?.rootViewController else {
                    result(nil)
                    return
                }
                let args = call.arguments as? [String: Any]
                // Met `returnSelection` bewaart Flutter de selectie per moment;
                // zonder blijft het oude gedeelde gedrag.
                let returnSelection = args?["returnSelection"] as? Bool ?? false
                var initial = FamilyActivitySelection()
                if let given = args?["selection"] as? FlutterStandardTypedData,
                   let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: given.data) {
                    initial = decoded
                }
                let hostingController = UIHostingController(rootView: AppPickerHostView(initial: initial, onDone: { selection in
                    let data = try? PropertyListEncoder().encode(selection)
                    if !returnSelection, let data = data {
                        UserDefaults.standard.set(data, forKey: "blockedSelection")
                    }
                    rootVC.dismiss(animated: true) {
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
                rootVC.present(hostingController, animated: true)
            case "openSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
