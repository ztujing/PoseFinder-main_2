// 目的: トレーニングメニュー詳細と撮影開始導線を提供し、完了後に詳細へ遷移する。
// 入出力: 選択メニュー情報/撮影完了コールバック。
// 依存: RecordingSessionScreen, SessionDetailView。
// 副作用: 画面遷移（撮影→セッション詳細）。

import SwiftUI
import AVKit

struct TrainingMenuDetailView: View {
    @ObservedObject var viewModel: TrainingMenuDetailViewModel
    @State private var completedSession: RecordingSession?
    @State private var isShowingSessionDetail = false
    @State private var player = AVPlayer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let videoURL = viewModel.videoURL() {
                    VideoPlayer(player: player)
                        .frame(height: 220)
                        .cornerRadius(8)
                        .onAppear {
                            configureAndPlayVideo(from: videoURL)
                        }
                        .onDisappear {
                            player.pause()
                        }
                        .padding(.bottom, 8)
                }
                headerSection
                focusSection
                navigationSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)

            sessionDetailLink
        }
        .navigationTitle(viewModel.menu.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("概要")
                .font(.title3)
                .fontWeight(.semibold)
            Text(viewModel.menu.description)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("チェックポイント")
                .font(.title3)
                .fontWeight(.semibold)
            ForEach(viewModel.menu.focusPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(point)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("準備ができたら撮影を開始しましょう。既存の撮影画面が起動し、Pose 検出と保存処理が行われます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            NavigationLink {
                RecordingSessionScreen { session in
                    DispatchQueue.main.async {
                        handleRecordingCompleted(session)
                    }
                }
                    .navigationTitle("撮影")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text("撮影を開始")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
        }
    }

    private var sessionDetailLink: some View {
        NavigationLink(destination: sessionDetailDestination, isActive: $isShowingSessionDetail) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var sessionDetailDestination: some View {
        // セッション取得の有無に応じて遷移先を切り替える。
        if let session = completedSession {
            SessionDetailView(session: session)
        } else {
            EmptyView()
        }
    }

    private func handleRecordingCompleted(_ session: RecordingSession) {
        guard !isShowingSessionDetail else { return }
        completedSession = session
        isShowingSessionDetail = true
    }

    private func configureAndPlayVideo(from url: URL) {
        let currentURL = (player.currentItem?.asset as? AVURLAsset)?.url
        if currentURL != url {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
        }

        player.isMuted = true
        player.play()
    }
}
