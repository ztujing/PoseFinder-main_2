# IMPL-0001: 動画保存とPoseデータJSON化（MVP）

- **Date**: 2025-10-20
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0001-video-and-pose-json](../plans/PLAN-0001-video-and-pose-json.md)
- **PRs**: (未作成)
- **Status**: Done

## 1. 実装サマリ（What Changed）
- `RecordingSessionManager` を実装し、セッション ID 生成・保存用ディレクトリ作成・`AVAssetWriter` での動画書き込み・`pose.ndjson` ストリーミング出力・`session.json` メタデータ生成までを包括的に実装。
- `VideoCapture` に `VideoCaptureSampleBufferDelegate` を追加し、カメラの `CMSampleBuffer` をリアルタイムで `RecordingSessionManager` へ転送できるように拡張。
- `PoseSerialization` を新規追加し、`Pose` から NDJSON 1 行分の payload を生成するユーティリティ（正規化座標・信頼度のクリップ処理等）を定義。
- `ViewController` へ録画セッションの開始/停止、`appendVideo`・`appendPose` 呼び出し、再生終了通知でのクリーンアップ処理を組み込み、UI 上で自動録画が完結するワークフローを構築。
- iOS 13.4 未満で `FileHandle` API が例外になる問題に対応するため、`seekToEndOfFile` / `write(_:)` / `closeFile()` へのフォールバックを追加して互換性を確保。
- 録画停止時に保存先パスをログ出力する処理を追加し、生成物確認の手順を明確化。
- `PoseFinder.xcodeproj` に `RecordingSessionManager.swift` を登録し忘れていた点を修正してビルドに含めた。
- 参照資料整理のため `docs/specs/他AI提案` ディレクトリを削除。

## 2. 仕様の確定内容（Finalized Specs）
- セッション保存構成を確定: `Documents/Sessions/<sessionId>/` 以下に `video.mp4`（H.264）、`pose.ndjson`（COCO17 正規化座標）、`session.json`（デバイス・カメラ・動画メタ情報）を出力。
- `PoseSerialization` の JSON 形式（`t_ms` / `img_size` / `score` / `joints`）を MVP の仕様として固定。
- UI/UX: 録画開始・停止・保存確認までを UI レイヤーから自動実行し、停止時には保存先パスをログ出力する運用仕様を追加。
- プロジェクト構成: `RecordingSessionManager` をビルドターゲットに含める設定を反映。
- API/DB: 新規通信やスキーマ変更なし。

## 3. 計画との差分（Deviation from Plan）
- iOS 13.4 未満互換のため `FileHandle` フォールバックを追加（PLAN では想定外だったが、サポート端末範囲を広げるため実施）。
- PLAN が参照していた `docs/specs/他AI提案` を削除したため、PLAN 内リンクの整理が必要。
- その他の仕様・構成は PLAN どおりに実装。

## 4. テスト結果（Evidence）
- 手動テスト: 実機で録画→再生終了まで実施し、保存先ログ（例: `/var/mobile/.../Sessions/20251020-194929-7298`）から `.xcappdata` を取得して `video.mp4`, `pose.ndjson`, `session.json` の生成を確認。`pose.ndjson` 行ごとの `t_ms` が増加し、正規化座標が [0,1] 内に収まっている点も Spot check。
- 自動テスト: 未実施。
- 受入基準チェック:
  - [ ] 主要ユースケース自動化
  - [ ] OpenAPI/Storybook 反映
  - [ ] 監視・アラート整備
  - [ ] リリースノート更新

## 5. 運用ノート（Operational Notes）
- デバイス上で保存確認する際は Xcode の `Download Container…` を利用し、保存先フォルダへのアクセス権（ファイルとフォルダ設定）を付与する必要あり。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）
- 自動テストが未整備。録画・NDJSON 出力のリグレッション検証を追加したい。
- PLAN が参照する資料パスの更新が必要（`docs/specs/他AI提案` 削除によるリンク切れ）。

## 7. 関連ドキュメント（Links）
- PLAN: [docs/plans/PLAN-0001-video-and-pose-json.md](../plans/PLAN-0001-video-and-pose-json.md)
- 仕様: [docs/specs/001_概要設計.md](../specs/001_概要設計.md), [docs/specs/002_画面遷移図.md](../specs/002_画面遷移図.md)

## 8. 追記/正誤
- なし
