import UIKit

/// Native Swift iOS Application Delegate Entry Point for Novetus Engine
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = NovetusViewController()
        window?.makeKeyAndVisible()
        print("[Novetus-iOS] AppDelegate launched successfully.")
        return true
    }
}
