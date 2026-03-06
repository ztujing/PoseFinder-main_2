# PLAN-0009: 未完項目完了（MVP 完全化ステップ1）

- **Date**: 2026-03-06
- **Owner**: @tujing
- **Scope**: FE
- **Status**: Draft

## 1. 背景 / 目的（Context & Goals）

- 課題: 0006/0007 の impl-report が Partially Done で、自動テスト未実施、specs 未更新、DoD 未充足。これにより MVP の品質保証が不十分。
- 目的: 未完項目を完了させ、MVP（Recording + Session Replay）の安定性を確保。撮影→保存→再生のユースケースを自動テストでカバーし、specs を最新に保つ。

## 2. 非目標（Non-Goals）

- 新機能追加（0008 Follow-ups やフォーム採点）。
- クラウド同期や DB 導入。

## 3. 影響範囲（Impact）

- UI: テスト追加で UI 導線変更の検証強化。
- DB: なし（ファイルベース）。
- セキュリティ/性能/可用性: テスト追加で品質向上。
- リリース/運用: なし。

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）

- 代替案A: 手動確認のみ継続（利点: 迅速、欠点: 回帰リスク高、却下: 品質保証不足）。
- 代替案B: フル E2E テスト導入（利点: 包括的、欠点: 複雑性高、却下: MVP スコープ外）。
- 選定理由: UI テストでバランスを取る。

## 5. 実装方針（Design Overview）

- テスト: PoseFinderTests に UI テスト追加（XCTest）。
- specs 更新: ui.md/tech.md に未反映内容を追記。
- DoD: チェックリスト再実行。

## 6. 実装手順（Implementation Steps）

1. 自動テスト追加: PoseFinderTests に UI テストケース作成（撮影完了遷移、Pose 同期表示）。
2. specs 更新: ui.md に Pose 同期オーバーレイ追記、tech.md に座標系互換追記。
3. DoD チェック: チェックリスト実行・確認。

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）

- ユニット: UI テスト実行。
- DoD:
  - [ ] 主要ユースケース自動化
  - [ ] specs 更新
  - [ ] リリースノート更新

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）

- ロールバック: テスト失敗時、手動確認に戻す。
- リスク: テスト追加でビルド失敗（軽減: 段階的追加）。
- 監視: なし。

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）

- `docs/tasks/0009-20260306-mvp-completion/impl-report.md`
- `docs/specs/ui.md` / `docs/specs/tech.md`

## 10. 参照（References）

- 0006/0007 impl-report