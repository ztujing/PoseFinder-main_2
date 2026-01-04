# Poseデータ欠損問題の修正プラン

## 概要

セッション詳細画面で「Poseデータの先頭フレームを読み込めませんでした」エラーが発生する、または `pose.ndjson` ファイルサイズが 0 になる問題を修正する。

## 問題の根本原因

### 発生条件

`VideoCapture.captureOutput()` 内で以下の順序で処理が実行される：

1. `sampleBufferDelegate.videoCapture(didOutput:)` → `appendVideo()` を **非同期** でキューイング
2. `delegate.videoCapture(didCaptureFrame:)` → ML Kit Pose 検出 → `appendPose()` を **非同期** でキューイング

`appendVideo()` 内で `firstVideoTimestamp` が設定されるが、非同期処理のため `appendPose()` が先に実行されることがある。

### 結果

`appendPose()` は `firstVideoTimestamp` が `nil` の場合に早期リターンするため、Pose データが破棄される。

```swift
// RecordingSessionManager.swift:238
guard let firstTimestamp = state.firstVideoTimestamp else { return }  // ← ここで破棄
```

`pose.ndjson` ファイルは `start()` 時に空ファイルとして作成されるため、書き込みが 0 のままセッションが終了する。

## 修正手順

### RecordingSessionManager.swift の修正

- [ ] `SessionState` クラスに `pendingPoses: [(Pose, CMTime, CGSize)]` プロパティを追加
- [ ] `appendPose()` を修正: `firstVideoTimestamp` が `nil` の場合、`pendingPoses` に追加して return
- [ ] `appendVideo()` を修正: `firstVideoTimestamp` 設定直後に `pendingPoses` 内の全 Pose を `poseWriter` に書き込む
- [ ] `pendingPoses` のメモリ上限を設定（任意: 最大 300 フレーム程度）

### RecordingSessionRepository.swift の修正

- [ ] `loadFirstPoseFrame()` でファイルサイズ 0 を検出し、専用エラー `RepositoryError.emptyPoseFile` をスロー
- [ ] `RepositoryError.emptyPoseFile` の `errorDescription` を追加:「Pose データが記録されませんでした（録画が短すぎた可能性があります）」

### テスト確認

- [ ] 実機でセッションを録画し、`pose.ndjson` にデータが書き込まれることを確認
- [ ] セッション詳細画面で Pose プレビューが正しく表示されることを確認
- [ ] 短い録画（1秒未満）でも Pose データが保存されることを確認

## 関連ファイル

| ファイル | 修正内容 |
|----------|----------|
| `PoseFinder/Utils/RecordingSessionManager.swift` | 一時バッファの追加、フラッシュ処理 |
| `PoseFinder/App/Repositories/RecordingSessionRepository.swift` | 空ファイル検出、エラーメッセージ改善 |

## 参考情報

- 問題のコードパス: `VideoCapture.captureOutput()` → `ViewController` → `RecordingSessionManager`
- 既存の関連ドキュメント: `docs/impl-reports/IMPL-0001-video-and-pose-json.md`
