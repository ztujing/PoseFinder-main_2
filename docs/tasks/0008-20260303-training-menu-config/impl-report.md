# Impl Report: training-menu-config

- **Date**: 2026-03-04
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0008](plan.md)
- **Status**: Done

## 1. 実装サマリ（What Changed）

- メニュー情報をソースコードから外部 JSON (`Resources/training-menus.json`) に移行
- `TrainingMenu` モデルに `videoFileName` フィールドを追加
- `TrainingMenuDataSource` プロトコルおよびローカル実装を追加しデータソースを抽象化
- `TrainingMenuRepository` を導入し DI により DataSource を差し替え可能に
- `HomeViewModel` を修正し、非同期で Repository からメニューを取得するよう変更
- `TrainingMenuDetailView` に参考動画プレイヤーを追加し、単一 `AVPlayer` で安定再生するよう修正
- `AppDelegate` にバンドル→Documents コピー処理を追加し、更新時に置換コピーするよう修正
- `PoseFinder.xcodeproj/project.pbxproj` の参照不整合・重複登録を修正し、`training-menus.json` をリソース登録
- テストコードを新規作成（DataSource/Repository/ViewModel）
- `docs/specs/structure.md` / `docs/specs/ui.md` を更新し構造および UI 仕様を反映
- ADR を新規作成（`docs/adr/0009-2026-03-03-training-menu-datasource-abstraction.md`）

## 2. 仕様の確定内容（Finalized Specs）

- `docs/specs/structure.md` にデータソース追加レイヤと移行手順を追記
- `docs/specs/ui.md` にメニュー詳細画面のビデオ再生仕様を追記
- `Resources/training-menus.json` をバンドルリソースとして読み込み・配布
- `TrainingMenuDetailViewModel.videoURL()` は `Documents` → `Bundle/videos` → `Bundle` の順で探索

## 3. 計画との差分（Deviation from Plan）

- 参照動画ファイル名は `squat-guide.mp4` などの想定名から、実在する `bg_blue.mp4` に統一
- 動画配布フォルダを `Resources/videos` 固定ではなく、既存のバンドル直下 mp4 もコピー対象とした

## 4. テスト結果（Evidence）

- ユニットテストファイルを3つ追加（`PoseFinderTests` ディレクトリ内）
- ビルド確認: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' ... build` が成功（BUILD SUCCEEDED）
- 手動確認:
  - HomeView で 3 メニュー表示
  - 詳細画面で動画再生（自動再生・無音）
  - Documents に `PoseFinderTrainingMenus/training-menus.json` と `videos/bg_blue.mp4` の配置を確認
  - `videoFileName` を存在しない名前にした場合、詳細画面でプレイヤー非表示かつクラッシュしないことを確認

## 5. 運用ノート（Operational Notes）

- JSON 差し替えはアプリ再インストール不要で、再起動時のコピー更新で反映可能
- 無効な `videoFileName` は UI で非表示にフォールバックし、機能停止しない設計

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）

- `PoseFinderTests` ターゲットの project 連携は未実施のため、CI 実行導線は次タスクで整備
- `HomeView` の `isLoading` / `errorMessage` 表示は未実装（ViewModel 側のみ実装済み）
- 将来のリモートデータソース（REST/Cloud DB）切替は別タスクで実施

## 7. 関連ドキュメント（Links）

- [PLAN-0008](plan.md)
- [TASKS-0008](tasks.md)
- [ADR-0009](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/docs/adr/0009-2026-03-03-training-menu-datasource-abstraction.md)
- [Structure Spec](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/docs/specs/structure.md)
- [UI Spec](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/docs/specs/ui.md)
