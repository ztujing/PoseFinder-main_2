import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isShowingHistory = false

    var body: some View {
        List(Array(viewModel.menus.enumerated()), id: \.element.id) { index, menu in
            NavigationLink(destination: TrainingMenuDetailView(viewModel: TrainingMenuDetailViewModel(menu: menu))) {
                TrainingMenuRow(menu: menu)
            }
            .accessibilityIdentifier("home.menu.row.\(index)")
        }
        .accessibilityIdentifier("home.menu.list")
        .listStyle(.insetGrouped)
        .navigationTitle("トレーニングメニュー")
        .toolbar {
            Button {
                isShowingHistory = true
            } label: {
                Label("履歴", systemImage: "clock.arrow.circlepath")
            }
            .accessibilityIdentifier("home.history.button")
        }
        .background(
            NavigationLink(
                destination: SessionListView(viewModel: SessionListViewModel()).navigationTitle("セッション履歴"),
                isActive: $isShowingHistory
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
}

private struct TrainingMenuRow: View {
    let menu: TrainingMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(menu.title)
                .font(.headline)
            Text(menu.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if let minutes = menu.estimatedDurationMinutes {
                Text("目安: 約\(minutes)分")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }
}
