# BACKLOG

小粒度のチケット候補一覧。各項目はタイトル / 目的 / 完了条件(DoD) / 参考パス / 想定影響範囲 を記載します。

1) 計測: FPS/レイテンシの基本ログ
- 目的: 実行時パフォーマンスを可視化
- DoD: フレーム処理時間/スループットをコンソール/OSLogに記録
- 参考: `PoseFinder/UI/ViewController.swift`, `PoseFinder/Utils/VideoCapture.swift`
- 影響: パフォーマンス, ログ

2) 計測: サーマル状態/CPU使用傾向の収集
- 目的: 熱暴走や性能低下を把握
- DoD: サーマル通知受信・状態ログ、CPU推定値の記録
- 参考: `ViewController`
- 影響: 性能/省電力

3) ML Kit オプションの明示設定
- 目的: 検出安定性の向上（モード/人数）
- DoD: `PoseDetectorOptions` を見直し、設定値を定数化
- 参考: `PoseFinder/UI/ViewController.swift`
- 影響: 推論/安定性

4) EMA スムージング（関節座標）
- 目的: フレーム間ジッター低減
- DoD: 直近Nフレームでの指数移動平均を適用
- 参考: `ViewController`（推論出力処理部）
- 影響: 可視化の安定性

5) 外れ値除去（信頼度/速度閾値）
- 目的: 誤検出の瞬間的スパイクの抑制
- DoD: inFrameLikelihood/移動量に基づく棄却ルール追加
- 参考: `ViewController`
- 影響: 品質/安定性

6) スコアリング閾値の設定ファイル化
- 目的: `ScaledPoseHelper` の閾値調整を容易化
- DoD: 値を定数/設定化、ドキュメント整備
- 参考: `PoseFinder/Pose/ScaledPoseHelper.swift`
- 影響: 評価/UX

7) オーバーレイの解像度適応
- 目的: 線幅/点サイズを端末解像度に応じ最適化
- DoD: 動的スケーリングの導入
- 参考: `PoseFinder/UI/PoseImageView.swift`
- 影響: 表示品質

8) 関節ラベル/凡例表示
- 目的: 学習・デバッグ支援
- DoD: 関節名/スコアの可視化トグル
- 参考: `PoseImageView`
- 影響: UI/UX

9) ログ整備（OSLog/Signpost）
- 目的: 本番向け軽量ログ
- DoD: カテゴリ/レベル/プライバシーフラグの定義
- 参考: `ViewController`
- 影響: 運用

10) エクスポート: 画像/動画保存
- 目的: 共有/検証用途
- DoD: フレームにオーバーレイ合成してフォト保存
- 参考: `PoseImageView`
- 影響: 権限/ストレージ

11) エクスポート: キーポイントJSON
- 目的: 解析・学習用データ生成
- DoD: `Pose` を JSON にシリアライズし保存
- 参考: `Pose`, `Joint`
- 影響: データ/プライバシー

12) マルチパーソン対応確認/切替
- 目的: 複数人環境での挙動保証
- DoD: ML Kit の人数設定確認、UI切替追加
- 参考: `ViewController`
- 影響: パフォーマンス/UX

13) 動画側のフレームサンプリング
- 目的: 教師側負荷低減
- DoD: Nフレーム毎推論、補間表示
- 参考: `setupAndBeginCapturingMovieFrames`
- 影響: パフォーマンス

14) バンドル動画の差し替え/外部読み込み
- 目的: 教師データの更新性向上
- DoD: フォト/ファイルからの読み込み導線
- 参考: `PlayerView`, `ViewController`
- 影響: 権限/UX

15) PoseNet 経路の整理
- 目的: 併存コードの役割明確化
- DoD: 切替/廃止/保存の方針決定と反映
- 参考: `PoseFinder/Model/*`, `PoseBuilder*`
- 影響: 技術負債

