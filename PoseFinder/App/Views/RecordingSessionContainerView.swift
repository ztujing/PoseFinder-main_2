import SwiftUI
import UIKit

extension Notification.Name {
    static let recordingSessionShouldCancel = Notification.Name("RecordingSessionShouldCancel")
    static let recordingSessionDidComplete = Notification.Name("RecordingSessionDidComplete")
}

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

struct RecordingSessionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingCancelAlert = false
    @State private var sessionCompleted = false

    var body: some View {
        RecordingSessionContainerView()
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if sessionCompleted {
                            dismiss()
                        } else {
                            isShowingCancelAlert = true
                        }
                    } label: {
                        Label("戻る", systemImage: "chevron.backward")
                    }
                }
            }
            .alert("セッションを中断しますか？", isPresented: $isShowingCancelAlert) {
                Button("中断する", role: .destructive) {
                    NotificationCenter.default.post(name: .recordingSessionShouldCancel, object: nil)
                    dismiss()
                }
                Button("続ける", role: .cancel) {}
            } message: {
                Text("中断した場合は保存されません。")
            }
            .onAppear {
                sessionCompleted = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .recordingSessionDidComplete)) { _ in
                sessionCompleted = true
            }
    }
}
