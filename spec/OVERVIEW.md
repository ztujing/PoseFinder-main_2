# プロジェクト概要（OVERVIEW）

本ドキュメントは iOS アプリ「PoseFinder」の全体像を俯瞰し、役割・依存・処理フローを整理します。対象は Swift 製、教師（動画）×生徒（カメラ）の姿勢推定・可視化アプリです。推論は ML Kit Pose Detection を主経路とし、Core ML PoseNet 経路は併存（UI では未使用）。

## 目次
- 背景と目的
- フォルダ構成
- 主要依存（フレームワーク/ライブラリ）
- アーキテクチャ概観
- データフロー（パイプライン）
- 描画とスコアリング
- 性能・電力・権限
- ログ/計測
- 参考資料

## 背景と目的
- 目的: 動画（教師）とリアルタイムカメラ（生徒）の姿勢を検出し、スケーリングと採点のうえでオーバーレイ描画する。
- 状態: サンプル動作は完成済み。推論は ML Kit を使用。PoseNet（Core ML）実装も同梱し、切替や再利用の素地あり。

## フォルダ構成
- `PoseFinder/App`: アプリ起動・`Info.plist` など
- `PoseFinder/UI`: 主要 UI／描画／設定ビュー
- `PoseFinder/Utils`: カメラ入出力・向き変換
- `PoseFinder/Pose`: ポーズ表現・組み立て・スケーリング/スコアリング
- `PoseFinder/Model`: Core ML PoseNet 入出力ラッパ（併存）
- `PoseFinder/Extensions+Types`: 型拡張（`CGImage.size` ほか）
- `Documentation/`: 画像アセット（パイプライン/可視化）

## 主要依存（フレームワーク/ライブラリ）
- Apple SDK: `AVFoundation`, `UIKit`, `VideoToolbox`, `CoreML`, `Vision`
- ML Kit: `MLKitPoseDetection`, `MLKitVision`（Pod: `GoogleMLKit/PoseDetection`）
- iOS: 最低 13.0（`Podfile` より）

## アーキテクチャ概観
- 入力は2系統
  - カメラ: `VideoCapture` が `CGImage` を生成
  - 動画: `AVPlayer` + `AVVideoComposition` でフレームを `CGImage` 化
- 推論
  - 現行: ML Kit `PoseDetector`（stream モード）
  - 併存: Core ML PoseNet → `PoseNetOutput` → `PoseBuilder`
- スコアリング: `ScaledPoseHelper` が教師基準で生徒をスケーリングし、関節距離からスコア集計
- 描画: `PoseImageView` が教師（青）/生徒（赤）を重ね描画（点色はスコアに応じ赤→緑連続）

## データフロー（パイプライン）
```mermaid
flowchart LR
  subgraph Input
    Cam[Camera\nAVCaptureSession] --> CG1[CGImage]
    Vid[Video\nAVPlayer+AVVideoComposition] --> CG2[CGImage]
  end

  CG1 --> MLK1[ML Kit\nPoseDetector(stream)] --> StuPose[Pose (student)]
  CG2 --> MLK2[ML Kit\nPoseDetector(stream)] --> TeaPose[Pose (teacher)]

  StuPose --> SPH[ScaledPoseHelper]
  TeaPose --> SPH
  SPH --> Overlay[PoseImageView Overlay]
  Overlay --> UI[UIImageView / UI]

  %% Alternate path (not active in UI)
  CG1 -.-> PN1[Core ML PoseNet] -.-> PNO1[PoseNetOutput] -.-> PB1[PoseBuilder] -.-> Pose1[Pose]
```

補足:
- 動画フレームは `CIImage.toCGImage()` で `CGImage` 化。
- `VideoCapture` は `alwaysDiscardsLateVideoFrames = true` で遅延フレームを廃棄。

## 描画とスコアリング
- 描画: `PoseFinder/UI/PoseImageView.swift` の `show()` が線分・関節点を重ね描画。
- スコア: `PoseFinder/Pose/ScaledPoseHelper.swift`
  - 教師/生徒の重心を計算して平行移動
  - 教師ポーズを基準にスケーリング（教師→生徒）
  - 各関節の距離に基づき `Joint.score` を算出、平均化して `Pose.score`

## 性能・電力・権限
- 性能: 遅延フレーム破棄により実時間描画を優先。FPS/レイテンシ計測、CPU/GPU/ANE 利用状況の収集は未実装。
- 電力: サンプリング制御や熱状態監視は未実装。
- 権限: `NSCameraUsageDescription` は `PoseFinder/App/Info.plist` に定義済み。

## ログ/計測
- 現状: `print` ログのみ。OSLog、FPS/レイテンシ、温度/サーマル状態監視は未導入。

## 参考資料
- `README.md`: パイプライン説明と抜粋コード
- `Documentation/PoseNetPipeline.png`, `Documentation/PoseNetVisualization.png`

