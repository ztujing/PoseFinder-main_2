// 目的: 撮影画面（UIKit）をSwiftUIに載せ、完了通知を親画面へ橋渡しする。
// 入出力: 録画完了通知/中断通知と完了コールバック。
// 依存: UIKit Storyboard, NotificationCenter, RecordingSessionRepository。
// 副作用: 画面遷移、録画中断の通知送信。

import Foundation
import SwiftUI
import UIKit

enum UITestSupport {
    static let seedSessionArgument = "-UITestSeedSession"
    static let autoCompleteRecordingArgument = "-UITestAutoCompleteRecording"
    static let seededSessionID = "ui-test-session-001"

    static var shouldSeedSession: Bool {
        CommandLine.arguments.contains(seedSessionArgument)
    }

    static var shouldAutoCompleteRecording: Bool {
        CommandLine.arguments.contains(autoCompleteRecordingArgument)
    }

    static func seededSessionDirectoryURL(fileManager: FileManager = .default) -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        return documentsURL
            .appendingPathComponent("Sessions", isDirectory: true)
            .appendingPathComponent(seededSessionID, isDirectory: true)
    }
}

extension Notification.Name {
    static let recordingSessionShouldCancel = Notification.Name("RecordingSessionShouldCancel")
    static let recordingSessionDidComplete = Notification.Name("RecordingSessionDidComplete")
}

enum RecordingSessionNotificationUserInfoKey {
    static let directoryURL = "recordingSessionDirectoryURL"
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
    @State private var isHandlingCompletion = false
    @State private var isShowingCompletionFailureAlert = false

    private let repository = RecordingSessionRepository()
    private let completionRetryDelay: TimeInterval = 0.25

    let onCompleted: (RecordingSession) -> Void

    init(onCompleted: @escaping (RecordingSession) -> Void = { _ in }) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        RecordingSessionContainerView()
            .accessibilityIdentifier("recording.screen.root")
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // 完了済みなら戻る、未完了なら中断確認を出す。
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
            .alert("保存は完了しました", isPresented: $isShowingCompletionFailureAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("履歴からセッションを確認してください。")
            }
            .onAppear {
                sessionCompleted = false
                isHandlingCompletion = false
                isShowingCompletionFailureAlert = false
                triggerUITestAutoCompletionIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .recordingSessionDidComplete)) { notification in
                guard !isHandlingCompletion else { return }
                isHandlingCompletion = true
                sessionCompleted = true
                handleRecordingCompleted(notification: notification)
            }
    }

    // --- Completion Handling ---

    private func handleRecordingCompleted(notification: Notification) {
        guard let directoryURL = notification.userInfo?[RecordingSessionNotificationUserInfoKey.directoryURL] as? URL else {
            showCompletionFailureAlert()
            return
        }
        loadCompletedSession(directoryURL: directoryURL, remainingRetries: 1)
    }

    private func loadCompletedSession(directoryURL: URL, remainingRetries: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = repository.reloadSession(at: directoryURL)
            DispatchQueue.main.async {
                switch result {
                case .success(let session):
                    dismiss()
                    DispatchQueue.main.async {
                        onCompleted(session)
                    }
                case .failure:
                    // 1回だけ再試行し、失敗時は自動遷移を諦める。
                    if remainingRetries > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + completionRetryDelay) {
                            loadCompletedSession(directoryURL: directoryURL, remainingRetries: remainingRetries - 1)
                        }
                    } else {
                        showCompletionFailureAlert()
                    }
                }
            }
        }
    }

    private func showCompletionFailureAlert() {
        isShowingCompletionFailureAlert = true
    }

    private func triggerUITestAutoCompletionIfNeeded() {
        guard UITestSupport.shouldAutoCompleteRecording else { return }
        guard let directoryURL = UITestSupport.seededSessionDirectoryURL() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(
                name: .recordingSessionDidComplete,
                object: nil,
                userInfo: [RecordingSessionNotificationUserInfoKey.directoryURL: directoryURL]
            )
        }
    }
}
