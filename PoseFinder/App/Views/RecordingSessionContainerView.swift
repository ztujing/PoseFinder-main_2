import SwiftUI
import UIKit

struct RecordingSessionContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        if let controller = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            return controller
        }

        assertionFailure("ViewControllerがStoryboard(Main)に存在しません")
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // UIKit 側で状態を管理しているため特に更新は不要
    }
}
