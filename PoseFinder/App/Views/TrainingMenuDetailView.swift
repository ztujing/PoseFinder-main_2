import SwiftUI

struct TrainingMenuDetailView: View {
    @ObservedObject var viewModel: TrainingMenuDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                focusSection
                navigationSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
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
                RecordingSessionContainerView()
                    .ignoresSafeArea()
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
}
