# PLAN-0004: SwiftUI移行フェーズ3（セッション詳細・再生UI）

- **Date**: 2025-10-30
- **Owner**: @tujing
- **Scope**: FE | Docs
- **Status**: Draft

## 1. 背景 / 目的（Context & Goals）
- フェーズ2で SwiftUI 製ホーム/メニュー詳細→既存録画画面への遷移を整備したが、録画後のセッション確認は依然として UIKit 依存のまま。
- ユーザーが撮影後すぐにフォーム確認を行えるよう、SwiftUI ベースのセッション詳細画面（動画＋Pose オーバーレイ再生、メタ情報の表示）を実装し、再生体験をモダンな UI へ移行する。
- ゴール:
  - 録画済みセッション一覧から選択されたデータを SwiftUI で再生・閲覧できる画面を提供。
  - セッションメタ情報（撮影日時・保存パス・動画/ポーズファイル情報など）を表示。
  - Pose オーバーレイ再生に向けた最小ラッパーを用意し、既存描画ビューを SwiftUI へ取り込む土台を作る。

## 2. 非目標（Non-Goals）
- Pose オーバーレイ描画の SwiftUI Canvas への移行（今回は UIKit ビューのラップまで）。
- セッション一覧機能の完全刷新（ホーム/詳細画面との連携は最小限の導線追加に留める）。
- クラウド同期や外部ストレージ連携。
- 撮影ロジック・ファイル保存の再設計。

## 3. 影響範囲（Impact）
- **UI**: 新規 SwiftUI View（`SessionDetailView` 等）追加、既存ルートからの遷移拡張。
- **Docs**: 概要設計 / 画面遷移図更新、Plan/Impl Report 追加。
- **データ/ストレージ**: `Documents/Sessions/<sessionId>/` 配下の読み込み処理を整備。ファイル I/O アクセスの整理（エラーハンドリング）。
- **テスト/リリース**: 撮影→保存→再生までのフローを再検証。既存 Storyboard セッション詳細との共存確認。

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）
- **A: UIKit セッション再生画面をラップする（採用案）**
  - 利点: 既存 PoseImageView や AVPlayer のロジックを再利用できる。SwiftUI への移行を段階的に進められる。
  - 欠点: UIKit/SwiftUI のハイブリッドが継続し、状態管理が複雑。
- **B: 完全に SwiftUI + AVPlayer + Canvas で再実装**
  - 利点: 統一された状態管理と UI。将来的な拡張性が高い。
  - 欠点: Pose オーバーレイの描画ロジックを書き直す必要があり、リスク・工数が大きい。
- **C: Storyboard 画面をそのまま利用し、SwiftUI から遷移だけ提供**
  - 利点: 追加実装が最小限。
  - 欠点: SwiftUI 移行が進まず、UX/設計が二重化されたまま。
- 採用理由: フェーズ分割の方針に合わせ、UIKit ラップでリスクを抑えながら SwiftUI 側に UI を構築する。

## 5. 実装方針（Design Overview）
- データモデル:
  - `RecordingSession`（ID、日時、保存パス、動画/ポーズファイル情報）を導入。
  - `SessionRepository` 的コンポーネントで `Documents/Sessions/` からメタ情報を読み込む。
- View / ViewModel 構成:
  - `SessionDetailViewModel`: 選択されたセッションのメタ情報と再生状態を管理。
  - `SessionDetailView`: SwiftUI で構築。動画再生エリア、Pose オーバーレイ、メタ情報表示、削除/再撮影アクション（任意）。
  - Pose オーバーレイは当面 UIKit `PoseImageView`/`PlayerView` を `UIViewRepresentable` で包む（既存 `PlayerView` の再利用）。
- 遷移:
  - ホーム/メニュー詳細からセッション一覧へ導線を用意（簡易リスト or ダイアログ）。
  - セッション選択で `SessionDetailView` をプッシュ表示。
- エラーハンドリング:
  - ファイルが存在しない / 読み込み失敗時にはエラービューを表示。
  - 既存録画画面で生成されるファイル構成を前提としつつ、将来のスキーマ変更にも対応できる構造にする。

## 6. 実装手順（Implementation Steps）
1. `docs/plans/PLAN-0004-session-detail.md`（本ドキュメント）を Draft として追加。
2. `RecordingSession` モデルと `RecordingSessionRepository`（仮称）を実装。`Documents/Sessions/` のスキャンとメタ情報読み込みを行う。
3. Pose/動画再生用のブリッジコンポーネント（`PosePlayerContainerView` 等）を作成し、既存 UIKit ビューをラップ。
4. `SessionDetailViewModel` / `SessionDetailView` を実装。動画再生・Pose オーバーレイ・メタ情報表示。
5. SwiftUI ルートからセッション詳細へ遷移できる導線を追加（ホーム or メニュー詳細に「履歴」ボタン等）。
6. 実機/シミュレータで録画→保存→セッション詳細表示→戻るまでを手動テスト。
7. `docs/specs/001_概要設計.md` / `docs/specs/002_画面遷移図.md` を更新。
8. 実装結果を `docs/impl-reports/IMPL-0004-session-detail.md` に記録。
9. Plan レビューで Approved 取得後、実装ブランチを main へ統合。

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）
- 手動テスト:
  - ホーム → セッション履歴 → 選択 → SwiftUI セッション詳細で動画/オーバーレイ確認。
  - ファイル欠損時のエラー表示を確認。
- 自動テスト:
  - Repository のファイル読み込みロジックに対する単体テスト（ダミーディレクトリを用意）。
- 受入基準（DoD）:
  - [ ] SwiftUI 画面で録画済みセッションの動画と Pose オーバーレイを再生できる。
  - [ ] セッションメタ情報（日時/ファイルパス/サイズ等）が表示される。
  - [ ] ファイル欠損時にクラッシュせずエラーメッセージを表示する。
  - [ ] Docs（概要設計・画面遷移図・Impl Report）が更新されている。

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）
- ロールバック: SwiftUI セッション詳細をビルド対象から外し、既存 Storyboard のセッション詳細へ導線を戻す。
- リスク:
  - ファイル読み込み失敗時のエラーハンドリング不足 → 明示的なエラービューで緩和。
  - オーバーレイ表示で UIKit/SwiftUI の同期が乱れる可能性 → Coordinator パターンで状態を同期。
  - 動画再生リソースの開放漏れ → `onDisappear` 等で AVPlayer の停止を実装。
- 監視: 本フェーズでは追加なし。将来的にはクラッシュログ/利用状況トラッキングを検討。

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）
- `docs/impl-reports/IMPL-0004-session-detail.md`
- `docs/specs/001_概要設計.md`
- `docs/specs/002_画面遷移図.md`
- SwiftUI ビュー構成やプレイヤーラップに関する補足資料（必要に応じて）

## 10. 参照（References）
- PLAN-0003: `docs/plans/PLAN-0003-swiftui-ui-layer.md`
- IMPL-0003: `docs/impl-reports/IMPL-0003-swiftui-ui-layer.md`
- Apple Docs: [AVPlayer](https://developer.apple.com/documentation/avkit/avplayer)
- Apple Docs: [UIViewRepresentable / Coordinator パターン](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
