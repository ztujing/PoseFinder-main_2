# IMPL-0007: 再生時に Pose を動画と同期してオーバーレイ表示

- **Date**: 2026-02-24
- **Owner**: @tujing
- **Related PLAN**: `docs/tasks/0007-20260210-pose-sync-playback/plan.md`
- **PRs**: （未作成）
- **Status**: Partially Done

## 1. 実装サマリ（What Changed）

- セッション詳細で動画の再生時刻に追従して、`pose.ndjson` の生徒Poseをオーバーレイ表示する。
- `pose.ndjson` は全フレームを読み込み、`AVPlayer` の periodic time observer で現在時刻に最も近いフレームを二分探索で引き当てる。
- 表示ズレ対策として、座標系の互換（正規化済み座標/ピクセル座標）推定と、SwiftUIのpointsとCGImageのpixels不一致の吸収を行う。

対象ファイル:

- `PoseFinder/App/Repositories/RecordingSessionRepository.swift`
- `PoseFinder/App/ViewModels/SessionDetailViewModel.swift`
- `PoseFinder/App/Views/SessionDetailView.swift`
- `PoseFinder/App/Views/PosePreviewView.swift`
- `PoseFinder/UI/PoseImageView.swift`
- `PoseFinder/Utils/PoseSerialization.swift`

## 2. 仕様の確定内容（Finalized Specs）

- UI:
  - セッション詳細の「動画」領域は `ZStack` で `VideoPlayer` と `PosePreviewView` を重ねる。
  - `currentPoseFrame` が取得できる場合は同期フレームを表示し、無い場合は `posePreview`（先頭フレーム）を表示する。
- データ:
  - `pose.ndjson` は改行区切り（NDJSON）としてチャンク読み込みし、行ごとにデコード（不正行はスキップ）して `t_ms` 昇順へ整列する。
  - `Pose` の関節座標は「ピクセル/正規化済み」を推定し、二重正規化を避ける。

## 3. 計画との差分（Deviation from Plan）

- Planでは「表示Rect補正は後回し」だったが、実運用で左上に縮む症状が出たため、points/pixels不一致と正規化の互換対応を追加した。
- `docs/specs/*` の更新は未実施（フォローアップへ移管）。

## 4. テスト結果（Evidence）

- 手動確認:
  - 動画上のPoseが左上に小さく寄る問題は解消（points/pixels不一致の修正）。
  - 再生時刻に追従してPoseが更新されることを確認。
- ビルド:
  - `xcodebuild -workspace PoseFinder.xcworkspace -scheme PoseFinder -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

受入基準（DoD）:

- [ ] `SessionDetail` で再生/一時停止/シークの一連を確認（チェックリスト化して再実行）
- [ ] `docs/specs/ui.md` 反映
- [ ] `docs/specs/tech.md` 反映（必要なら）

## 5. 運用ノート（Operational Notes）

- `AVPlayer` の time observer は `onAppear` で開始し、`onDisappear` / `deinit` で解除する（リーク防止）。
- 現状は全フレーム読み込みのため、長尺/高fpsのセッションではメモリ・待ち時間が増える可能性がある（必要なら間引き/インデックス化を別タスク化）。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）

- `docs/specs/ui.md` に「再生時のPose同期オーバーレイ」を追記する。
- `docs/specs/tech.md` に `t_ms` の引き当て（nearest + 二分探索）と座標系互換の方針を必要に応じて追記する。
- 動画の向き/ミラー（フロントカメラ）による左右反転や回転のズレが出る場合は、座標変換を追加する。

## 7. 関連ドキュメント（Links）

- `docs/tasks/0007-20260210-pose-sync-playback/plan.md`
- `docs/tasks/0007-20260210-pose-sync-playback/tasks.md`
- `docs/specs/ui.md`
- `docs/specs/tech.md`

## 8. 追記/正誤

- （なし）
