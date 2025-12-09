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
        List {
            if viewModel.isLoading {
                ProgressView("読み込み中…")
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if viewModel.sessions.isEmpty {
                Section {
                    Text("録画済みセッションがありません")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.sessions) { session in
                    if session.isComplete {
                        NavigationLink(destination: SessionDetailView(viewModel: SessionDetailViewModel(session: session))) {
                            sessionRowContent(for: session, showIncompleteMessage: false)
                        }
                    } else {
                        sessionRowContent(for: session, showIncompleteMessage: true)
                            .contentShape(Rectangle())
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .navigationTitle("セッション履歴")
        .onAppear {
            if viewModel.sessions.isEmpty {
                viewModel.refresh()
            }
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
