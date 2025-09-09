# PLAN-0001 — 動画保存とPoseデータJSON化（MVP）

- Status: Draft
- Date: 2025-09-09
- Pair Impl: `IMPL-0001-video-and-pose-json.md`
- Related Specs: `docs/specs/001_概要設計.md`, `docs/specs/002_画面遷移図.md`
- Related Notes: `docs/specs/他AI提案/200_実装方針_動画保存_json保存まで.md`

## Context
ユーザーが筋トレ中のフォームを客観的に記録・再生できるよう、撮影動画と姿勢（Pose）を同期して保存・再生する機能が必要。現状のアプリは“姿勢検出の検証実装”段階で、保存は未対応。

まずは MVP として「動画（mp4）」と「Poseデータ（JSON or JSONL）」を同一セッションとして保存できるようにする。起動→お手本Movie再生→同時にカメラ撮影→Movie終了で自動保存、を目標とする。

## Goals
- 動画を `Documents/Sessions/<sessionId>/video.mp4` に保存（H.264、サイズはiphone動画撮影サイズを想定）。
- Pose をフレームタイムスタンプと同期して JSON として保存。
- セッションメタデータ（保存先、開始/終了時刻、端末情報）を `session.json` に保存。
- 録画の開始/終了トリガーをお手本Movieの再生開始/終了に連動。
- 後続の再生画面（SessionDetail）で同期再生できる前提のデータ構造を用意。

## Non-Goals
- クラウド同期/共有、編集機能、解析スコアの高度化。
- マルチセッション同時録画、音声入力、サーバ連携。

## Impact
- 追加: `RecordingSessionManager`（セッション生成/ファイルI/O/メタ情報管理）。
- 変更: `VideoCapture`（フレームのタイムスタンプを取得・委譲できる拡張）。
- 変更: `ViewController`（録画開始/終了、Pose書き出しのオーケストレーション）。
- 追加: `PoseSerialization`（Pose→JSON 変換ユーティリティ）。

## Alternatives
- 動画保存手段:
  - A) `AVAssetWriter`（推奨）: `CMSampleBuffer`/`CVPixelBuffer`単位で書き込み・時刻同期しやすい。
  - B) `AVCaptureMovieFileOutput`（簡易）: 手軽だが同期制御と細かな設定はAに劣る。
  本計画では A を採用（将来Bのフォールバック追加可）。
- Pose保存形式:
  - A) JSON Lines（`.ndjson`）ストリーミング書き出し（推奨）。
  - B) 1ファイル配列（`pose.json`）: 終了時一括保存でメモリ使用大。
  MVPは A を採用（安定まで B をオプションとして残してもよい）。

## Design Overview
- ディレクトリ構成（アプリ内Documents）
  - `Documents/Sessions/<sessionId>/`
    - `session.json`（メタ）
    - `video.mp4`（H.264）
    - `pose.ndjson`（1行=1フレーム）

- セッションID: `yyyyMMdd-HHmmss` 形式（重複回避のため末尾に乱数4桁付与可）。

- `session.json`（例）
  ```json
  {
    "schemaVersion": 1,
    "sessionId": "20250909-223000",
    "createdAt": "2025-09-09T22:30:00Z",
    "device": { "model": "iPhone", "os": "iOS 17" },
    "camera": { "position": "front|back", "preset": "vga640x480" },
    "video": { "file": "video.mp4", "codec": "h264", "size": [640,480], "fps": 30 },
    "pose": { "file": "pose.ndjson", "jointSet": "coco17", "coords": "normalized" }
  }
  ```

- `pose.ndjson`（1行ごとに以下のJSON）
  ```json
  {
    "t_ms": 1234,
    "img_size": [640,480],
    "score": 0.87,
    "joints": {
      "nose": { "x": 0.51, "y": 0.12, "c": 0.9 },
      "leftShoulder": { "x": 0.33, "y": 0.42, "c": 0.8 },
      "rightShoulder": { "x": 0.66, "y": 0.41, "c": 0.8 }
      // ... coco17
    }
  }
  ```
  - 座標は [0,1] 正規化（再生時に画素座標へ復元）。
  - `t_ms` は `CMSampleBuffer` の `presentationTimeStamp` 基準（開始時刻=0ms 換算）。

- 処理フロー
  1) `ViewController` 起動時にお手本Movie再生を開始。
  2) 同時に `RecordingSessionManager.start()` でセッションを生成し、`AVAssetWriter` 準備。
  3) `VideoCapture` のデリゲートで `CMSampleBuffer` の時刻取得→`AVAssetWriter` へ書き込み。
  4) 同フレームで推定した `Pose` を NDJSON へ追記（I/O専用キューで非同期書き込み）。
  5) Movie終了通知で `stop()` を呼び、`finishWriting()` とファイルハンドルを閉じる。
  6) `session.json` を出力し完了。

## Implementation Steps
1. `RecordingSessionManager` 追加
   - セッションID生成、ディレクトリ作成、`AVAssetWriter` 構築（mp4/H.264, 640x480, ~30fps）。
   - `append(sampleBuffer:)`/`append(pixelBuffer:at:)` 実装。
   - NDJSON用 `PoseWriter`（`FileHandle` + シリアライザ + 専用`DispatchQueue`）。
2. `VideoCapture` 拡張
   - 既存 `delegate` に加え、`sampleBuffer` を横取りできるコールバック/デリゲートを追加（時刻取得用）。
   - 出力の向き/ミラー設定と `CVPixelBuffer` フォーマット（`kCVPixelFormatType_32BGRA` 等）を `AVAssetWriter` と整合。
3. `PoseSerialization` 追加
   - `Pose`/`Joint` → 正規化座標JSON へ変換（フレーム画像サイズ依存）。
   - JSONLines 1行文字列へエンコード（`JSONEncoder` + 改行）。
4. `ViewController` 連携
   - 再生開始時に `start()`、`AVPlayerItemDidPlayToEndTime` で `stop()`。
   - キャプチャ中は各フレームで `RecordingSessionManager` に動画/ポーズを渡す。
5. エラーハンドリング/リソース解放
   - 録画停止時に `markAsFinished/finishWriting`、`FileHandle` を確実にクローズ。
   - 失敗時はセッションディレクトリをクリーンアップ。
6. 設定/フラグ
   - `RecordingEnabled`/`PoseJSONLinesEnabled` の内部フラグを用意（将来の切替用）。

## Test Plan
- 端末/シミュレータで実行し、Movie終了後に `video.mp4` と `pose.ndjson` が生成されること。
- `pose.ndjson` の行数 ≒ 動画フレーム数（±ドロップ数）であること。
- 一部行を抽出し、`t_ms` が単調増加、`[0,1]` 範囲、`c` が [0,1] を満たすこと。
- `session.json` の整合性（ファイルパス/サイズ/画角）。
- 長尺（>5分）でメモリリーク/ファイルロックが無いこと（Instruments）。

## Rollback
- `RecordingEnabled=false` で保存を無効化。コード変更は `ViewController` の分岐のみで切り戻し可能。

## Follow-ups
- セッション再生画面（`SessionDetail`）での同期再生実装。
- Photos へのエクスポート/共有。
- JSON スキーマの厳密化（バージョニングとバリデータ追加）。

## Artifacts（想定）
- 出力例: `…/Documents/Sessions/20250909-223000/{video.mp4, pose.ndjson, session.json}`

