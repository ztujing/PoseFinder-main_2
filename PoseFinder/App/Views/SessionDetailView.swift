// 目的: セッション詳細で動画再生とPose情報を表示し、同期オーバーレイを提供する。
// 入出力: `SessionDetailViewModel` の状態を表示する。
// 依存: AVKit, SessionDetailViewModel, PosePreviewView。
// 副作用: 再生の開始/停止、タイムオブザーバの制御。

import AVKit
import SwiftUI

struct SessionDetailView: View {
    @StateObject private var viewModel: SessionDetailViewModel
    @State private var isVideoPlaying = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    init(session: RecordingSession) {
        _viewModel = StateObject(wrappedValue: SessionDetailViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isReloading && viewModel.session.video == nil && viewModel.posePreview == nil {
                    VStack(spacing: 16) {
                        ProgressView("最新データを読み込み中…")
                            .progressViewStyle(.circular)
                    }
                    .frame(maxWidth: .infinity)
                }
                videoSection
                poseSection
                metadataSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .accessibilityIdentifier("session.detail.root")
        .navigationTitle("セッション詳細")
        
        
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.player?.pause()
            viewModel.stopTimeObserver()
        }
        .onAppear {
            print("SessionDetailView onAppear at \(Date())")
            viewModel.reloadSessionWithDelay()
            viewModel.startTimeObserverIfNeeded()
        }
    }

    // --- Sections ---

    @ViewBuilder
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("動画")
                .font(.title3)
                .fontWeight(.semibold)
            
            // 動画プレイヤと同期Poseを重ねて表示する。
            if let player = viewModel.player {
                GeometryReader { geometry in
                    ZStack {
                        VideoPlayer(player: player)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .accessibilityIdentifier("session.detail.videoPlayer")
                            .onAppear {
                                if !isVideoPlaying {
                                    player.play()
                                    isVideoPlaying = true
                                }
                            }
                        if let frame = viewModel.currentPoseFrame {
                            PosePreviewView(
                                poseFrame: frame,
                                aspectRatioSize: viewModel.player?.currentItem?.presentationSize ?? viewModel.session.video?.size
                            )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .allowsHitTesting(false)
                                .accessibilityIdentifier("session.detail.syncedPoseOverlay")
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
            } else {
                Text("動画ファイルが見つかりません。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var poseSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Pose プレビュー")
                .font(.title3)
                .fontWeight(.semibold)

            // 同期フレームがあればそれを優先し、なければ静的プレビューを表示する。
            if let frame = viewModel.currentPoseFrame ?? viewModel.posePreview {
                GeometryReader { geometry in
                    PosePreviewView(
                        poseFrame: frame,
                        aspectRatioSize: viewModel.player?.currentItem?.presentationSize ?? viewModel.session.video?.size
                    )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                        .accessibilityIdentifier("session.detail.posePreview")
                }
                .frame(height: 240)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
            } else {
                Text("Pose データが見つかりません。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("メタ情報")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("セッションID")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.session.id)
                }
                HStack {
                    Text("作成日時")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(dateFormatter.string(from: viewModel.session.createdAt))
                }
            }

            if let video = viewModel.session.video {
                VStack(alignment: .leading, spacing: 6) {
                    Text("動画ファイル")
                        .fontWeight(.semibold)
                    metadataRow(label: "ファイル名", value: video.fileName)
                    metadataRow(label: "コーデック", value: video.codec)
                    if let size = video.size {
                        metadataRow(label: "解像度", value: "\(Int(size.width)) x \(Int(size.height))")
                    }
                    if let fps = video.fps {
                        metadataRow(label: "FPS", value: String(format: "%.1f", fps))
                    }
                    if let bytes = video.fileSizeBytes {
                        metadataRow(label: "サイズ", value: ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                    }
                    metadataRow(label: "パス", value: video.url.lastPathComponent)
                }
            }

            if let pose = viewModel.session.pose {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pose ファイル")
                        .fontWeight(.semibold)
                    metadataRow(label: "ファイル名", value: pose.fileName)
                    metadataRow(label: "座標モード", value: pose.coords)
                    metadataRow(label: "関節セット", value: pose.jointSet)
                    if let bytes = pose.fileSizeBytes {
                        metadataRow(label: "サイズ", value: ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                    }
                    metadataRow(label: "パス", value: pose.url.lastPathComponent)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("デバイス")
                    .fontWeight(.semibold)
                metadataRow(label: "モデル", value: viewModel.session.device.model)
                metadataRow(label: "OS", value: viewModel.session.device.os)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("カメラ")
                    .fontWeight(.semibold)
                metadataRow(label: "位置", value: viewModel.session.camera.position)
                metadataRow(label: "プリセット", value: viewModel.session.camera.preset)
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}
