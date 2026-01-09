# PLAN-0005: docs/specs（product/structure/tech/ui）初期作成

- **Date**: 2026-01-09
- **Owner**: @tujing
- **Scope**: Docs
- **Status**: Approved

## 1. 背景 / 目的（Context & Goals）

- `docs/specs/product.md` / `structure.md` / `tech.md` / `ui.md` が空のため、仕様の正本として最低限の内容を整備する。
- `docs/archive/specs/*`（旧仕様）および `docs/archive/specs/検証実装/*`（検証実装の整理）を参照し、現状コードと矛盾しない形で再構成する。

## 2. 非目標（Non-Goals）

- 新機能の実装やリファクタは行わない（ドキュメント整備のみ）
- 仕様の完全確定（採点/同期再生/クラウドなどの将来要件）は行わない

## 3. 影響範囲（Impact）

- Docs: `docs/specs/*` の新規記述（正本の整備）
- UI/コード: 変更なし

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）

- 代替案A: `docs/archive/specs/*` をそのまま正本に昇格する
  - 利点: 早い
  - 欠点: 現状の `docs/specs/*` と役割が逆転し、運用規約（AGENTS）と齟齬が出る
- 本案: `docs/specs/*` を正本として再構成し、`docs/archive/*` は参考に留める
  - 利点: 規約どおりの導線・運用になる
  - 欠点: 記述の移植・再整理が必要

## 5. 実装方針（Design Overview）

- 仕様は「現状のコード（MVP）に合わせる」ことを優先し、未実装部分は「非目標」または「既知課題」として明確に分離する。
- 参照元（archive/specs）のリンクを貼り、過去経緯を追えるようにする。

## 6. 実装手順（Implementation Steps）

1. `docs/archive/specs/*` と `docs/archive/specs/検証実装/*` を読み、要点を抽出する
2. `docs/specs/product.md` を作成（目的・ユーザー・主要体験・スコープ）
3. `docs/specs/structure.md` を作成（構成・保存形式・フロー）
4. `docs/specs/tech.md` を作成（技術スタック・フォーマット）
5. `docs/specs/ui.md` を作成（画面遷移・画面仕様・例外系）
6. `docs/tasks/0005-20260109-specs-baseline/impl-report.md` を作成し、成果物へリンクする

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）

- [ ] `docs/specs/*` が空でなく、最低限の章立てがある
- [ ] `docs/archive/specs/*` への参照リンクがある
- [ ] 既存コード（保存形式/画面構成）と矛盾しない

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）

- ロールバック: `docs/specs/*` の変更を revert するだけ
- リスク: 仕様が現状コードとズレると、以降の変更で判断を誤る
- 軽減: 参照元を明記し、「未実装/既知課題」を明確に書く

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）

- `docs/specs/product.md`
- `docs/specs/structure.md`
- `docs/specs/tech.md`
- `docs/specs/ui.md`
- `docs/tasks/0005-20260109-specs-baseline/impl-report.md`

## 10. 参照（References）

- `docs/archive/specs/001_概要設計.md`
- `docs/archive/specs/002_画面遷移図.md`
- `docs/archive/specs/検証実装/OVERVIEW.md`
- `docs/archive/specs/検証実装/CODEMAP.md`
