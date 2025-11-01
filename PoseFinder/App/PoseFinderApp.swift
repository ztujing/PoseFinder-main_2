import SwiftUI
import UIKit

@main
struct PoseFinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            LegacyRootView()
        }
    }
}

private struct LegacyRootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateInitialViewController() ?? UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op: legacy UIKit controller manages its own updates.
    }
}
