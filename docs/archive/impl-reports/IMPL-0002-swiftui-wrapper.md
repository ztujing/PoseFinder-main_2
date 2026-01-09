# IMPL-0002: SwiftUI移行フェーズ1（UIKitラップ）

- **Date**: 2025-10-30
- **Owner**: @tujing
- **Related PLAN**: PLAN-0002-swiftui-wrapper.md
- **PRs**: （未作成）
- **Status**: Done

## 1. 実装サマリ（What Changed）
- `PoseFinder/App/PoseFinderApp.swift` を新規追加し、`@main` を付与した SwiftUI `App` から既存 Storyboard 初期画面を `UIViewControllerRepresentable` で起動できるようにした。
- `AppDelegate` を `@UIApplicationDelegateAdaptor` でラップできるよう `@UIApplicationMain` を削除し、SwiftUI エントリポイントとの競合を解消した。
- `PoseFinder.xcodeproj/project.pbxproj` に `PoseFinderApp.swift` を登録し、ビルドターゲットへ組み込んだ。
- `Podfile` / `Podfile.lock` の iOS デプロイターゲットを 15.0 に更新し、`README.md` を SwiftUI 化の足掛かりに合わせて整理した。
- `docs/plans/PLAN-0002-swiftui-wrapper.md` を追加し、フェーズ1の意図と手順を記録した。

## 2. 仕様の確定内容（Finalized Specs）
- **UI**: アプリのエントリポイントは SwiftUI `PoseFinderApp` → `LegacyRootView` → Storyboard 初期 `UIViewController` という階層を採用。SwiftUI から UIKit 画面を安全にラップし、今後の SwiftUI 画面差し替えに備える。
- **API / DB**: 変更なし。

## 3. 計画との差分（Deviation from Plan）
- README の大幅更新（現状は Xcode プロジェクト構成を直接出力する内容）について PLAN では触れておらず、ドキュメント整理の追加作業が必要。→ Known Issues に記載し、別タスクで整備予定。
- DoD で想定していた SwiftUI ViewModel や Pose オーバーレイのラップは未着手。フェーズ2以降に扱う。

## 4. テスト結果（Evidence）
- 手動テスト: iOS 実機でアプリをビルド・起動し、SwiftUI エントリポイントから既存撮影画面が表示されることを確認（クラッシュ・エラーなし）。
- 自動テスト: 未実施（このフェーズでは UI 差し替えのみのため）。
- 受入基準（DoD）:
  - [x] SwiftUI ルートから録画フローを開始・完了できる
  - [ ] 主要 SwiftUI View のテスト容易性（ViewModel 化）
  - [ ] OpenAPI / Storybook 反映
  - [ ] 監視・アラート整備

## 5. 運用ノート（Operational Notes）
- 設定/環境変数の追加なし。
- ロールバック時は `PoseFinderApp.swift` を無効化し、`@UIApplicationMain` を復元すれば従来の Storyboard 起動に戻せる。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）
- README.md の内容が Xcode プロジェクト定義を丸ごと含む状態になっており、利用者向けドキュメントとして読みづらい。要再構成（別 Issue 化予定）。
- SwiftUI 用 ViewModel / `PoseImageView` ラップの実装が未完。PLAN-0002 の残作業としてフェーズ2で着手。

## 7. 関連ドキュメント（Links）
- `docs/plans/PLAN-0002-swiftui-wrapper.md`
- `docs/specs/001_概要設計.md`
- `docs/specs/002_画面遷移図.md`

## 8. 追記/正誤
- なし
