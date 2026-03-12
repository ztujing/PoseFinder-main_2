# IMPL-0009: 未完項目完了（MVP 完全化ステップ1）

- **Date**: 2026-03-09
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0009](docs/tasks/0009-20260306-mvp-completion/plan.md)
- **PRs**: なし（`main` へ fast-forward マージ）
- **Status**: Done

## 1. 実装サマリ（What Changed）

- UI テスト追加: `PoseFinderTests` / `PoseFinderUITests` に撮影完了遷移と Pose 同期表示のテストケースを追加。
- UI テスト安定化: 起動引数で UI テスト用セッションを自動投入し、`accessibilityIdentifier` ベースで判定可能にした。
- テスト基盤整備: `PoseFinderTests` ターゲットを追加し、`PoseFinder.xcscheme` の `TestAction` に `PoseFinderTests` を接続した。
- テスト設定整備: `PoseFinderTests` の `TEST_HOST` / `BUNDLE_LOADER` を確認し、デプロイターゲットを `15.6` に揃えた。
- テスト依存修正: `PoseFinderTests` に `Pods_PoseFinder.framework` と `Pods-PoseFinder.*.xcconfig` を適用し、`MLKit` 依存解決エラーを解消。
- テスト修正: `TrainingMenuRepositoryTests` の async 例外検証を `do/catch` 形式へ修正。
- ターゲット分離: `PoseFinderUITests` を専用 UI テストターゲットへ分離し、`XCTSkip` なしで実行する構成へ変更。
- UI テスト安定化: `CollectionView/Button` に合わせたクエリへ修正し、遷移導線と UI テストシード（pose.ndjson 末尾改行）を調整して 2 件を Green 化。
- specs 更新: ui.md に Pose 同期オーバーレイ追記、tech.md に座標系互換追記。
- DoD チェック: 0006/0007 のチェックリスト再実行・確認。
- リリースノート: `docs/release-notes.md` を新設し、0009 の反映内容を追記。

## 2. 仕様の確定内容（Finalized Specs）

- UI: セッション詳細で Pose 同期オーバーレイ表示。
- Tech: Pose 再生時の二分探索と座標変換。

## 3. 計画との差分（Deviation from Plan）

- テストターゲット/スキーム設定を追加したため、旧エラー（`Scheme PoseFinder is not currently configured for the test action.`）は解消した。
- `xcodebuild` は専用 `DerivedData` を使用して再実行する運用に変更した。
- リリースノートの格納先が未定だったため、共有ファイル `docs/release-notes.md` を新設した。
- PR 経由ではなく `main` へ fast-forward マージして完了した。

## 4. テスト結果（Evidence）

- UI テスト実行:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath /tmp/PoseFinderDerivedData-0009-test CODE_SIGNING_ALLOWED=NO test`
  - 日時: 2026-03-10
  - 結果: `PoseFinderTests` ビルド時に `Unable to find module dependency: 'MLKitPoseDetection'` / `Unable to find module dependency: 'MLKitVision'` で失敗（`** TEST FAILED **`）。
  - xcresult: `/tmp/PoseFinderDerivedData-0009-test/Logs/Test/Test-PoseFinder-2026.03.10_22-47-21-+0900.xcresult`
- UI テスト再実行（切り分け）:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0.1' -derivedDataPath /tmp/PoseFinderDerivedData-0009-test-ios17 CODE_SIGNING_ALLOWED=NO test`
  - 日時: 2026-03-10
  - 結果: 同一エラー（`MLKitPoseDetection` / `MLKitVision` 依存解決失敗）を再現。
  - xcresult: `/tmp/PoseFinderDerivedData-0009-test-ios17/Logs/Test/Test-PoseFinder-2026.03.10_22-51-37-+0900.xcresult`
- UI テスト再実行（修正後）:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0.1' -derivedDataPath /tmp/PoseFinderDerivedData-0009-test-fix3 CODE_SIGNING_ALLOWED=NO test`
  - 日時: 2026-03-11
  - 結果: `** TEST SUCCEEDED **`。Unit Test は全件成功（当時は `PoseFinderUITests` 2件を `XCTSkip`）。
  - xcresult: `/tmp/PoseFinderDerivedData-0009-test-fix3/Logs/Test/Test-PoseFinder-2026.03.11_12-35-49-+0900.xcresult`
- UI テスト専用ターゲット化後:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0.1' -derivedDataPath /tmp/PoseFinderDerivedData-0009-uitarget CODE_SIGNING_ALLOWED=NO test`
  - 日時: 2026-03-11
  - 結果: `PoseFinderUITests` は `XCTSkip` なしで実行開始できることを確認。2件とも要素未検出で失敗（`home.history.button` / `home.menu.row.0`）。
  - xcresult: `/tmp/PoseFinderDerivedData-0009-uitarget/Logs/Test/Test-PoseFinder-2026.03.11_13-04-26-+0900.xcresult`
- UI テスト再実行（最終）:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath /tmp/PoseFinderDerivedData-0009-uitarget-fix2 test -only-testing:PoseFinderUITests/PoseFinderUITests/testPoseSyncPlayback -only-testing:PoseFinderUITests/PoseFinderUITests/testRecordingCompletionNavigation`
  - 日時: 2026-03-11
  - 結果: `PoseFinderUITests` 2件とも成功（`** TEST SUCCEEDED **`）。
  - xcresult: `/tmp/PoseFinderDerivedData-0009-uitarget-fix2/Logs/Test/Test-PoseFinder-2026.03.11_15-29-18-+0900.xcresult`
- ビルド確認:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -destination-timeout 5 -derivedDataPath /tmp/PoseFinderDerivedData-0009-build-check CODE_SIGNING_ALLOWED=NO build`
  - 日時: 2026-03-10
  - 結果: `** BUILD SUCCEEDED **` を確認。
- 手動確認: 撮影完了遷移、Pose 同期表示を確認。
- DoD:
  - [x] 主要ユースケース自動化（UI テスト2件 Green）
  - [x] specs 更新
  - [x] リリースノート更新

## 5. 運用ノート（Operational Notes）

- `PoseFinder` スキームの `TestAction` には `PoseFinderTests` を接続済み。
- `xcodebuild` 実行時は `DerivedData` をジョブ単位で分離する。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）

- 長尺/高fpsセッション向けの Pose フレーム読み込み最適化。
- 計測（fps/latency/電力/温度）と OSLog 整備。

## 7. 関連ドキュメント（Links）

- 0006/0007 impl-report

## 8. 追記/正誤

- 2026-03-12: `docs/release-notes.md` を追加し、`Status` を `Done` へ更新。
