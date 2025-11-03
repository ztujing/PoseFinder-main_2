import SwiftUI
import UIKit

@main
struct PoseFinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("-UseLegacyUI") {
                LegacyRootView()
            } else {
                RootNavigationView()
            }
        }
    }
}

private struct RootNavigationView: View {
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    HomeView(viewModel: homeViewModel)
                }
            } else {
                NavigationView {
                    HomeView(viewModel: homeViewModel)
                }
                .navigationViewStyle(.stack)
            }
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
