# TASKS-0009: 未完項目完了（MVP 完全化ステップ1）

- **Date**: 2026-03-06
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0009](docs/tasks/0009-20260306-mvp-completion/plan.md)
- **Scope**: FE
- **Status**: In Progress

> 本ファイルは `plan.md` の「実装手順（Implementation Steps）」を  
> 実際の作業単位に分解した **2階層のチェックリスト** です。  
> AI コーディングや日々の実装は、この順序に沿って進めます。

## 1. 準備 / セットアップ

- [x] リポジトリ / ブランチの準備
  - [x] `feature/0009-mvp-completion` ブランチ作成
  - [x] 依存ライブラリ / ツールの確認

## 2. 実装タスク（Implementation Tasks）

- [x] 自動テスト追加
  - [x] PoseFinderTests に UI テストケース作成（撮影完了遷移）
  - [x] PoseFinderTests に UI テストケース作成（Pose 同期表示）

- [x] specs 更新
  - [x] ui.md に Pose 同期オーバーレイ追記
  - [x] tech.md に座標系互換追記

- [x] DoD チェック
  - [x] チェックリスト実行・確認

## 3. テスト / 品質確認

- [ ] テストコードの整備
  - [ ] UI テスト実行
- [ ] 手動確認
  - [ ] 主要ユースケースの画面動作確認

## 4. ドキュメント / レビュー準備

- [ ] `impl-report.md` のドラフト作成
- [ ] `docs/specs/*` の更新（必要な場合）
- [ ] レビュアーに共有（Issue / PR にリンク）

## 5. マージ / アフターケア

- [ ] PR マージ
- [ ] 本番/ステージングへのデプロイ確認
- [ ] 監視 / アラート / ログの確認
- [ ] `impl-report.md` を `Done` に更新
- [ ] フォローアップ Issue の登録（残課題があれば）