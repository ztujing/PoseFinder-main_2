# IMPL-0004: SwiftUI移行フェーズ3（セッション詳細・再生UI）

- **Date**: 2026-01-04
- **Owner**: @tujing
- **Related PLAN**: [PLAN-0004-session-detail](../plans/PLAN-0004-session-detail.md)
- **PRs**: （未作成）
- **Status**: Done

## 1. 実装サマリ（What Changed）
- 録画済みセッションの一覧/詳細を扱うモデル `RecordingSession` とリポジトリ `RecordingSessionRepository` を実装し、`Documents/Sessions/<sessionId>/` 以下からメタ情報・動画・Pose ファイルを読み込めるようにした。
- SwiftUI の `SessionListView` / `SessionListViewModel` を追加し、録画完了通知（`Notification.Name.recordingSessionDidComplete`）をトリガにセッション一覧を自動リフレッシュする履歴画面を実装。
- SwiftUI の `SessionDetailView` / `SessionDetailViewModel` を追加し、動画再生（`AVPlayer` + `VideoPlayer`）、Pose プレビュー（`PosePreviewView`）、メタ情報表示（デバイス/カメラ/ファイル情報）を 1 画面で確認できるセッション詳細 UI を実装。
- UIKit の `PoseImageView` をラップする `PosePreviewView`（`UIViewRepresentable`）を実装し、SessionDetailView から Pose オーバーレイ画像を SwiftUI 上に安全に組み込めるようにした。
- 表示不具合対策として、`PoseImageView` が `image` サイズを intrinsicContentSize として主張しないよう `intrinsicContentSize = .zero` をオーバーライドし、`PosePreviewView.makeUIView` で `PoseImageView(frame: .zero)` を生成するようにすることで、Pose プレビューが下部の Text/メタ情報を覆い隠してしまう問題を解消。
- Pose プレビューのデータパス強化として、`RecordingSessionManager` に一時バッファ `pendingPoses` を導入し、最初の動画フレームより先に到着した Pose を保持→`firstVideoTimestamp` 設定直後にまとめて `pose.ndjson` へ書き出すようにして、レース条件により Pose データが 0 行のまま終了してしまう問題を低減。
- `RecordingSessionRepository.loadFirstPoseFrame` にファイルサイズ 0 を検知するロジックと専用エラー `RepositoryError.emptyPoseFile` を追加し、「Pose データが記録されませんでした（録画が短すぎた可能性があります）。」というユーザーフレンドリーなメッセージで空ファイルを扱えるようにした。

## 2. 仕様の確定内容（Finalized Specs）
- **セッション一覧/詳細の構成**
  - `SessionListView` から `SessionDetailView` へ `NavigationLink` で遷移し、`SessionListViewModel` が `RecordingSessionRepository.fetchSessions()` を通じてセッション一覧を取得・ソート。
  - `SessionDetailView` は `SessionDetailViewModel` を介して `RecordingSessionRepository.reloadSession(at:)` / `loadFirstPoseFrame(from:)` を呼び出し、動画プレイヤー・Pose プレビュー・メタ情報を構成する。
- **Pose プレビューの UI 仕様**
  - `SessionDetailView.poseSection` では、Pose データが存在する場合に `PosePreviewView(poseFrame:)` を `frame(height: 240)` でレイアウトし、角丸矩形で表示。
  - `PosePreviewView` は `PoseImageView(frame: .zero)` を生成し、バックグラウンドとしてダミーの黒一色画像を生成 (`makePlaceholderImage`) した上で `PoseImageView.show(scaledPose:studentPose:on:isFrameDraw:)` を呼び出して生徒の Pose のみを重ね描画。
  - `PoseImageView` は `intrinsicContentSize` を `.zero` に固定し、SwiftUI 側の `.frame(height: ...)` が優先されるようにすることで、画像サイズに応じてビューが縦方向に膨張しないことを保証。
- **Pose データ読み込み/エラー仕様**
  - `RecordingSessionRepository.loadFirstPoseFrame(from:)` は:
    - ファイル不存在 → `RepositoryError.fileNotFound`
    - ファイルサイズ 0 → `RepositoryError.emptyPoseFile`（「Pose データが記録されませんでした（録画が短すぎた可能性があります）。」）
    - 先頭行から有効な JSON が見つからない → `RepositoryError.poseFrameNotFound`（「Pose データの先頭フレームを読み込めませんでした。」）
  - `SessionDetailViewModel` はこれらのエラーを `errorMessage` に格納し、`SessionDetailView` の Pose セクションでメッセージ表示。
- **Pose データ記録仕様（録画側）**
  - `RecordingSessionManager.appendPose` は、`state.firstVideoTimestamp` 未設定の間は Pose を `pendingPoses` に一時保存し、`appendVideo` の最初のフレームで `firstVideoTimestamp` を確定した直後に `pendingPoses` をまとめてシリアライズして `pose.ndjson` へ書き出す。
  - `pendingPoses` の上限は 300 件（`Constants.maxPendingPoses`）とし、超過時は古いデータから削除してメモリ使用量を抑制。

## 3. 計画との差分（Deviation from Plan）
- PLAN-0004 では主に UI/遷移の追加とファイル読み込みロジックの実装を想定していたが、実装中に以下の問題が判明し、追加で対応を行った:
  - SwiftUI × UIKit ラップにおいて、`PoseImageView` が intrinsicContentSize により SwiftUI のレイアウトを壊し、Pose プレビューが下部メタ情報を覆い隠してしまう不具合。→ `intrinsicContentSize = .zero` と `frame: .zero` で解消。
  - 録画開始直後に Pose 検出が動画フレームより先に完了するケースで、`firstVideoTimestamp` 未設定のため Pose が破棄され `pose.ndjson` が 0 行のままになる不具合。→ `pendingPoses` バッファと初回フレーム時のフラッシュ処理で改善。
  - `pose.ndjson` が生成されているものの中身が空の場合に、`poseFrameNotFound` との区別がつきづらかったため、`emptyPoseFile` を新設してエラーメッセージを明確化。
- これらの対応は PLAN-0004 のスコープ（セッション詳細表示の安定化）と整合するため、本 Impl Report に含める。

## 4. テスト結果（Evidence）
- 手動テスト:
  - 録画完了後、ホーム → セッション履歴 → 任意の完了セッション → `SessionDetailView` で動画再生と Pose プレビューが表示されることを確認。
  - Pose プレビュー表示時も、下部の Text / メタ情報セクションが消えずにスクロール可能であることを確認（以前の不具合では Pose プレビューが画面下部を覆っていた）。
  - 短時間の録画や Pose が検出されなかった録画について、`pose.ndjson` が 0 バイトの場合には「Pose データが記録されませんでした（録画が短すぎた可能性があります）。」と表示されることを確認。
  - 通常の録画（十分な長さ）では `pose.ndjson` にデータが書き込まれ、セッション詳細画面の Pose プレビューが正しく表示されることを確認。
- 自動テスト:
  - なし（現時点では手動テストでカバー）。
- 受入基準（DoD）:
  - [x] SwiftUI 画面で録画済みセッションの動画と Pose プレビューを再生できる。
  - [x] セッションメタ情報（日時/ファイルパス/サイズ等）が表示される。
  - [x] Pose プレビュー表示時にレイアウト崩れを起こさず、下部メタ情報が確認できる。
  - [x] `pose.ndjson` が空/不正な場合にクラッシュせず、ユーザーに分かりやすいエラーを表示する。
  - [ ] Repository / ViewModel の単体テスト整備。
  - [ ] 監視・アラート整備、リリースノート更新。

## 5. 運用ノート（Operational Notes）
- 新たな設定値や環境変数の追加はなし。
- セッション一覧は `Documents/Sessions/` 直下のディレクトリを走査するため、古い不完全セッションや手動削除されたセッションが混在する場合は、エラーメッセージで通知される（クラッシュはしない想定）。
- ロールバックが必要な場合は、SwiftUI の `SessionListView` / `SessionDetailView` をルートから外し、従来の UIKit ベースのセッション詳細導線へ戻すことで復旧可能。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）
- Pose プレビューは現状静止画 1 フレームのみ（先頭フレーム）を表示しており、動画と同期した Pose オーバーレイ再生は未実装（将来的に Canvas やタイムライン連動を検討）。
- Repository / ViewModel レイヤーに対する自動テストが未整備であり、ファイル構成変更時のリグレッション検出が難しい。
- `RecordingSessionManager` の `pendingPoses` はシンプルなバッファ実装のため、将来的に録画/検出パイプラインの見直し時にはより明示的な同期モデルへ移行する余地がある。

## 7. 関連ドキュメント（Links）
- Plan: [docs/plans/PLAN-0004-session-detail.md](../plans/PLAN-0004-session-detail.md)
- 仕様: [docs/specs/001_概要設計.md](../specs/001_概要設計.md), [docs/specs/002_画面遷移図.md](../specs/002_画面遷移図.md)
- 既存 Impl: [docs/impl-reports/IMPL-0001-video-and-pose-json.md](IMPL-0001-video-and-pose-json.md), [docs/impl-reports/IMPL-0002-swiftui-wrapper.md](IMPL-0002-swiftui-wrapper.md), [docs/impl-reports/IMPL-0003-swiftui-ui-layer.md](IMPL-0003-swiftui-ui-layer.md)

## 8. 追記/正誤
- なし

