import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        List(viewModel.menus) { menu in
            NavigationLink(destination: TrainingMenuDetailView(viewModel: TrainingMenuDetailViewModel(menu: menu))) {
                TrainingMenuRow(menu: menu)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("トレーニングメニュー")
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
