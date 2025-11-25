import AVKit
import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var isVideoPlaying = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                videoSection
                poseSection
                metadataSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("セッション詳細")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.player?.pause()
        }
    }

    @ViewBuilder
    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("動画")
                .font(.title3)
                .fontWeight(.semibold)
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(height: 240)
                    .cornerRadius(12)
                    .onAppear {
                        if !isVideoPlaying {
                            player.play()
                            isVideoPlaying = true
                        }
                    }
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
            if let frame = viewModel.posePreview {
                PosePreviewView(poseFrame: frame)
                    .frame(height: 240)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
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
