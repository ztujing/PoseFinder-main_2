# PLAN-0006: Recording 完了後に SessionDetail へ自動遷移

- **Date**: 2026-01-19
- **Owner**: @tujing
- **Scope**: FE
- **Status**: Approved

## 1. 背景 / 目的（Context & Goals）

現状の導線では、撮影が完了してもユーザーが「履歴」から該当セッションを探して詳細を開く必要があり、MVP の主要ジャーニー（撮影→保存→確認）の完遂に手戻りが発生する。

`docs/specs/ui.md` の遷移（`Recording -> SessionDetail`）に合わせ、**撮影の正常完了時に新規セッションの詳細画面へ自動遷移**できるようにする。

ゴール（DoD の観点）:

- 撮影完了後に、保存された「当該セッション」の `SessionDetail` が自動で開く
- `SessionDetail` で動画再生と Pose 先頭フレームプレビューが表示できる（既存実装を利用）
- 戻る操作で録画画面に戻らず、トレーニングメニュー詳細へ戻れる（ナビゲーションスタックの自然さ）
- iOS 15（`NavigationView`）/ iOS 16+（`NavigationStack`）の両方で同等に動作する

## 2. 非目標（Non-Goals）

- Pose と動画のフレーム完全同期（`docs/specs/tech.md` の既知課題）
- 採点ロジックの改善、フォームフィードバック、UI の大規模改修
- セッション保存スキーマの変更（`session.json` / `pose.ndjson` の互換性変更）
- ナビゲーション全体の刷新（Coordinator 導入、`NavigationPath` 化など）

## 3. 影響範囲（Impact）

- UI:
  - 撮影画面（SwiftUIラッパー）: `PoseFinder/App/Views/RecordingSessionContainerView.swift`
  - トレーニングメニュー詳細: `PoseFinder/App/Views/TrainingMenuDetailView.swift`
  - セッション詳細: `PoseFinder/App/Views/SessionDetailView.swift`（原則は既存利用）
- UIKit:
  - 撮影本体の完了イベント: `PoseFinder/UI/ViewController.swift`
- 永続化 / I/O:
  - 読み込みは既存 `RecordingSessionRepository` を利用（`PoseFinder/App/Repositories/RecordingSessionRepository.swift`）
- ドキュメント:
  - 必要に応じて `docs/specs/ui.md` に「完了時は自動遷移する」旨を追記（矛盾がない範囲で最小）

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）

- 代替案A: 現状維持（ユーザーが履歴から探す）
  - 利点: 実装なし
  - 欠点: MVP ジャーニーが途切れる、初見で「保存できたのか？」が分かりにくい
  - 却下理由: MVP を早く出す上で体験の悪さが目立つ

- 代替案B: 完了後にセッション一覧（`SessionList`）へ遷移
  - 利点: 実装が比較的簡単、当該セッションを視認できる
  - 欠点: 目的（詳細での即時確認）まで 1 アクション残る、一覧が空/未更新のタイミング差が出る
  - 却下理由: `docs/specs/ui.md` の想定（`Recording -> SessionDetail`）とずれる

- 代替案C: グローバルなナビゲーション状態（Coordinator/Router）を導入して遷移を統一
  - 利点: 将来拡張に強い
  - 欠点: MVP に対して過剰、影響範囲が大きい
  - 却下理由: 早期リリース優先のため、局所的変更で達成する

採用（本案）:

- 完了イベントに **directoryURL（セッション保存先）** を紐付けて SwiftUI 側へ渡し、`SessionDetail` を直接開く。

## 5. 実装方針（Design Overview）

### 5.1 イベントフロー

1. UIKit 撮影画面（`ViewController`）が録画停止を完了し、セッションの `directoryURL` を確定する
2. `NotificationCenter` で `.recordingSessionDidComplete` を **`userInfo` 付き**で通知する
   - `userInfo["directoryURL"] = directoryURL`
3. SwiftUI 側（`RecordingSessionScreen`）が通知を受ける
4. `RecordingSessionRepository.reloadSession(at:)` で `RecordingSession` を読み込み、成功したら:
   - 録画画面を `dismiss()` で閉じる
   - 親画面（メニュー詳細）へ「完了したセッション」を渡し、`SessionDetailView` へプログラム遷移する

### 5.2 ナビゲーション設計（iOS 15 / iOS 16+ 両対応）

- 親（`TrainingMenuDetailView`）側に、`SessionDetailView` への遷移トリガー（`@State`）を持たせる
- 子（`RecordingSessionScreen`）は、完了時に「セッション情報」をコールバックで親へ返し、`dismiss()` する
- これにより「詳細から戻ると録画画面に戻ってしまう」を避ける

## 6. 実装手順（Implementation Steps）

1. 完了通知に `directoryURL` を含める
   - 対象: `PoseFinder/UI/ViewController.swift`
   - `.recordingSessionDidComplete` の `userInfo` に `directoryURL` を設定

2. `RecordingSessionScreen` に完了コールバックを追加し、通知から `RecordingSession` を復元する
   - 対象: `PoseFinder/App/Views/RecordingSessionContainerView.swift`
   - `onCompleted: (RecordingSession) -> Void`（もしくは `URL`）を追加
   - `.recordingSessionDidComplete` 受信時に `RecordingSessionRepository` で読み込み → 成功で `dismiss` → コールバック実行
   - 読み込み失敗時は **短い遅延で 1 回だけ再試行** する
   - 再試行でも失敗した場合は **自動遷移を行わずメニュー詳細へ戻す**（必要なら簡易アラートで「履歴から確認」を案内）

3. `TrainingMenuDetailView` から `RecordingSessionScreen` を起動し、完了時に `SessionDetailView` へ遷移させる
   - 対象: `PoseFinder/App/Views/TrainingMenuDetailView.swift`
   - 隠し `NavigationLink` / `navigationDestination`（OS 分岐）で詳細へ遷移

4. 既存の一覧更新（`.recordingSessionDidComplete` 監視）に影響がないことを確認する
   - 対象: `PoseFinder/App/ViewModels/SessionListViewModel.swift`

5. （必要なら）`docs/specs/ui.md` を最小更新
   - 「完了時は自動でセッション詳細へ遷移する」を明文化（現状の図と矛盾しない範囲）

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）

手動テスト（端末/シミュレータ）:

- [ ] メニュー詳細 → 撮影開始 → 撮影が最後まで完了したら自動で `SessionDetail` が開く
- [ ] `SessionDetail` で動画が再生され、Pose プレビューが表示される（既存機能の確認）
- [ ] `SessionDetail` の戻るでメニュー詳細へ戻る（録画画面に戻らない）
- [ ] 録画中に「戻る」→「中断する」を選ぶと保存されず、詳細へ遷移しない
- [ ] 取得失敗時は 1 回だけ再試行し、再失敗時は自動遷移せずメニュー詳細へ戻る（必要なら簡易アラートを表示）
- [ ] iOS 15 / iOS 16+ で同等の動作になる（少なくとも手元の主要ターゲットで確認）

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）

- ロールバック:
  - 通知の `userInfo` 付与と SwiftUI 側の遷移ロジックを取り除き、現状の手動導線へ戻す
- リスク:
  - 完了直後にメタ情報読み込みが間に合わず、遷移先で欠損扱いになる
    - 軽減: 完了通知は `session.json` 書き込み完了後に発火する（現状の `stop` 完了後）。短い遅延で 1 回だけ再試行する
  - 通知が複数回発火して多重遷移する
    - 軽減: SwiftUI 側で 1 回のみ処理するガードを入れる（状態フラグ）

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）

- `docs/tasks/0006-20260119-recording-to-session-detail/impl-report.md`
- （必要なら）`docs/specs/ui.md`（今回の変更で体験が変わる箇所）
- ADR: 不要（局所的 UI 導線改善のため）

## 10. 参照（References）

- `docs/specs/ui.md`
- `docs/specs/structure.md`
- `PoseFinder/UI/ViewController.swift`
- `PoseFinder/App/Views/RecordingSessionContainerView.swift`
- `PoseFinder/App/Views/TrainingMenuDetailView.swift`
- `PoseFinder/App/Views/SessionDetailView.swift`
- `PoseFinder/App/Repositories/RecordingSessionRepository.swift`
