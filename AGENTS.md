# AGENTS — リポジトリ運用規約（SSOT）

本書は、AIエージェント（Claude Code / GitHub Copilot / Codex 等）と開発者が従う **単一の出典** です。
「**計画指示 → 計画 → 実装 → 報告**」を中核としたドキュメント運用、開発ルール、命名規約をここに集約します。

> すべての応答・コメントは **日本語** で記述してください。
> **ログ出力のエラーなどは英語** で記述してください。

---

## 1. プロジェクト構成とモジュール構成

**未確定**

---

## 2. ドキュメント出力先・命名規約

同一タスクの **計画（Plan）** と **実装報告（Impl）** は **通番（####）でペア**にします。
`<slug>` は英小文字ケバブ（例: `user-authn-be`）。

* **計画（Plan）**:
  `docs/plans/PLAN-####-<slug>.md`
* **実装報告（Impl Report）**:
  `docs/impl-reports/IMPL-####-<slug>.md`
* **仕様**:
  `docs/specs/*`
* **テンプレート**:
  `docs/templates/plan.md` / `docs/templates/impl-report.md`

**ステータス**:

* Plan: `Draft` → `Approved`
* Impl Report: `Partially Done` → `Done`

---

## 3. フロー（Plan → Implement → Report）

1. **ブランチ作成**

   * 例：`feature/####-<slug>`（または `hotfix/####-<slug>`）。

2. **Plan 作成（壁打ち → 事前計画）**

   * 生成先：`docs/plans/PLAN-####-<slug>.md`（Status: `Draft`）
   * 内容：Context/Goals/Non-Goals、Impact、Alternatives、Design Overview、Implementation Steps、Test Plan、Rollback、Artifacts。
   * **PR 作成 → レビュー承認で `Approved`**。Approved になるまで実装は開始しません。

3. **実装**

   * API/UI/DB は **spec-first / code-first** のいずれかを **AGENTS で定義した方向**に合わせて更新。

4. **Impl Report 作成（実装結果の仕様化）**

   * 生成先：`docs/impl-reports/IMPL-####-<slug>.md`（Status: `Partially Done`→`Done`）
   * 記載：What changed、Finalized Specs（OpenAPI/Storybook/DDL等へのリンク）、Deviation from Plan、Evidence（テスト結果・ベンチ）、Operational Notes、Follow-ups。
   * **原則不変（履歴）**。後日の軽微修正は本文を書き換えず **「Amendments/Errata」追記**と **PR リンク追加**のみ可。

---

## 4. ビルド・テスト・開発コマンド

**未確定**


---

## 5. コーディング規約と命名規則

**未確定**
