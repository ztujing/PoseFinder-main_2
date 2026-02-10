# AGENTS — リポジトリ運用規約（SSOT）

本書は、AIエージェント（Claude Code / GitHub Copilot / Codex CLI 等）と開発者が従う **単一の出典** です。
「**計画 → 実装 → 報告**」および **ADR** を中核としたドキュメント運用、開発ルール、命名規約をここに集約します。

> すべての応答・コメントは **日本語** で記述してください。
> **ログ出力のエラーなどは英語** で記述してください。

---

## 1. プロジェクト構成 / モジュール配置

```
/repo-root
  AGENTS.md     # ← 本ファイル（規約の SSOT）
  docs/         # ← ドキュメントの正本（本規約、設計、仕様、タスクごとの計画・報告）
    tasks/      # ← 1タスク＝1フォルダで Plan / Tasks / Impl Report / Notes を集約（＋ draft.md で次タスクの仕様ドラフトを管理）
    adr/        # ← 重要な設計判断（ADR）
    specs/      # ← プロジェクト全体の仕様・設計（コードと同期する正本）
    templates/  # ← PLAN / TASKS / IMPL / ADR などのテンプレート
    README.md   # 最小の導線（本 AGENTS へリンク）
```

---

## 2. ドキュメント出力先・命名規約

同一タスクの **計画（Plan）** と **実装報告（Impl）** は **通番（####）でペア**にします（#### は Issue / ブランチと対応させる想定）。
`<slug>` は英小文字ケバブ（例: `user-authn-be`）。

### 2.1 タスクフォルダ（1タスク＝1フォルダ）

1タスクごとに次のフォルダを作成します（タスクID = `####-YYYYMMDD-<slug>`）。

- **タスクフォルダ（Task Folder）**:
  `docs/tasks/####-YYYYMMDD-<slug>/`

タスクフォルダ内に、以下のファイルを配置します。

- **計画（Plan）**: タスクの全体方針・設計

  - パス: `docs/tasks/####-YYYYMMDD-<slug>/plan.md`
  - 役割: Context/Goals/Non-Goals、Impact、Alternatives、Design Overview、Implementation Steps、Test Plan、Rollback、Artifacts を記載
  - ステータス: `Draft` → `Approved`

- **実装タスク一覧（Tasks）**: AIコーディングや実装作業の進捗管理

  - パス: `docs/tasks/####-YYYYMMDD-<slug>/tasks.md`
  - 役割: `plan.md` の Implementation Steps を 2階層のチェック付き箇条書きに分解した「実作業リスト」
    - 第1階層: 大きな作業単位（例: API 設計、UI 実装、テスト追加）
    - 第2階層: 実装可能な粒度のタスク（例: `GET /documents` のバリデーション追加 など）
  - 運用: 実装中はこのファイルのチェックボックスを更新して進捗を管理する

- **実装報告（Impl Report）**: 実装結果のサマリ・証跡

  - パス: `docs/tasks/####-YYYYMMDD-<slug>/impl-report.md`
  - 役割:
    - What changed（人間がレビューしやすい要約を必ず先頭に記載）
    - Finalized Specs（OpenAPI/Storybook/DDL 等へのリンク）
    - Deviation from Plan（Plan との違い）
    - Evidence（テスト結果・ベンチマーク）
    - Operational Notes（運用上の注意）
    - Follow-ups（残課題）
  - ステータス: `Partially Done` → `Done`
  - 備考: 原則として履歴として固定し、後日の修正は「Amendments/Errata」セクションで追記する

- **補足ノート（任意）**:

  - パス: `docs/tasks/####-YYYYMMDD-<slug>/notes.md`
  - 役割: 壁打ちメモ / 打ち合わせメモ / 一時的な検討事項など、Plan/Impl に載せないラフな情報

- **画像・添付（任意）**:

  - パス: `docs/tasks/####-YYYYMMDD-<slug>/images/`
  - 役割: 画面キャプチャ・図版・一時的な添付ファイルなど

- **仕様ドラフト共通メモ（任意）**:
  - パス: `docs/tasks/draft.md`
  - 役割: 次に着手するタスクのラフな仕様・要件を Markdown で書き出す一時的なドラフト置き場  
    （内容が固まったら新しいタスクフォルダの `plan.md` / `tasks.md` に整理してコピーする）

### 2.2 ADR / 仕様・設計（Specs）

- **ADR（重要な設計判断の履歴）**:

  - パス: `docs/adr/####-YYYY-MM-DD-<slug>.md`
  - 1決定1ファイル。長期的に影響のある設計判断のみを記録する

- **仕様・設計（API/UI/ER・画面遷移・全体構成など）**:

  - パス: `docs/specs/*`
  - 役割: プロジェクト全体の概要と契約仕様の「正本」。現在のコード・挙動と一致していることを保証する。
  - ベースとなるファイル:
    - `docs/specs/product.md`
      - 製品・プロジェクトの目的、ターゲットユーザー、主要機能、ビジネス目標など
      - 「なぜ/誰向け/何を実現するか」を明確にし、AI の提案に必要な背景を共有する
    - `docs/specs/tech.md`
      - 使用する技術スタック（言語・フレームワーク・ライブラリ）、技術的制約、開発ツールなど
      - 技術面での制約・選択を明文化し、AI がコード生成・実装提案を行う際のガイドとする
    - `docs/specs/structure.md`
      - プロジェクト構成（ディレクトリ構造、命名規則、アーキテクチャ上の決定事項など）
      - コードベースや配置・構成のルールを定義し、開発の整合性や保守性を高める
    - `docs/specs/ui.md`
      - UI/UX 全般の方針（レイアウト、タイポグラフィ、カラー、フォーム、アクセシビリティ、コンポーネント設計など）
      - フロントエンドの見た目や挙動を実装・変更する際のルールを定義する
  - 方針:
    - 振る舞いに影響するコード変更（API/DB/UI/バッチ等）がある場合、必ず同一 PR 内で該当する `docs/specs/*` を更新する。
    - **Plan 作成時**や「今回の仕様を `specs` に反映する」という指示がある場合、`product.md` / `tech.md` / `structure.md` / `ui.md` に必要な追記・修正を行い、現状のコードと仕様が一致するようにする。

- **テンプレート**:
  - `docs/templates/plan.md`
  - `docs/templates/tasks.md`
  - `docs/templates/impl-report.md`
  - `docs/templates/adr.md`

**ステータス**:

- Plan (`plan.md`): `Draft` → `Approved`
- Impl Report (`impl-report.md`): `Partially Done` → `Done`
- ADR: `Proposed` → `Accepted` / `Rejected` / `Superseded by ADR-XXXX`
  （置換時は新ADRに **Supersedes**、旧ADRの **Status** を “Superseded by …” に更新。本文は改変しない）

---

## 3. フロー（Plan → Implement → Report → ADR）

1. **Issue 作成**

   - 目的／非目標／受入基準（DoD）を記載。必要なラベルを付与。

2. **ブランチ作成**

   - 例：`feature/####-<slug>`（または `hotfix/####-<slug>`）。

3. **仕様ドラフト作成（任意）**

   - 必要に応じて、`docs/tasks/draft.md` に次のタスクの仕様・要件をラフに記述する。
   - Issue だけでは書ききれない長めの仕様、UI 案、API イメージなどを Markdown で自由に書いてよい。
   - 内容が固まったら、次の「タスクフォルダ作成」以降で正式な `plan.md` / `tasks.md` に落とし込む。

4. **タスクフォルダ作成**

   - パス: `docs/tasks/####-YYYYMMDD-<slug>/`
   - `docs/templates/plan.md` / `docs/templates/impl-report.md` などからコピーして初期ファイルを作成する（必要に応じて `tasks.md` もテンプレートから作成）

5. **Plan 作成（壁打ち → 事前計画）**

   - 生成先：`docs/tasks/####-YYYYMMDD-<slug>/plan.md`（Status: `Draft`）
   - 内容：Context/Goals/Non-Goals、Impact、Alternatives、Design Overview、Implementation Steps、Test Plan、Rollback、Artifacts。
   - **PR 作成 → レビュー承認で `Approved`**。Approved になるまで実装は開始しません。

6. **タスク分解 / Tasks 作成**

   - `plan.md` の Implementation Steps に基づき、`docs/tasks/####-YYYYMMDD-<slug>/tasks.md` に 2階層のチェック付き箇条書きで実装タスクを作成する。
   - AIコーディングや日々の実装は、この `tasks.md` の順序に沿って進める。

7. **実装**

   - 実装の進捗に応じて、`tasks.md` のチェックボックスを更新する。
   - 必要に応じて `notes.md` に検討メモやログを残す。
   - API/UI/DB は **spec-first / code-first** のいずれかを **AGENTS で定義した方向**に合わせて更新。

8. **テスト & 検証**

   - 単体/E2E/負荷/セキュリティ（該当範囲）を実施。

9. **Impl Report 作成（実装結果の仕様化）**

   - 生成先：`docs/tasks/####-YYYYMMDD-<slug>/impl-report.md`（Status: `Partially Done`→`Done`）
   - 記載：What changed（サマリ必須）、Finalized Specs（OpenAPI/Storybook/DDL等へのリンク）、Deviation from Plan、Evidence（テスト結果・ベンチ）、Operational Notes、Follow-ups。
   - **原則不変（履歴）**。後日の軽微修正は本文を書き換えず **「Amendments/Errata」追記**と **PR リンク追加**のみ可。

10. **コードレビュー & マージ / リリース**

- PR 本文に Issue・Plan・Impl・Specs・（必要なら）ADR を必ずリンク。
- マージ後、タグ付与・リリースノート更新。

11. **ADR 追加（必要時）**

- 長期影響のある設計判断は `docs/adr/####-YYYY-MM-DD-<slug>.md` に **1決定1ファイル**で記録。
- 置換時は **Supersedes / Superseded by** を相互に明記（旧 ADR 本文は改変しない）。

12. **アーカイブ & 索引更新（定期）**

- `docs/tasks/####-YYYYMMDD-<slug>/` をタスク完了後、四半期ごとなどのタイミングで `docs/tasks/archive/YYYY/QN/` へ移動。
- 必要に応じて `docs/tasks/rollups/ROLLUP-YYYY-QN.md`（総括）を作成し、主要変更点を要約。

---

## 4. ビルド / テスト / 開発コマンド

---

## 5. コーディングスタイル / 命名

**TypeScript / React**

- インデント 2 スペース / 厳格な型付け
- コンポーネントは `PascalCase`、hooks/utilities は `camelCase`
- `frontend` 配下で ESLint（`npm run lint`）
- フロントエンドの見た目や挙動を実装・変更する際は、`docs/specs/ui.md` に定義された UI ガイドライン（レイアウト/カラー/タイポグラフィ/フォーム/アクセシビリティ/コンポーネント設計など）に従う。必要に応じて `ui.md` を更新してから実装する。

---

## 6. コミット / Pull Request

**コミット**

- 短い命令形サマリ、必要ならスコープ接頭辞（`auth:`, `orders:` など）
- 英日いずれも可。**1コミット1論理変更** を心がける

**PR**

- 目的 / 関連 Issue / テスト結果・スクショ / ロールアウト考慮点
- コンフィグやスキーマ変更は必ず明示
- Plan/Impl/ADR/Specs へのリンクを添付

## 7. コメント

- 日本語で簡潔に記述する（英語はログ出力のエラー等のみ）。
- 行ごとの逐次解説は避けるが、5行程度以上のロジックには先頭に1行コメントを記述する。
- 複雑なロジックや副作用がある箇所のみ追加コメントを検討する。
- 詳細な仕様・背景・議論は `docs/`（Plan/Impl/ADR/Specs）に記述する。
- 変更で意味が変わる場合はコメントも必ず更新する（コメントと実装の乖離を禁止）。
- 固有名詞・用語はプロジェクト内で統一（`docs/specs` の語彙に従う）。
- TODO は目的が明確な1行に限定する。
- 同じ目的の変数や関数は並べて宣言する（例：エラーハンドラ群、変換関数群、ある目的に用いる変数群）
- 処理や意味の塊ごとに 1行分、空行を入れる
- Mermaid（` ```mermaid `）で図を書く場合、**丸括弧 `(` `)` を使用しない**（ノード定義/ラベル内を含む）。必要なら表現を言い換えるか、`[]` / `{}` など括弧以外の形状記法で代替する。

**必ず書く場所**

- **ファイル先頭**：目的・入出力・依存・副作用
- **セクション見出し**：意味が似ている関数群が続く場合は、その前に `// --- Section ---`
- **3行以上のif/for/whileロジック先頭**: 処理概要を記述 `// 簡潔に何をしているかを記述`。ただし、guard目的のifではコメントは不要。
- **関数・公開変数のみ JSDoc**：概要を1行で記述。 関数は `@param`, `@returns`, `@throws`, `@remarks`

---

## 8. AIエージェント向けコンテキスト / 指示

このリポジトリでは、AIエージェントに対して以下の前提・優先順位でコンテキストを解釈することを期待します。

### 8.1 コンテキストの優先順位

1. **AGENTS.md（本ファイル）**
   - すべての規約・フローの SSOT。矛盾がある場合は本ファイルを優先する。
2. **仕様・設計（`docs/specs/*`）**
   - 特に `product.md` / `tech.md` / `structure.md` は、プロジェクト全体の前提・技術選択・構成ルールを定義する。
   - コード提案・設計提案を行う際は、必ずこれらの内容に整合するようにする。
3. **タスク単位のドキュメント（`docs/tasks/####-YYYYMMDD-<slug>/`）**
   - `plan.md` / `tasks.md` / `impl-report.md` / `notes.md` は、各 Issue / ブランチに紐づくログ・計画・実装記録として扱う。
4. **その他ドキュメント（`docs/README.md` / 旧プロジェクトの docs 等）**
   - 参考情報として利用するが、AGENTS.md / specs / tasks の内容と矛盾しない範囲で扱う。

### 8.2 プロジェクト準備時のAIのふるまい

- 新規プロジェクトや大きめの新規開発案件で呼び出された場合:
  - まず `docs/specs/product.md` / `tech.md` / `structure.md` を読み、内容がない場合はユーザーと対話しながら埋める。
    - 例: 「product.md の 1. プロジェクト概要から順に埋めていきましょう」のように対話をリードする。
  - 概要設計が固まり次第、必要に応じてフレームワーク導入や Docker 構成の雛形を提案する（実装はユーザーの指示に従う）。
  - 仕様や方針に影響する決定が出た場合は、`product.md` / `tech.md` / `structure.md` に反映するべきかを常に検討し、必要なら更新案を提示する。

### 8.3 Issueごとの実装フローにおけるAIの役割

ユーザーは、Issue 単位で次のような指示を行う前提とします。AI はそれぞれに対し、以下のように振る舞います。

- **PLAN フェーズ（タスクフォルダ / `plan.md`）**

  - AI は、Issue の背景・やりたいこと・懸念点をヒアリングします。特別な指示があるまで、実装PLANは作成しません。
    - タスクによっては、`docs/tasks/draft.md` から概要を読み込んでと指示する場合もあります。その場合は、そちらを読み込み、そのうえでヒヤリングを継続します。
  - ある程度まとまってきたら、「実装PLANの作成」が支持されます。
    - 指示例: 「タスクフォルダを作成し、実装PLANを作って」。
  - AI は、必要に応じてタスクID（`####-YYYYMMDD-<slug>`）をユーザーに確認しつつ、`docs/tasks/####-YYYYMMDD-<slug>/plan.md` をテンプレートから生成する。
  - `plan.md` の内容は `docs/specs/*` と矛盾しないようにし、矛盾が疑われる場合はユーザーに確認した上で specs 側の更新案も提案する。

- **TASKS フェーズ（`tasks.md`）**

  - 指示例: 「実装PLANから、実装タスクを作って」。
  - AI は、`plan.md` の「6. 実装手順（Implementation Steps）」を読み、`docs/templates/tasks.md` に従って `tasks.md` に 2階層のチェックリストを作成する。
  - タスクの粒度が粗すぎる/細かすぎる場合は、ユーザーに確認しながら分割・統合の提案を行う。

- **IMPL フェーズ（実装）**

  - 指示例: 「タスクに基づいて実装して」。
  - AI は `tasks.md` の順序に沿って実装を進めることを基本とし、完了したタスクにはチェックを付けるパッチを提案する。
  - 実装中に仕様変更が必要だと判断した場合は、`plan.md` / `tasks.md` / `docs/specs/*` への反映が必要かどうかをユーザーに問いかける。

- **REVIEW 準備（`impl-report.md`）**

  - 指示例: 「実装レポートを作成して」。
  - AI は `docs/templates/impl-report.md` に従い、`impl-report.md` を生成・更新する。
    - 特に「What changed」のサマリを人間がレビューしやすい形で充実させる。

- **AI REVIEW**

  - 指示例: 「実装をレビューして」。
  - AI は `plan.md` / `tasks.md` / `impl-report.md` / 関連コードを突き合わせ、仕様との齟齬・リスク・改善余地をコメントとして提示する。
  - 必要に応じて、追加テストやリファクタリングの提案も行う。

- **FIX / HUMAN REVIEW**
  - 指示例: 「指摘をもとに修正して」など。
  - AI は指摘事項を反映するパッチを提案し、その結果を `impl-report.md` / `tasks.md` にも反映する。
  - HUMAN REVIEW フェーズでは、`impl-report.md` を前提に人間がレビューしやすいよう、説明の一貫性を保つ。

### 8.4 ADR に関するAIの支援

- コード変更や仕様変更が、これまでの方針から大きく外れる場合、または複数選択肢の中から 1 つを選ぶ設計判断が必要な場合、AI は ADR 作成を提案してよい。
- 指示例: 「この変更は ADR にしたほうがいい？」への対応として:
  - 影響範囲や長期的な影響を簡潔に整理し、ADR を作るべきかどうかの判断材料を提示する。
  - 作成する場合は、`docs/adr/####-YYYY-MM-DD-<slug>.md` のドラフトをテンプレートに沿って生成する。
- 既存の ADR を置き換える内容であれば、`Supersedes` / `Superseded by` の関係を AI 側からも明示的に提案する。

### 8.5 その他AIへの注意事項

- すべての応答は日本語で行い、ログ出力のエラーなどのみ英語を用いる（本ファイル冒頭のルールを遵守）。
- コード変更と `docs/specs/*` の内容が不整合になりそうな場合は、必ずユーザーに確認し、必要なら specs 更新案を一緒に提示する。
- 大きなリファクタリングや設計変更を提案する際は、まず PLAN / ADR レベルでの検討を促し、いきなり大規模なパッチを出さない。
