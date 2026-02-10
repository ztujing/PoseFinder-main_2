# TASKS-0006: Recording 完了後に SessionDetail へ自動遷移

- **Date**: 2026-01-19
- **Owner**: @tujing
- **Related PLAN**: PLAN-0006
- **Scope**: FE
- **Status**: In Progress

> 本ファイルは `plan.md` の「実装手順（Implementation Steps）」を  
> 実際の作業単位に分解した **2階層のチェックリスト** です。  
> AI コーディングや日々の実装は、この順序に沿って進めます。

## 1. 準備 / セットアップ

- [ ] リポジトリ / ブランチの準備
  - [ ] `feature/0006-recording-to-session-detail` ブランチ作成
  - [ ] 対象ファイルと現状導線（撮影→完了通知→SwiftUI）の確認

## 2. 実装タスク（Implementation Tasks）

- [x] 大タスク1: 完了通知に `directoryURL` を含める（UIKit）
  - [x] `PoseFinder/UI/ViewController.swift` の `.recordingSessionDidComplete` に `userInfo` を付与する
  - [x] `userInfo` のキー（例: `directoryURL`）を SwiftUI 側と一致させる

- [x] 大タスク2: `RecordingSessionScreen` で完了通知を処理し、セッションを復元して親へ返す（SwiftUI）
  - [x] `PoseFinder/App/Views/RecordingSessionContainerView.swift` に `onCompleted` コールバックを追加する
  - [x] 通知 `userInfo` から `directoryURL` を取得し、`RecordingSessionRepository.reloadSession(at:)` で `RecordingSession` を復元する
  - [x] 多重遷移防止（1回だけ処理）と、失敗時の **1回再試行 → 再失敗時はメニュー詳細へ戻す** を入れる
  - [x] 成功時に `dismiss()` して親へ `RecordingSession` を渡す

- [x] 大タスク3: メニュー詳細から「撮影→完了→詳細」へ繋ぐ（SwiftUI ナビゲーション）
  - [x] `PoseFinder/App/Views/TrainingMenuDetailView.swift` から `RecordingSessionScreen(onCompleted:)` を起動する
  - [x] 受け取った `RecordingSession` を使って `SessionDetailView(session:)` へプログラム遷移する（iOS 15/16+ 両対応）
  - [x] 詳細画面から戻った際、録画画面へ戻らないことを確認する

- [x] 大タスク4: 既存の一覧更新通知と干渉しないことを確認する
  - [x] `PoseFinder/App/ViewModels/SessionListViewModel.swift` の通知購読が引き続き動作することを確認する

- [ ] 大タスク5: 仕様の最小更新（必要な場合）
  - [x] `docs/specs/ui.md` に「完了時はセッション詳細へ自動遷移」を追記する（差分が出た場合のみ）

## 3. テスト / 品質確認

- [ ] 手動確認
  - [x] メニュー詳細 → 撮影開始 → 完了で `SessionDetail` が自動で開く
  - [ ] `SessionDetail` で動画再生と Pose プレビューが表示される
  - [x] `SessionDetail` の戻るでメニュー詳細に戻る（録画画面に戻らない）
  - [x] 録画中に「戻る」→「中断する」では詳細へ遷移しない
  - [ ] 取得失敗時は 1 回だけ再試行し、再失敗時は自動遷移せずメニュー詳細へ戻る
  - [ ] iOS 15 / iOS 16+ で同等に動作する（可能な範囲で確認）

## 4. ドキュメント / レビュー準備

- [x] `docs/tasks/0006-20260119-recording-to-session-detail/impl-report.md` のドラフト作成
- [x] `docs/specs/*` の更新（必要な場合）
- [ ] レビュアーに共有（Issue / PR にリンク）

## 5. マージ / アフターケア

- [ ] PR マージ
- [ ] `impl-report.md` を `Done` に更新
- [ ] フォローアップ Issue の登録（残課題があれば）
