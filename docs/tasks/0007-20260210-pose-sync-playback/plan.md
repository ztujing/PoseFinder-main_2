# PLAN-0007: 再生時に Pose を動画と同期してオーバーレイ表示

- **Date**: 2026-02-10
- **Owner**: @tujing
- **Scope**: FE
- **Status**: Approved

## 1. 背景 / 目的（Context & Goals）

現状のセッション詳細では動画は再生できるが、Pose は先頭フレームのプレビュー表示に留まっており、フォームの振り返り（動画＋棒人間）としての価値が低い。

MVP として、**動画再生時刻に追従して生徒（自分）の Pose をオーバーレイ表示**できるようにする。

ゴール:

- セッション詳細の動画再生に合わせて、生徒 Pose が追従して更新される（再生/一時停止/シークで破綻しない）
- Pose データ欠損や NDJSON 破損があってもクラッシュせず、既存のエラー表示方針に従う
- 実装は最短で「同期して動く」ことを優先し、表示Rect補正などの精密化は後回しにする

前提（将来の拡張）:

- 先生 Pose は「メニューごとに 1 本、アプリバンドルへ同梱」する方針（本タスクでは生徒 Pose の同期表示を優先し、先生 Pose 同時表示は次タスクで対応する）

## 2. 非目標（Non-Goals）

- 先生 Pose の同時表示（比較モード）と、そのためのアセット同梱・対応表整備
- 表示Rect補正（アスペクトフィットのレターボックスを考慮した厳密な座標変換）
- 高速化のための NDJSON インデックス化、部分読み込み、間引き最適化
- 再生時のフレーム完全一致（nearest で十分な体験を優先）

## 3. 影響範囲（Impact）

- UI:
  - セッション詳細: `PoseFinder/App/Views/SessionDetailView.swift`
  - Pose 描画: `PoseFinder/App/Views/PosePreviewView.swift`（流用またはロジック切り出し）
- ViewModel:
  - `PoseFinder/App/ViewModels/SessionDetailViewModel.swift`
- 永続化 / I-O:
  - `PoseFinder/App/Repositories/RecordingSessionRepository.swift`（必要なら「全フレーム読込」API を追加）
- ドキュメント:
  - 実装で挙動が変わるため `docs/specs/ui.md` を更新候補
  - データ扱いの補足が必要なら `docs/specs/tech.md` も更新候補

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）

- 代替案A: 現状維持（先頭フレームだけ）
  - 利点: 実装なし
  - 欠点: 振り返り価値が低い
  - 却下理由: MVP の主要価値に直結するため

- 代替案B: 動画の上にオーバーレイはせず、別領域に Pose を表示
  - 利点: 位置ズレの問題が小さい
  - 欠点: 動画と見比べにくい
  - 却下理由: 「動画＋棒人間」の直感的価値を優先

採用（本案）:

- `AVPlayer` の再生時刻を定期購読し、`t_ms` に最も近い Pose フレームを選んで描画する（MVPは nearest）

## 5. 実装方針（Design Overview）

### 5.1 データフロー概観

1. セッション詳細で `AVPlayer` を再生
2. `AVPlayer` の time observer で現在時刻を取得し、ms に変換
3. `pose.ndjson` を読み込んだフレーム配列から、現在msに最も近いフレームを選択
4. `VideoPlayer` の上に `PoseOverlayView` を重ねて描画

### 5.2 実装の要点

- Pose フレーム読み込み:
  - MVP は「全行読み込み」でも良い（データ量が増えたら最適化タスクに分離）
  - `t_ms` 昇順配列を作り、シークに強いように二分探索で引き当てる
- 時刻購読:
  - `addPeriodicTimeObserver` を使用し、間隔は 1/30 秒程度から開始
- 描画:
  - 既存の `PosePreviewView` の描画ロジックを流用し、オーバーレイ用の View へ切り出す

## 6. 実装手順（Implementation Steps）

1. 生徒 Pose の全フレーム読み込みを追加する
   - `RecordingSessionRepository` に `pose.ndjson` 全フレーム読み込み API を追加する
   - `PoseFrame` 配列へ decode し、`t_ms` を保持する

2. セッション詳細 ViewModel に「現在フレーム」を導入する
   - `SessionDetailViewModel` に `currentPoseFrame` を追加する
   - `AVPlayer` の time observer を管理し、`currentTime` に応じて `currentPoseFrame` を更新する
   - `deinit` または `onDisappear` 相当で observer を確実に解除する

3. セッション詳細にオーバーレイ表示を追加する
   - `SessionDetailView` の動画領域を `ZStack` にし、上に `PoseOverlayView` を重ねる
   - 一時停止時も最後のフレームが保持されることを確認する

4. 例外系と表示を整える
   - NDJSON が空/壊れている場合は、既存のエラー表示方針に従う
   - Pose が無いセッションでも動画表示は維持する

5. `docs/specs` を最小更新する
   - `docs/specs/ui.md` に「再生時にPoseを同期表示する」を追記する
   - 必要なら `docs/specs/tech.md` に time observer と `t_ms` の引き当て方針を補足する

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）

手動テスト:

- [ ] `SessionDetail` で動画再生に合わせて Pose が追従して更新される
- [ ] 一時停止で Pose が停止し、再開で追従が再開する
- [ ] シークしてもクラッシュせず、Pose が追従する
- [ ] `pose.ndjson` が空/不正の場合にクラッシュせず、エラー表示が出る

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）

- ロールバック:
  - time observer とオーバーレイ表示を削除し、先頭フレームプレビューへ戻す
- リスク:
  - 全フレーム読み込みでメモリ/待ち時間が増える
    - 軽減: MVPは許容し、次タスクでインデックス化/間引き/ストリーミングを検討
  - オーバーレイの位置ズレが目立つ
    - 軽減: 本タスクは「同期して動く」を優先し、表示Rect補正は別タスク化

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）

- `docs/tasks/0007-20260210-pose-sync-playback/impl-report.md`
- `docs/specs/ui.md`（挙動変更の反映）
- `docs/specs/tech.md`（必要なら補足）
- ADR: 不要（MVPの段階的改善として扱う）

## 10. 参照（References）

- `docs/specs/ui.md`
- `docs/specs/tech.md`
- `PoseFinder/App/Views/SessionDetailView.swift`
- `PoseFinder/App/ViewModels/SessionDetailViewModel.swift`
- `PoseFinder/App/Repositories/RecordingSessionRepository.swift`
