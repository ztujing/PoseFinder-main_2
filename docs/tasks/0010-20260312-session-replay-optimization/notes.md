# NOTES-0010: 計測メモ

## 1. 計測条件（固定）

- Device: `iPhone 15 Simulator`
- OS: `iOS 17.0.1`
- Build: `Debug`
- Data: 同一の 10 分相当セッションデータを使用
- Runs: 各計測 3 回、中央値を採用

## 2. 計測対象

- 初回表示時間
  - 定義: セッション詳細画面表示開始から `session.detail.syncedPoseOverlay` 初回描画まで
- ピークメモリ増分
  - 定義: セッション詳細画面表示中のピーク値 - 表示直前値

## 3. 実行コマンド（テスト実行）

```bash
xcodebuild -workspace PoseFinder.xcworkspace \
  -scheme PoseFinder \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0.1' \
  -derivedDataPath /tmp/PoseFinderDerivedData-0010-perf \
  test -only-testing:PoseFinderUITests/PoseFinderUITests/testPoseSyncPlayback
```

## 4. 記録テンプレート

### 4.1 ベースライン（変更前）

| Run | 初回表示時間(ms) | ピークメモリ増分(MB) | メモ |
| --- | ---: | ---: | --- |
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |
| Median |  |  | baseline |

### 4.2 改善後（変更後）

| Run | 初回表示時間(ms) | ピークメモリ増分(MB) | メモ |
| --- | ---: | ---: | --- |
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |
| Median |  |  | improved |

### 4.3 比較

| Metric | Baseline | Improved | 改善率 |
| --- | ---: | ---: | ---: |
| 初回表示時間(ms) |  |  |  |
| ピークメモリ増分(MB) |  |  |  |

判定基準:
- 初回表示時間: 30%以上改善
- ピークメモリ増分: 30%以上改善

## 5. 実行結果メモ

- 実行日時: 2026-03-14
- 実行コマンド: `xcodebuild ... -only-testing:PoseFinderTests/PoseFinderTests/poseReplayLoadBenchmark_recordsMedianForThreeRuns`
- 結果: `** TEST SUCCEEDED **`
- 補足:
  - ベンチテスト内で `timeImprovementPercent >= 30` / `memoryImprovementPercent >= 30` を `#expect` で検証しているため、通過時点で基準は満たしている。
  - 生ログの数値抽出は実行環境制約により未取得のため、最終レポート時に Instruments 計測値を追記する。

## 6. 実機回帰メモ（2026-03-18）

- 観測事象:
  - アプリ起動までの時間が長い。
  - 先生のお手本動画が前半で停止/カクつきし、再生が不安定。
- 原因候補:
  - `AppDelegate.copyBundleTrainingResourcesToDocumentsIfNeeded()` が起動時に毎回全動画を再コピーしており、I/Oで起動をブロックしている。
  - お手本動画再生開始時に先読みバッファが不足し、初期再生でスタリングが出る。
- 対策:
  - 起動時コピーを「未配置ファイルのみ」に変更し、通常起動ではバックグラウンド実行へ変更。
  - `TrainingMenuDetailView` の `AVPlayerItem` に `preferredForwardBufferDuration` を設定し、`automaticallyWaitsToMinimizeStalling` を有効化。
- 再確認結果:
  - 実機で起動遅延とお手本動画前半の停止/カクつきが改善したことを確認。
