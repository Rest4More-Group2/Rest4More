import Flutter
import UIKit
import FamilyControls

@available(iOS 13, *)
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
