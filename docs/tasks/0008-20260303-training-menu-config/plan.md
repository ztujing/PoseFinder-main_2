# PLAN-0008: training-menu-config

- **Date**: 2026-03-03
- **Owner**: @tujing
- **Scope**: FE
- **Status**: Draft

## 1. 背景 / 目的（Context & Goals）

- 現在はトレーニングメニューがソースコードにハードコードされている。
- 追加・編集のたびにビルドが必要でメンテナンス性が低い。
- **目的**: メニュー情報を外部ファイル（JSON＋動画）で管理し、起動時に動的に読み込めるようにする。
  - JSON を編集するだけで新しいメニューを追加できる。
  - **将来、ローカルファイルからクラウドデータベースや REST API への切り替えを見越し、Protocol ベースのデータソース抽象化により、最小限の変更で対応可能にする**。

## 2. 非目標（Non-Goals）

- クラウドデータベース（Firestore/DynamoDB/他）や REST API への移行実装（今回は実装しない）。
- 管理画面や編集UI の開発。
- オフラインキャッシング戦略の詳細実装（フレームワーク基盤のみ）。
- JSON 以外のフォーマットの対応（初期は JSON 固定）。

## 3. 影響範囲（Impact）

- **UI**: トレーニング一覧画面（[HomeView](PoseFinder/App/Views/HomeView.swift)）の背後で、データ取得が動的に変わる。ユーザー画面への影響なし。
- **ファイル**:
  - 新規リソース `Resources/training-menus.json` と `Resources/videos/*.mp4`
  - 新規ディレクトリ `PoseFinder/App/DataSources/` でプロトコル実装
  - 新規ディレクトリ `PoseFinder/App/Repositories/` で Repository パターン
- **コード**:
  - `TrainingMenuDataSource` Protocol（読み込み・キャッシュインターフェース）
  - `TrainingMenuLocalDataSource` 実装（ローカル JSON）
  - `TrainingMenuRepository` 実装（DI により DataSource を切り替え可能）
  - `HomeViewModel` 修正（Repository 経由で読み込み）
- **テスト**: Protocol に基づく Mock DataSource でユニットテスト
- **ドキュメント**: specs/structure.md、specs/ui.md へ記述、ADR 追加
- **運用**: リモートデータソースへの移行時は新規 DataSource 実装を追加し、Repository の依存性注入を切り替えるだけで完了。

## 4. 代替案とトレードオフ（Alternatives & Trade-offs）

- **A. Singleton パターン（シンプル実装）**
  - 利点: 実装がシンプル。
  - 欠点: リモートデータソース移行時にシングルトンの除去 + DI 導入が必要 → 大幅リファクタリング。
  - 却下理由: 移行時の改修コストが高い。

- **B. Repository + Protocol ベース（★選定）**
  - 利点:
    - DI により DataSource を柔軟に切り替え可能。
    - リモートデータソース移行時は新規実装を追加し、Repository の init に切り替えるだけで完了。
    - Mock DataSource でテスト容易。
  - 欠点: 初期実装が少し複雑（が、長期的には改修コスト削減）。
  - 採用理由: データソース切り替えを見越した設計コスト削減。

- **C. Plist**
  - 利点: macOS/iOS 標準で読み込み簡単。
  - 欠点: JSON より可読性・編集性が低い、API との親和性が低い。
  - 却下理由: JSON の方が外部編集・API 親和性が高い。

## 5. 実装方針（Design Overview）

### 5.1 アーキテクチャ（データソース切り替え対応）

```
HomeViewModel
    ↓ (depends on)
TrainingMenuRepository
    ↓ (DI で切り替え可能)
TrainingMenuDataSource (Protocol)
    ├─ TrainingMenuLocalDataSource (現在: ローカル JSON から読み込み)
    └─ TrainingMenuRemoteDataSource (将来: REST API/Cloud DB から読み込み)
```

### 5.2 ファイル構成

- `Resources/training-menus.json` - バンドルリソース
- `Resources/videos/*.mp4` - 参考動画
- `PoseFinder/App/Models/TrainingMenu.swift` - Model（既存、フィールド追加）
- `PoseFinder/App/DataSources/TrainingMenuDataSource.swift` - Protocol 定義
- `PoseFinder/App/DataSources/TrainingMenuLocalDataSource.swift` - ローカル JSON 実装
- `PoseFinder/App/Repositories/TrainingMenuRepository.swift` - Repository（DI層）
- `PoseFinder/App/ViewModels/HomeViewModel.swift` - 修正（Repository 経由で読み込み）
- `PoseFinder/App/Views/TrainingMenuDetailView.swift` - 修正（動画再生機能追加）

### 5.3 データモデル

TrainingMenu 型に以下フィールドを追加：

- `videoFileName: String?` - 参考動画ファイル名

JSON スキーマ例：

```json
{
  "trainings": [
    {
      "id": "squat",
      "title": "スクワット",
      "description": "...",
      "focusPoints": [...],
      "estimatedDurationMinutes": 5,
      "videoFileName": "squat-guide.mp4"
    }
  ]
}
```

### 5.4 Protocol 定義

`TrainingMenuDataSource`:

```swift
protocol TrainingMenuDataSource {
    func fetchTrainingMenus() async throws -> [TrainingMenu]
    func getVideoURL(for fileName: String) -> URL?
}
```

### 5.5 Repository パターン

`TrainingMenuRepository`:

- Constructor で `dataSource` を受け取る（DI）
- `getTrainingMenus()` → `dataSource.fetchTrainingMenus()` を呼び出し、エラーハンドリング
- キャッシュ機能（オプション）

## 6. 実装手順（Implementation Steps）

### フェーズ1: 基礎レイヤー構築

1. `TrainingMenu.swift` に `videoFileName` フィールドを追加。
2. `PoseFinder/App/DataSources/TrainingMenuDataSource.swift` を作成し、`TrainingMenuDataSource` Protocol を定義。
3. `PoseFinder/App/DataSources/TrainingMenuLocalDataSource.swift` を作成し、JSON からの読み込み実装。
   - `Resources/training-menus.json` をバンドルから読み込み
   - Codable で逆シリアライズ
   - `getVideoURL(for:)` で `Documents/PoseFinderTrainingMenus/videos/` から探索
4. `PoseFinder/App/Repositories/TrainingMenuRepository.swift` を作成し、Repository パターン実装。
   - Constructor で `dataSource` 依存性を受け取る
   - 公開 method `getTrainingMenus() async throws -> [TrainingMenu]`

### フェーズ2: UI層変更

5. `HomeViewModel.swift` を修正。
   - `TrainingMenuRepository` をプロパティとして保持
   - `init()` で Repository を初期化（LocalDataSource 使用）
   - `@Published menus` の読み込みを非同期化（Task で実施）
   - エラーハンドリング追加

6. `HomeView.swift` をローディング状態に対応（オプション）。

7. `TrainingMenuDetailView.swift` に参考動画プレイヤーを追加。
   - `AVPlayer` を使用（音声なし、自動再生）

### フェーズ3: リソース配置

8. `Resources/training-menus.json` を配置（初期データ: 既存 3 メニュー）。

9. `Resources/videos/` を作成し、サンプル MP4 を配置（オプション）。

10. Xcode ビルドフェーズ `Copy Bundle Resources` で JSON / mp4 が含まれることを確認。

11. Documents ディレクトリへのコピー処理（AppDelegate または SceneDelegate）。
    - 初回起動時（またはアプリ更新時）に `Resources/training-menus.json` を `Documents/PoseFinderTrainingMenus/` にコピー
    - 動画も同様にコピー

### フェーズ4: テスト & 検証

12. Mock DataSource を作成し、ユニットテスト実装。
    - `MockTrainingMenuDataSource` で定義済みデータを返す
    - Repository テスト: 正常系・エラー系をカバー

13. 手動テスト実装。
    - ビルド後、HomeView に 3 メニューが表示されることを確認
    - 詳細画面で動画が再生されることを確認
    - JSON を編集して再起動で反映されることを確認

### フェーズ5: ドキュメント & ADR

14. `docs/adr/0009-2026-03-03-training-menu-datasource-abstraction.md` を作成。
    - 決定: Protocol ベース + Repository パターン
    - 理由: リモートデータソース切り替えを見越した DI 設計
    - 代替案との比較
    - 将来の移行手順（REST API/Cloud DB への対応例）

15. `docs/specs/structure.md` に「トレーニングメニュー構成」セクションを追加。
    - DataSource → Repository → ViewModel のレイヤー図
    - データソース切り替えの手順（将来の参考）

16. `docs/specs/ui.md` に「トレーニングメニュー詳細画面に参考動画機能」を追記。

## 7. テスト計画 / 受入基準（Test Plan / Acceptance Criteria）

- **ユニット**
  - [ ] `TrainingMenuLocalDataSource.fetchTrainingMenus()` が正常な配列を返す
  - [ ] JSON 構文エラー時に `throw` する
  - [ ] `getVideoURL(for:)` が正しい URL / nil を返す
  - [ ] Repository が DataSource のエラーをキャッチして適切に処理
  - [ ] Mock DataSource による疎結合テスト成功
- **手動**
  - [ ] HomeView に既存 3 メニュー表示
  - [ ] メニュー詳細画面で参考動画が再生（音無し）
  - [ ] 動画ファイルが見つからない場合、プレイヤーが表示されない（グレースフル）
  - [ ] JSON 再編集 + 再起動で新内容が反映
- **受入チェックリスト**
  - [ ] ユニット・手動テスト全て通過
  - [ ] Protocol/Repository/ViewModel 構成が ADR/specs に記載
  - [ ] リモートデータソース移行時の手順が docs/adr に記載
  - [ ] Impl Report 作成完了

## 8. ロールバック / リスク / 監視（Rollback, Risks, Monitoring）

- **ロールバック**:
  - コード: git revert or reset
  - リソース: 過去コミットに戻す
- **リスク**:
  - JSON 構文エラー → 起動時 throw → HomeView が空になる（対策: エラーハンドリング、UIに警告表示）
  - 動画ファイル不在 → プレイヤーが表示されない（対策: グレースフルな非表示）
  - ファイル名誤り / Target Membership 忘れ → バンドルから JSON が見つからない（対策: ビルドログで確認）
  - リモートデータソース移行時に DataSource インターフェースが変わる可能性 → 今回の Protocol は将来の要件に合わせて拡張予定（ADR に記載）
- **監視**:
  - 初回起動時のメニュー読み込み成功を analytics でトラッキング
  - エラー発生時はクラッシュレポートで追跡

## 9. 生成/更新すべきドキュメント（Artifacts to Produce）

- `docs/adr/0009-2026-03-03-training-menu-datasource-abstraction.md` ← **新規**
- `docs/specs/structure.md` - 「トレーニングメニューレイヤー構成」セクション追加
- `docs/specs/ui.md` - 「トレーニング詳細画面・参考動画機能」追記
- `docs/tasks/0008-20260303-training-menu-config/impl-report.md`

## 10. 参照（References）

- [AGENTS.md](AGENTS.md) - Repository パターン、Protocol ベース設計
- [RecordingSessionRepository.swift](PoseFinder/App/Repositories/RecordingSessionRepository.swift) - 既存 Repository 実装例
- [HomeViewModel.swift](PoseFinder/App/ViewModels/HomeViewModel.swift) - 現在の実装（修正対象）
- [TrainingMenu.swift](PoseFinder/App/Models/TrainingMenu.swift) - 既存 Model
- iOS DataSource パターン・Dependency Injection 関連ドキュメント
