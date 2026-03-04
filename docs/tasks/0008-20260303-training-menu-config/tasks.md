# TASKS-0008: training-menu-config

- **Date**: 2026-03-04
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0008](plan.md)
- **Scope**: FE
- **Status**: In Progress

> 本ファイルは `plan.md` の「実装手順（Implementation Steps）」を  
> 実際の作業単位に分解した **2階層のチェックリスト** です。  
> AI コーディングや日々の実装は、この順序に沿って進めます。

## 1. 準備 / セットアップ

- [ ] リポジトリ / ブランチの準備
  - [ ] `feature/0008-training-menu-config` ブランチ作成
  - [ ] 既存 Repository 実装例（RecordingSessionRepository）を確認

## 2. 実装タスク（Implementation Tasks）

### フェーズ1: 基礎レイヤー構築

- [ ] TrainingMenu.swift にフィールド追加
  - [ ] `videoFileName: String?` フィールド追加
  - [ ] Codable 適用確認

- [ ] TrainingMenuDataSource Protocol 作成
  - [ ] `PoseFinder/App/DataSources/` ディレクトリ作成
  - [ ] `TrainingMenuDataSource.swift` 作成
  - [ ] `fetchTrainingMenus() async throws -> [TrainingMenu]` メソッド定義
  - [ ] `getVideoURL(for fileName: String) -> URL?` メソッド定義

- [ ] TrainingMenuLocalDataSource 実装
  - [ ] `TrainingMenuLocalDataSource.swift` 作成
  - [ ] Protocol 準拠実装
  - [ ] `Resources/training-menus.json` からバンドル読み込み
  - [ ] Codable でデコード
  - [ ] `getVideoURL(for:)` で `Documents/PoseFinderTrainingMenus/videos/` から探索
  - [ ] エラーハンドリング（JSONデコードエラー等）

- [ ] TrainingMenuRepository 作成
  - [ ] `PoseFinder/App/Repositories/` 確認（既存ディレクトリか作成）
  - [ ] `TrainingMenuRepository.swift` 作成
  - [ ] Constructor で `dataSource` 依存性を受け取る
  - [ ] `getTrainingMenus() async throws -> [TrainingMenu]` 実装
  - [ ] エラーハンドリング・キャッシュ（Option）

### フェーズ2: UI層変更

- [ ] HomeViewModel 修正
  - [ ] `TrainingMenuRepository` プロパティ追加
  - [ ] `init()` で Repository 初期化（LocalDataSource 使用）
  - [ ] `@Published menus` の初期化を async に変更
  - [ ] Task で `getTrainingMenus()` 呼び出し
  - [ ] エラーハンドリング（ネットワークエラー感知）

- [ ] HomeView 修正（オプション）
  - [ ] ローディング状態表示（必要に応じて）
  - [ ] エラー表示（必要に応じて）

- [ ] TrainingMenuDetailView に動画再生機能追加
  - [ ] `videoFileName` 取得
  - [ ] `AVPlayer` を使用してプレイヤー実装
  - [ ] 動画ファイルの URL 取得
  - [ ] 自動再生設定（音声なし）
  - [ ] 動画ファイル不在時のグレースフル処理

### フェーズ3: リソース配置

- [ ] JSON リソース作成・配置
  - [ ] `Resources/training-menus.json` 作成
  - [ ] 既存の 3 メニュー（スクワット/デッドリフト/プッシュアップ）をコピー
  - [ ] Xcode ビルドフェーズで Target に含める確認

- [ ] ビデオリソース配置（オプション）
  - [ ] `Resources/videos/` ディレクトリ作成
  - [ ] サンプル MP4 配置（またはプレースホルダ）
  - [ ] Xcode ビルドフェーズで Target に含める確認

- [ ] Documents ディレクトリへのコピー処理
  - [ ] AppDelegate または SceneDelegate を確認
  - [ ] 初回起動時に `training-menus.json` を `Documents/PoseFinderTrainingMenus/` にコピー
  - [ ] 動画もコピー（あれば）

### フェーズ4: テスト & 検証

- [x] ユニットテスト実装
  - [x] Mock DataSource 作成（定義済みメニューを返す）
  - [x] TrainingMenuLocalDataSource テスト
    - [x] 正常な JSON 読み込み
    - [x] JSON 構文エラー時の throw
    - [x] `getVideoURL()` の正常系・nil 返却確認
  - [x] Repository テスト
    - [x] DataSource エラーのハンドリング
    - [x] キャッシュ動作（実装時）

- [x] 手動テスト実装
  - [x] ビルド後、HomeView に 3 メニュー表示確認
  - [x] メニュー詳細画面で参考動画が再生確認（音無し）
  - [x] 動画ファイルが見つからない場合、プレイヤーが非表示確認
  - [x] JSON 再編集 + 再起動で反映確認

### フェーズ5: ドキュメント & ADR

- [x] ADR 0009 作成
  - [x] `docs/adr/0009-2026-03-03-training-menu-datasource-abstraction.md` 作成
  - [x] 決定・理由・代替案・後続手順を記載
  - [x] リモートデータソース移行手順をスケッチ

- [x] docs/specs/structure.md 更新
  - [x] 「トレーニングメニュー構成」セクション追加
  - [x] DataSource → Repository → ViewModel のレイヤー図追加
  - [x] データソース切り替えの手順（将来の参考）

- [x] docs/specs/ui.md 更新
  - [x] 「トレーニング詳細画面・参考動画機能」セクション追加

## 3. テスト / 品質確認

- [ ] テストコードの整備
  - [ ] ユニットテスト全て通過
  - [x] 手動テストチェックリスト全て確認
  - [ ] CI/ビルドエラーなし

- [ ] コード品質チェック
  - [ ] Lint エラーなし
  - [ ] 型チェック通過
  - [ ] 命名規則・スタイルガイド準拠

## 4. ドキュメント / レビュー準備

- [x] `impl-report.md` ドラフト作成
  - [x] What changed（サマリ）記述
  - [x] Finalized Specs（Protocol/Repository/ViewModel の構成）記述
  - [x] Deviation from Plan 記述
  - [x] Evidence（テスト結果）記述

- [x] `docs/specs/*` の最終確認
  - [x] structure.md に記載内容と実装の一致確認
  - [x] ui.md に記載内容と実装の一致確認

- [ ] PR 準備
  - [ ] Commit メッセージ整理
  - [ ] PR 本文にリンク（Plan/Impl/ADR 等）
  - [ ] レビュアーに共有・承認待ち
