# PLAN-0003: SwiftUI移行フェーズ2（ホーム/メニューUI導入）

- **Date**: 2025-10-30
- **Owner**: @tujing
- **Scope**: FE | Docs
- **Status**: Draft

## 1. 背景 / 目的（Context & Goals）
- フェーズ1では SwiftUI エントリポイントを導入しつつ既存 Storyboard 画面を SwiftUI から起動できる状態まで整備した。
- 次段として、ユーザーが最初に触れるホーム画面とトレーニングメニュー詳細を SwiftUI で実装し、以降の画面遷移を SwiftUI 主導へ段階的に移行する必要がある。
- ゴール:
  - SwiftUI でホーム画面（メニュー一覧）とトレーニングメニュー詳細画面を実装する。
  - トレーニングメニュー詳細から既存録画画面（UIKit `ViewController`）へナビゲーションできるよう統合する。
  - 画面遷移や状態管理の基盤（NavigationStack / ViewModel）を整備し、後続フェーズでの SwiftUI 化を容易にする。

## 2. 非目標（Non-Goals）
- 録画画面（既存 ViewController）の SwiftUI ネイティブ化や UI リデザイン。
- Pose オーバーレイや録画ロジックの再実装。
- セッション保存/一覧機能の完全移行（今回はダミーデータまたは既存のデータ源に限定）。
- Storyboard 全面撤廃。

## 3. 影響範囲（Impact）
- **UI**: 新規 SwiftUI 画面（HomeView, TrainingMenuDetailView など）の追加、NavigationStack 構成、UIKit 画面への遷移ハンドリング。
- **Docs**: 概要設計/画面遷移図への更新、Plan/Impl Report の追加。
- **API/DB**: 変更なし（ローカルデータ/ダミーモデルで対応）。
- **運用/リリース**: 既存 Storyboard 画面との共存を継続。デプロイターゲットは前フェーズで iOS 15.0 へ更新済み。

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）
- **A: SwiftUI ナビゲーションのみ先行導入（採用案）**
  - 利点: 既存 UIKit 画面を活用しつつ SwiftUI 画面を積み増せる。移行リスクが低い。
  - 欠点: SwiftUI と UIKit が混在し、状態管理が複雑になり得る。
- **B: 録画画面を含む全面 SwiftUI 化を同時実施**
  - 利点: 状態・ライフサイクルを SwiftUI に統一できる。
  - 欠点: AVFoundation/Ros まわりの大幅な書き換えが必要で、スケジュール・リスクが高い。
- 採用理由: フェーズ分割の方針に従い、段階的移行でリスクを制御する。

## 5. 実装方針（Design Overview）
- `PoseFinderApp` の `WindowGroup` 内で SwiftUI の `NavigationStack` を構築し、ホーム → メニュー詳細 → 既存録画画面 という遷移を定義。
- データモデル:
  - `TrainingMenu`（ID, 表示名, サムネイル, 説明など）を定義し、当面はスタティックなダミーデータを ViewModel で提供。
- View 構成:
  - `HomeView`: メニュー一覧表示、詳細への遷移を提供。
  - `TrainingMenuDetailView`: メニュー情報表示と「撮影を開始」ボタンを配置。ボタン押下時に `RecordingSessionContainerView`（UIKit ラッパー）へ遷移。
  - `RecordingSessionContainerView`: 既存 `ViewController` を `UIViewControllerRepresentable` で包むラッパーを新規実装（PLAN-0002 の拡張）。
- 状態管理:
  - `HomeViewModel` / `TrainingMenuDetailViewModel` を `ObservableObject` として定義し、メニューリストや選択状態を集中管理。
- 既存 Storyboard は `LegacyRootView` からではなく、SwiftUI ナビゲーションの最終地点として利用（将来的に順次置き換え）。

## 6. 実装手順（Implementation Steps）
1. `docs/plans/PLAN-0003-swiftui-ui-layer.md` を Draft として作成（本ドキュメント）。
2. データモデル/ラッパー/ビュー/ビューModel のファイルスケルトンを `PoseFinder/App` 配下に追加。
3. `HomeView` と `TrainingMenuDetailView` の UI コンポーネントを実装し、ダミーデータで一覧表示ができるようにする。
4. `RecordingSessionContainerView` を実装し、既存 `ViewController` を SwiftUI から起動できるよう `Coordinator`/delegate を整備。
5. `PoseFinderApp` を更新し、`NavigationStack` を構築して新規 SwiftUI 画面をルートに据える。
6. Storyboard 初期画面経由の起動が不要になった場合は `LegacyRootView` をオプション化し、テスト時に切り替えられるよう調整。
7. 単体/結合テストおよび実機検証でホーム→詳細→録画の流れを確認。
8. Docs 更新（概要設計・画面遷移図・Impl Report など）。
9. Plan レビュー→Approved 取得後に実装へ移行。

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）
- 手動テスト:
  - シミュレータ/実機でホーム → メニュー詳細 → 録画画面まで遷移し、既存録画機能が動作することを確認。
- 単体テスト:
  - ViewModel のデータ供給ロジックを重点的にテスト（必要に応じて Snapshot テストを検討）。
- UI テスト（任意）:
  - SwiftUI 画面のボタン操作で正しい画面遷移が起こることを確認。
- DoD チェック:
  - [ ] SwiftUI 画面から既存録画画面へ到達でき、録画完了まで動作する。
  - [ ] 主要 ViewModel の単体テストが追加されている。
  - [ ] Docs（概要設計/画面遷移図/Impl Report）が最新化されている。
  - [ ] リリースノート草案を追記。

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）
- ロールバック: `PoseFinderApp` を `LegacyRootView` のみ表示する構成に戻し、新規 SwiftUI 画面をビルド対象から外す。
- リスク:
  - SwiftUI → UIKit への遷移時にナビゲーション戻り操作が不整合になる可能性（→ Coordinator で録画終了時の状態戻しを制御）。
  - ダミーデータ前提の ViewModel が将来の永続化実装と乖離するリスク（→ プロトコル抽象化で将来差し替え可能にする）。
- 監視: 本フェーズでは新規メトリクスなし。クラッシュログ等の基本的な監視のみ。

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）
- Implementation Report: `docs/impl-reports/IMPL-0003-swiftui-ui-layer.md`
- `docs/specs/001_概要設計.md`（SwiftUI 画面構造の更新）
- `docs/specs/002_画面遷移図.md`（ホーム→詳細→録画の遷移図更新）
- 必要に応じて SwiftUI コンポーネントの設計資料

## 10. 参照（References）
- PLAN-0002: `docs/plans/PLAN-0002-swiftui-wrapper.md`
- IMPL-0002: `docs/impl-reports/IMPL-0002-swiftui-wrapper.md`
- Apple Docs: [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- Apple Docs: [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
