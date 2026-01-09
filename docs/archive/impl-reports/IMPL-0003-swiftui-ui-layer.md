# IMPL-0003: SwiftUI移行フェーズ2（ホーム/メニューUI導入）

- **Date**: 2025-10-30
- **Owner**: @tujing
- **Related PLAN**: PLAN-0003-swiftui-ui-layer.md
- **PRs**: （未作成）
- **Status**: Done

## 1. 実装サマリ（What Changed）
- SwiftUI製のホーム画面 `HomeView` とトレーニングメニュー詳細 `TrainingMenuDetailView` を追加し、ダミーデータを `HomeViewModel` から供給。
- `TrainingMenuDetailView` から既存 UIKit 録画画面へ遷移する `RecordingSessionContainerView` を実装し、SwiftUI → UIKit の橋渡しを整備。
- `PoseFinderApp` のエントリポイントを更新し、通常は SwiftUI ナビゲーションスタックを表示、起動引数 `-UseLegacyUI` で従来 Storyboard を起動できる切替フラグを導入。
- `docs/specs/001_概要設計.md` と `docs/specs/002_画面遷移図.md` を更新し、SwiftUI 画面導入後の構成／遷移を反映。
- PLAN ドキュメント `docs/plans/PLAN-0003-swiftui-ui-layer.md` を作成。

## 2. 仕様の確定内容（Finalized Specs）
- **UI**: アプリ起動後は SwiftUI の `HomeView` を初期画面とし、メニュー選択 → `TrainingMenuDetailView` → `RecordingSessionContainerView`（UIKit `ViewController`）という遷移で録画を開始する。
- **データモデル**: `TrainingMenu`（ID/タイトル/説明/チェックポイント/所要時間）を導入し、ViewModel 経由で View へ供給。将来的なデータソース置き換えを見据え ObservableObject で構造化。
- **ナビゲーション**: iOS 16 以上では `NavigationStack`、それ以前は `NavigationView` を使用し、戻る操作で問題なく SwiftUI スタックへ復帰できることを確認済み。

## 3. 計画との差分（Deviation from Plan）
- Plan で想定した範囲内で実装完了。ダミーデータ提供・UIKit 録画画面のラップ共に計画通り。
- ViewModel のテスト整備は次フェーズで検討（現状は手動検証のみ）。

## 4. テスト結果（Evidence）
- 手動テスト:
  - ホーム → メニュー詳細 → 録画画面 → 戻る、までの遷移が期待通り動作。
  - 録画画面での撮影・保存フローは既存機能として継続動作（クラッシュなし）。
- 自動テスト: 未実施（今フェーズでは UI 手動検証で確認）。
- 受入基準（DoD）:
  - [x] SwiftUI 画面から既存録画画面へ到達し録画完了まで動作する
  - [ ] 主要ユースケース自動化
  - [ ] OpenAPI/Storybook 反映（今回該当なし）
  - [ ] 監視・アラート整備
  - [ ] リリースノート更新

## 5. 運用ノート（Operational Notes）
- フラグ: 起動引数 `-UseLegacyUI` を付けることで従来 Storyboard を利用可能（デバッグ・ロールバック用途）。
- 環境変数・Secrets: 追加なし。
- ロールバック: `PoseFinderApp` を `LegacyRootView` のみ表示する構成に戻し、新規 SwiftUI View/Model をターゲットから外せば従来 UI に復旧可。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）
- メニュー一覧はダミーデータ。永続化や外部データ連携を実装する場合は Repository 層の導入が必要。
- ViewModel の単体テスト／Snapshot テスト未整備。
- 録画画面の SwiftUI 化は未着手（PLAN-0004 以降で検討）。

## 7. 関連ドキュメント（Links）
- `docs/plans/PLAN-0003-swiftui-ui-layer.md`
- `docs/specs/001_概要設計.md`
- `docs/specs/002_画面遷移図.md`
- `docs/impl-reports/IMPL-0002-swiftui-wrapper.md`

## 8. 追記/正誤
- なし
