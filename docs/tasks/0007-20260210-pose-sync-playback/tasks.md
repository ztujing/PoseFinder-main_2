# TASKS-0007: 再生時に Pose を動画と同期してオーバーレイ表示

- **Date**: 2026-02-10
- **Owner**: @tujing
- **Related PLAN**: PLAN-0007
- **Scope**: FE
- **Status**: In Progress

> 本ファイルは `plan.md` の「実装手順（Implementation Steps）」を  
> 実際の作業単位に分解した **2階層のチェックリスト** です。  
> AI コーディングや日々の実装は、この順序に沿って進めます。

## 1. 準備 / セットアップ

- [ ] リポジトリ / ブランチの準備
  - [ ] `feature/0007-pose-sync-playback` ブランチ作成
  - [ ] 現状の `SessionDetail` と `PosePreview` 実装を確認する

## 2. 実装タスク（Implementation Tasks）

- [x] 大タスク1: 生徒 Pose の全フレーム読み込みを追加する
  - [x] `RecordingSessionRepository` に `pose.ndjson` の全フレーム読み込み API を追加する
  - [x] `t_ms` 昇順のフレーム配列を作る（decode失敗行はスキップ）

- [x] 大タスク2: セッション詳細 ViewModel に「現在フレーム」を導入する
  - [x] `SessionDetailViewModel` に `currentPoseFrame` を追加する
  - [x] `AVPlayer` の time observer を追加し、`currentTime` に応じてフレームを引き当てる
  - [x] observer の解除（`deinit` や `onDisappear` 相当）を確実に行う

- [x] 大タスク3: `SessionDetail` にオーバーレイ表示を追加する
  - [x] 動画領域を `ZStack` にし、`PoseOverlayView` を重ねる
  - [x] `PosePreviewView` の描画ロジックを流用または切り出す

- [x] 大タスク4: 例外系と表示を整える
  - [x] Pose が無いセッションでも動画表示は維持する
  - [x] NDJSON が空/不正の場合にクラッシュしないことを確認し、既存方針のエラー表示に合わせる

- [ ] 大タスク5: `docs/specs` を最小更新する
  - [ ] `docs/specs/ui.md` に「再生時にPoseを同期表示する」を追記する
  - [ ] 必要なら `docs/specs/tech.md` に引き当て方針を追記する

## 3. テスト / 品質確認

- [ ] 手動確認
  - [ ] 再生に合わせて Pose が追従して更新される
  - [ ] 一時停止/再開で Pose が追従する
  - [ ] シークしてもクラッシュせず Pose が追従する
  - [ ] `pose.ndjson` が空/不正でもクラッシュせずエラー表示になる

## 4. ドキュメント / レビュー準備

- [ ] `docs/tasks/0007-20260210-pose-sync-playback/impl-report.md` のドラフト作成
- [ ] `docs/specs/*` の更新（必要な場合）
- [ ] レビュアーに共有（Issue / PR にリンク）

## 5. マージ / アフターケア

- [ ] PR マージ
- [ ] `impl-report.md` を `Done` に更新
- [ ] フォローアップ Issue の登録（残課題があれば）
