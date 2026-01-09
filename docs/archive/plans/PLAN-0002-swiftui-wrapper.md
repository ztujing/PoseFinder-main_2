# PLAN-0002: SwiftUI移行フェーズ1（UIKitラップ）

- **Date**: 2025-10-20
- **Owner**: @tujing
- **Scope**: FE | Docs
- **Status**: Draft

## 1. 背景 / 目的（Context & Goals）
- 既存アプリは Storyboard + UIKit ベースで撮影・再生機能を実装済み。今後の機能拡張／UI 改修を見据え、SwiftUI へ段階的に移行したい。
- Phase 1 では既存の録画・Pose 描画ロジック（`ViewController`／`RecordingSessionManager`／`PoseImageView`）を SwiftUI へラップし、SwiftUI のレイアウト／ナビゲーション基盤を整えることをゴールとする。
- 具体的には、撮影画面・再生画面の SwiftUI ルート構築、UIKit コンポーネントの `UIViewControllerRepresentable`／`UIViewRepresentable` 化、状態/通知の橋渡しを行う。

## 2. 非目標（Non-Goals）
- SwiftUI による完全な再実装（Canvas/Shape での描画リライト、AVFoundation の SwiftUI ネイティブ化）は対象外（フェーズ2以降で検討）。
- Core ロジック（`RecordingSessionManager`、`PoseSerialization`）の挙動変更。
- アプリ全画面の一括移行。今回は撮影画面と周辺ナビゲーションを中心に扱う。

## 3. 影響範囲（Impact）
- UI: SwiftUI ベースの画面構成導入、NavigationStack などを用いた遷移管理。
- Docs: 概要設計 / 画面遷移図に SwiftUI 化の段階を追記（必要に応じて）。
- API/DB/Backend: 変更なし。
- ビルド設定: SwiftUI エントリーポイント追加に伴うターゲット設定の確認。
- テスト/運用: UI テスト観点の更新、Storyboard との共存状態の確認。

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）
- **A: UIKit ラップ方式（採用）**
  - 利点: 既存コードを最大限再利用、短期間で SwiftUI 化の足掛かりを整備。リスク低。
  - 欠点: SwiftUI と UIKit の状態二重管理が発生、SwiftUI ネイティブの利点を活かし切れない。
- **B: SwiftUI ネイティブで再実装**
  - 利点: 状態管理や描画を SwiftUI 流に統一でき、将来的な拡張性が高い。
  - 欠点: AVFoundation や Pose 描画の書き直しコストが高く、移行期間が長期化。
- 選定理由: まず安全に SwiftUI 基盤を導入し、徐々にネイティブ化する段階的戦略が実装コストとリスクのバランスが良い。

## 5. 実装方針（Design Overview）
- アプリエントリ: SwiftUI の `App` 構造体を導入し、必要に応じて既存 Storyboard 起動と切り替えられる状態にする。
- 撮影画面: `RecordingViewController`（既存 `ViewController`）を `UIViewControllerRepresentable` でラップした `RecordingSessionContainerView` を作成し、SwiftUI から `start/stop` などのコマンドを発行できるよう `Coordinator` を実装。
- Pose オーバーレイ: 現状の `PoseImageView` を `UIViewRepresentable` として SwiftUI に組み込む（フェーズ2で Canvas 化を検討）。
- ナビゲーション: SwiftUI の `NavigationStack`（または `NavigationSplitView`）を追加し、ホーム → 撮影 → セッション詳細の遷移を管理。Storyboard 上の遷移は段階的に無効化。
- 状態同期: SwiftUI 側で `@StateObject` / `ObservableObject` を用いて、録画状態・保存ディレクトリなどを ViewModel に集約。UIKit 側は `delegate` や `NotificationCenter` 経由で状態更新を通知。

## 6. 実装手順（Implementation Steps）
1. `feature/0002-swiftui-wrapper` ブランチを作成。
2. SwiftUI エントリポイント（`PoseFinderApp.swift`）を追加し、既存 AppDelegate との共存を整理。
3. 既存 `ViewController` を `UIViewControllerRepresentable` で包むラッパー `RecordingSessionContainerView` を作成。
4. `RecordingSessionContainerView` と連携する `RecordingSessionViewModel`（`ObservableObject`）を追加し、録画状態や保存先パスを SwiftUI 側で管理。
5. SwiftUI ベースの画面構成を新規作成（例: `HomeView`, `RecordingRootView`, `SessionDetailView`）。初期表示は新 SwiftUI ルートへ遷移。
6. 既存 Storyboard の撮影画面へのエントリを停止し、SwiftUI 側から `RecordingSessionContainerView` を呼び出すよう移行。
7. `PoseImageView` を `UIViewRepresentable` 化して SwiftUI View から利用できるよう調整（最小限のラップ）。
8. ビルド・実機検証で録画～保存までのフローが維持されていることを確認。
9. Docs 更新（必要なら `docs/specs/001_概要設計.md` 等へ段階的移行の補足を追記）。
10. PLAN をレビュー → Approved 後、実装開始。

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）
- 手動テスト: SwiftUI ベース UI から撮影→保存→セッション確認まで実施し、保存ファイルが従来通り生成されること。
- SwiftUI プレビュー: 主要 View（HomeView, RecordingRootView）のプレビュー確認。
- UI テスト（任意）: 撮影ボタンの操作が想定通りのライフサイクルを呼ぶかを確認。
- DoD:
  - [ ] SwiftUI ルートから録画フローを開始・完了できる。
  - [ ] 保存先ログが表示され、`video.mp4`/`pose.ndjson`/`session.json` が生成される。
  - [ ] 主要 SwiftUI View にテストしやすい状態（ViewModel など）が導入されている。
  - [ ] 関連ドキュメント（概要設計等）が更新されている場合、その記録を残す。

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）
- ロールバック: SwiftUI ルートの起動を停止し、既存 Storyboard 入口に戻す。`RecordingSessionContainerView` 導入前のブランチへ戻す。
- リスク:
  - UIKit/SwiftUI の二重状態管理による同期ズレ（→ ViewModel と Coordinator を介して単一情報源に揃える）。
  - SwiftUI エントリ導入時の AppDelegate / SceneDelegate 周りの競合（→ ビルドターゲット設定を確認し、必要に応じて SceneDelegate へ移行）。
  - 標準の `NavigationStack` での戻り動作と既存ロジックの整合性（→ SwiftUI 側で `onDisappear` を利用し停止処理を保証）。
- 監視: 開発段階では Xcode ログで保存先・エラーを監視。本番導入後はクラッシュログ/analytics を検討。

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）
- Implementation Report: `docs/impl-reports/IMPL-0002-swiftui-wrapper.md`
- 仕様更新: 必要に応じて `docs/specs/001_概要設計.md` / `docs/specs/002_画面遷移図.md`
- 図表: 新しい SwiftUI 画面構造があれば mermaid 図を追記

## 10. 参照（References）
- PLAN-0001: `docs/plans/PLAN-0001-video-and-pose-json.md`
- 概要設計: `docs/specs/001_概要設計.md`
- 画面遷移図: `docs/specs/002_画面遷移図.md`
- Apple Docs: [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
- Apple Docs: [Integrating SwiftUI views into UIKit](https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit)
