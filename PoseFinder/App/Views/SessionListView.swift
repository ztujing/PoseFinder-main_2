import SwiftUI

struct SessionListView: View {
    @StateObject var viewModel: SessionListViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List(viewModel.sessions) { session in
            if session.isComplete {
                // Use iOS 15 compatible NavigationLink initializer
                NavigationLink(destination: SessionDetailView(session: session)) {
                    sessionRowContent(for: session, showIncompleteMessage: false)
                }
                .accessibilityIdentifier("session.list.completeRow.\(session.id)")
            } else {
                sessionRowContent(for: session, showIncompleteMessage: true)
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("session.list.incompleteRow.\(session.id)")
            }
        }
        .accessibilityIdentifier("session.list.root")
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView("読み込み中…")
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            } else if viewModel.sessions.isEmpty {
                Text("録画済みセッションがありません")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("セッション履歴")
        .onAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    private func sessionRowContent(for session: RecordingSession, showIncompleteMessage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.id)
                .font(.headline)
            Text(dateFormatter.string(from: session.createdAt))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let video = session.video {
                Text(video.fileName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if showIncompleteMessage {
                Text("中断されたため正しく保存されませんでした。")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
