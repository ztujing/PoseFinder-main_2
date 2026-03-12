# PoseFinder: Tech（技術仕様）

- **最終更新日**: 2026-03-06
- **正本**: `docs/specs/*`（`docs/archive/specs/*` は参考資料）

## 1. 対象プラットフォーム / 前提

- iOS アプリ（Xcode プロジェクト: `PoseFinder.xcworkspace` / `PoseFinder.xcodeproj`）
- デプロイターゲット: iOS 15.0（`Podfile`）
- ネットワーク必須機能: なし（当面はローカル完結）

## 2. 技術スタック（主な依存）

### 2.1 UI

- SwiftUI（ホーム/一覧/詳細など、段階的移行）
- UIKit（撮影画面など既存資産）

### 2.2 Media / カメラ

- `AVFoundation`（カメラ入力、録画、再生）
- `AVAssetWriter`（`video.mp4` の生成）
- `AVPlayer` / `AVKit.VideoPlayer`（セッション詳細での再生）

### 2.3 Pose 推定

- Google ML Kit Pose Detection（CocoaPods）
  - Pod: `GoogleMLKit/PoseDetection`（`Podfile` 参照）
  - 利用モード: stream（リアルタイム推定）

### 2.4 永続化

- DB は使わず、アプリの `Documents/` 配下にファイル保存
- フォーマット:
  - `session.json`（メタ情報）
  - `pose.ndjson`（JSON Lines / NDJSON）
  - `video.mp4`（H.264）

## 3. データフォーマット

### 3.1 `pose.ndjson`

- 1行=1フレームの JSON（末尾に `\n`）
- 主キー:
  - `t_ms`: 録画開始（先頭ビデオフレーム）からの相対ミリ秒
  - `img_size`: `[width, height]`
  - `score`: 現状は `Pose.confidence` を出力
  - `joints`: COCO17 相当の関節キー → `{x, y, c}`
- 座標:
  - `x`, `y` は **[0,1] 正規化**（画像サイズで割った値）
  - `c` は **[0,1]**（信頼度）

実装: `PoseFinder/Utils/PoseSerialization.swift`

- 再生時処理:
  - 全フレーム読み込み後、`t_ms` 昇順整列。
  - AVPlayer の現在時刻に最も近いフレームを二分探索で引き当て。
  - 座標系互換: 正規化済み座標をピクセル座標に変換（points/pixels 不一致吸収）。

### 3.2 `session.json`

- スキーマの基礎実装: `PoseFinder/Utils/RecordingSessionManager.swift`
- 読み込み側: `PoseFinder/App/Repositories/RecordingSessionRepository.swift`
- 例（概形）:
  - `schemaVersion`（現在 `1`）
  - `sessionId`
  - `createdAt`（ISO8601、fractional seconds あり）
  - `device`（model/os）
  - `camera`（position/preset）
  - `video`（file/codec/size/fps）
  - `pose`（file/jointSet/coords）

## 4. 技術方針（当面）

- **ファイルベース保存**を前提に、セッション構造・スキーマの安定化を優先する
- SwiftUI への移行は段階的に行い、撮影（UIKit）との境界は `UIViewControllerRepresentable` で保つ
- 仕様変更で挙動が変わる場合は、同一 PR で `docs/specs/*` を更新して整合性を維持する

## 5. 既知の技術課題（メモ）

- 計測（fps/latency/電力/温度）や OSLog 整備は未着手
- 再生時の Pose と動画のフレーム同期は実装済み。長尺/高fpsセッション向けのメモリ最適化は未完了

## 6. 参照

- 検証実装まとめ: `docs/archive/specs/検証実装/OVERVIEW.md`
