                                            # IMPL-0009: 未完項目完了（MVP 完全化ステップ1）

- **Date**: 2026-03-09
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0009](docs/tasks/0009-20260306-mvp-completion/plan.md)
- **PRs**: -
- **Status**: Partially Done

## 1. 実装サマリ（What Changed）

- UI テスト追加: PoseFinderTests/PoseFinderUITests.swift に撮影完了遷移と Pose 同期表示のテストケースを追加。
- UI テスト安定化: 起動引数で UI テスト用セッションを自動投入し、`accessibilityIdentifier` ベースで判定可能にした。
- テスト基盤整備: `PoseFinderTests` ターゲットを追加し、`PoseFinder.xcscheme` の `TestAction` に `PoseFinderTests` を接続した。
- テスト設定整備: `PoseFinderTests` の `TEST_HOST` / `BUNDLE_LOADER` を確認し、デプロイターゲットを `15.6` に揃えた。
- specs 更新: ui.md に Pose 同期オーバーレイ追記、tech.md に座標系互換追記。
- DoD チェック: 0006/0007 のチェックリスト再実行・確認。
- 未完: `xcodebuild test` の完走ログ採取、リリースノート更新。

## 2. 仕様の確定内容（Finalized Specs）

- UI: セッション詳細で Pose 同期オーバーレイ表示。
- Tech: Pose 再生時の二分探索と座標変換。

## 3. 計画との差分（Deviation from Plan）

- テストターゲット/スキーム設定を追加したため、旧エラー（`Scheme PoseFinder is not currently configured for the test action.`）は解消した。
- `xcodebuild` は専用 `DerivedData` を使用して再実行する運用に変更した。

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
- ビルド確認:
  - コマンド: `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -destination-timeout 5 -derivedDataPath /tmp/PoseFinderDerivedData-0009-build-check CODE_SIGNING_ALLOWED=NO build`
  - 日時: 2026-03-10
  - 結果: `** BUILD SUCCEEDED **` を確認。
- 手動確認: 撮影完了遷移、Pose 同期表示を確認。
- DoD:
  - [ ] 主要ユースケース自動化（`xcodebuild test` の完走証跡追記が未完）
  - [x] specs 更新
  - [ ] リリースノート更新（次タスク）

## 5. 運用ノート（Operational Notes）

- `PoseFinder` スキームの `TestAction` には `PoseFinderTests` を接続済み。
- `xcodebuild` 実行時は `DerivedData` をジョブ単位で分離する。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）

- `PoseFinderTests` の `MLKitPoseDetection` / `MLKitVision` 依存解決失敗を解消し、`xcodebuild test` を完走させる。
- リリースノート更新。

## 7. 関連ドキュメント（Links）

- 0006/0007 impl-report

## 8. 追記/正誤
