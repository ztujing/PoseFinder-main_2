# PoseFinder: UI/UX（画面・体験仕様）

- **最終更新日**: 2026-01-27
- **正本**: `docs/specs/*`（`docs/archive/specs/*` は参考資料）

## 1. UI の基本方針

- 目的は「撮影 → 保存 → 再生」でフォーム振り返りができること
- 記録の失敗（中断/未保存）はユーザーに明確に伝える
- まずは iOS 標準コンポーネント（`NavigationStack` 相当 / `List` / `VideoPlayer`）を優先し、UI の複雑化を避ける
- SwiftUI 移行中のため、撮影（UIKit）との境界は画面遷移と状態連携（通知）を最小限に保つ

## 2. 画面遷移（MVP想定）

```mermaid
graph TD
  Splash[起動画面<br/>Splash]
  Home[ホーム<br/>Training Menu List<br/>(SwiftUI)]
  MenuDetail[メニュー詳細<br/>(SwiftUI)]
  Recording[撮影<br/>Auto Record + Pose Overlay<br/>(UIKit)]
  SessionList[セッション履歴<br/>(SwiftUI)]
  SessionDetail[セッション詳細<br/>(SwiftUI)]
  Settings[設定<br/>(UIKit)]

  Splash --> Home
  Home --> MenuDetail
  Home --> SessionList
  Home --> Settings
  MenuDetail --> Recording
  SessionList --> SessionDetail
  Recording --> SessionDetail
  SessionDetail --> MenuDetail
  Settings --> Home
```

補足:

- 旧仕様図: `docs/archive/specs/002_画面遷移図.md`
- 現状の実装では、ホーム右上の「履歴」から `SessionList` → `SessionDetail` を開く（メニュー詳細から履歴へは未接続）
- 現状の実装では、撮影が正常完了した場合は `Recording` から当該セッションの `SessionDetail` へ自動遷移する
- `Splash` / `Settings` は将来想定（または既存 UIKit 画面がある場合は別途実装と紐付ける）

## 3. 画面仕様（要点）

### 3.1 ホーム（トレーニングメニュー一覧）

- 実装: `PoseFinder/App/Views/HomeView.swift`
- 要素:
  - トレーニングメニューのリスト（現状はサンプルデータ）
  - ツールバーに「履歴」導線（セッション一覧へ）

### 3.2 トレーニングメニュー詳細

- 実装: `PoseFinder/App/Views/TrainingMenuDetailView.swift`
- 要素:
  - 概要（説明文）
  - チェックポイント（フォーム観点）
  - **参考動画プレイヤー**: 設定ファイルに `videoFileName` があれば上部に自動再生・無音で表示
  - 「撮影を開始」ボタン → 撮影画面を表示

### 3.3 撮影（UIKit）

- 実装（橋渡し）: `PoseFinder/App/Views/RecordingSessionContainerView.swift`
- 実装（本体）: `PoseFinder/UI/ViewController.swift`
- 期待体験:
  - カメラプレビュー + Pose オーバーレイ
  - 収録（Video + Pose NDJSON）を同一セッションとして保存
  - 正常完了時は当該セッションの詳細画面へ自動遷移する（失敗時は1回再試行し、再失敗時は自動遷移しない）
  - 戻る操作時は「中断（保存されない）」を確認する

### 3.4 セッション履歴（一覧）

- 実装: `PoseFinder/App/Views/SessionListView.swift`
- 要素:
  - 保存済みセッションを新しい順に表示
  - 読み込み中表示、空状態、エラー表示
  - 未完了セッションは選択不可かつ注意文言を表示

### 3.5 セッション詳細

- 実装: `PoseFinder/App/Views/SessionDetailView.swift`
- 要素:
  - 動画再生（`VideoPlayer`）
  - Pose プレビュー（`pose.ndjson` の先頭フレーム + 再生時の同期オーバーレイ）
  - メタ情報（ファイル名、サイズ、デバイス/カメラ情報）

## 4. エラー/空状態の方針

- 一覧:
  - 空: 「録画済みセッションがありません」
  - エラー: `LocalizedError` の文言をそのまま表示（必要に応じて将来改善）
- 詳細:
  - 動画/pose が欠損している場合は、それぞれ「見つかりません」を表示
- 中断:
  - 「中断した場合は保存されません」を明確に表示し、破棄をデフォルトにする

## 5. アクセシビリティ / ローカライズ（当面）

- 文言は日本語をデフォルトとし、将来 `Localizable.strings` へ移行できる粒度を意識する
- タップ領域/フォントサイズは iOS 標準に追従（Dynamic Type は将来検証）
