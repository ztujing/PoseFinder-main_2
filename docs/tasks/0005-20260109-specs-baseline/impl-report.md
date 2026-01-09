# IMPL-0005: docs/specs（product/structure/tech/ui）初期作成

- **Date**: 2026-01-09
- **Owner**: @tujing
- **Related PLAN**: PLAN-0005
- **PRs**: -
- **Status**: Done

## 1. 実装サマリ（What Changed）

- `docs/specs/*` の空ファイルを埋め、仕様の正本として最低限の内容を追加した。
- 旧仕様（`docs/archive/specs/*`）と検証実装の整理（`docs/archive/specs/検証実装/*`）を参照し、現状コード（セッション保存/一覧/詳細）と矛盾しない記述に揃えた。

## 2. 仕様の確定内容（Finalized Specs）

- Product: `docs/specs/product.md`
- Structure: `docs/specs/structure.md`
- Tech: `docs/specs/tech.md`
- UI: `docs/specs/ui.md`

## 3. 計画との差分（Deviation from Plan）

- なし

## 4. テスト結果（Evidence）

- ドキュメント変更のみのため、自動テストは未実施

## 5. 運用ノート（Operational Notes）

- 今後、挙動が変わるコード変更を行う場合は、同一 PR で `docs/specs/*` を更新して整合性を保つ。

## 6. 既知の課題 / 次の改善（Known Issues / Follow-ups）

- 再生時の Pose と動画の完全同期（現状は Pose の先頭フレームプレビューまで）
- 計測（fps/latency/電力）やログ整備（OSLog 等）

## 7. 関連ドキュメント（Links）

- `docs/archive/specs/001_概要設計.md`
- `docs/archive/specs/002_画面遷移図.md`
- `docs/archive/specs/検証実装/OVERVIEW.md`

