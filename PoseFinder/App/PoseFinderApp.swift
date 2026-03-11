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
    private let uiTestMenu = TrainingMenu(
        id: "ui-test-training-menu-001",
        title: "UI Test Training",
        description: "UIテスト用の一時メニューです。",
        focusPoints: ["フォームを安定させる"],
        estimatedDurationMinutes: 1,
        videoFileName: nil
    )

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    rootContent
                }
            } else {
                NavigationView {
                    rootContent
                }
                .navigationViewStyle(.stack)
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if UITestSupport.shouldOpenSessionList {
            SessionListView(viewModel: SessionListViewModel())
        } else if UITestSupport.shouldOpenTrainingDetail {
            TrainingMenuDetailView(viewModel: TrainingMenuDetailViewModel(menu: uiTestMenu))
        } else {
            HomeView(viewModel: homeViewModel)
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
