# ADR-0009: トレーニングメニュー取得の DataSource 抽象化

- **Date**: 2026-03-03
- **Status**: Accepted
- **Authors**: @tujing
- **Related Artifacts**: [PLAN-0008](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/docs/tasks/0008-20260303-training-menu-config/plan.md), [IMPL-0008](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/docs/tasks/0008-20260303-training-menu-config/impl-report.md)

---

## 1. 背景（Context）

- トレーニングメニューが `TrainingMenu.sampleData` にハードコードされており、更新のたびに再ビルドが必要だった。
- 将来的にローカル JSON から REST API / Cloud DB へ切り替える計画があるため、取得経路を固定実装にしたくない。
- UI 層（`HomeViewModel` / `TrainingMenuDetailViewModel`）からデータ取得の詳細を分離し、テスト容易性を上げる必要があった。

## 2. 決定（Decision）

- 取得経路を `TrainingMenuDataSource` Protocol で抽象化し、`TrainingMenuRepository` 経由で ViewModel から利用する構成を採用する。
- 初期実装は `TrainingMenuLocalDataSource` とし、`Resources/training-menus.json` と Documents 配下の動画を読み込む。
- `TrainingMenuRepository` は DI で DataSource を受け取り、将来は `TrainingMenuRemoteDataSource` 実装へ差し替える。

## 3. 代替案と却下理由（Alternatives Considered）

- Singleton でローカル JSON を直接読む:
  - 利点: 実装量が少ない。
  - 欠点: 将来のリモート移行で大規模リファクタリングが発生しやすい。
  - 却下理由: 拡張性とテスト容易性が不足する。

- ViewModel から直接 JSON/API を読む:
  - 利点: 層を減らせる。
  - 欠点: ViewModel が肥大化し、データ取得責務が UI 層に漏れる。
  - 却下理由: 責務分離に反し、モック注入もしづらい。

- Plist ベース管理:
  - 利点: iOS 標準で扱いやすい。
  - 欠点: 外部連携/API との親和性が JSON より低い。
  - 却下理由: 将来の移行経路に不利。

## 4. 影響（Consequences）

- **Positive**:
  - データ取得経路の差し替えが `TrainingMenuRepository` 初期化時の DI で完結する。
  - ユニットテストで `MockDataSource` を使った検証が可能になる。
  - JSON 編集でメニュー内容の調整が可能になる。

- **Negative**:
  - 層が増えるため、初期実装とプロジェクト設定（pbxproj 管理）が複雑化する。
  - バンドル/ドキュメント間の同期（コピー戦略）を誤ると反映不整合が起きる。

- **運用影響**:
  - 起動時に `training-menus.json` と mp4 を Documents へコピーし、更新時は置換する運用を採用。

## 5. リスクと軽減策（Risks & Mitigations）

- JSON 構文不正やファイル欠落:
  - 軽減策: `fetchTrainingMenus()` でエラーを throw し、ViewModel 側でエラー状態を保持する。

- 動画ファイル不在:
  - 軽減策: `videoURL()` が `nil` を返した場合、UI はプレイヤーを非表示にする。

- リソース参照ずれ（Xcode 設定ミス）:
  - 軽減策: `Copy Bundle Resources` と build 成功確認を実施し、`xcodebuild` で検証する。

## 6. ロールアウト / モニタリング（Rollout & Monitoring）

- ロールアウト:
  - `TrainingMenuLocalDataSource` + `TrainingMenuRepository` を導入し、`HomeViewModel` / `TrainingMenuDetailViewModel` から利用。
  - 既存 UI の導線を維持したままデータ供給元を差し替える。

- モニタリング:
  - 手動確認で Documents 配下へのコピー結果を確認する。
  - ビルド確認（`xcodebuild`）を継続して参照不整合を早期検出する。

## 7. 参考資料（References）

- [TrainingMenuDataSource.swift](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/PoseFinder/App/DataSources/TrainingMenuDataSource.swift)
- [TrainingMenuLocalDataSource.swift](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/PoseFinder/App/DataSources/TrainingMenuLocalDataSource.swift)
- [TrainingMenuRepository.swift](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/PoseFinder/App/Repositories/TrainingMenuRepository.swift)
- [HomeViewModel.swift](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/PoseFinder/App/ViewModels/HomeViewModel.swift)
- [TrainingMenuDetailViewModel.swift](/Users/tujing/Dropbox/xcode_app/PoseFinder-main/PoseFinder/App/ViewModels/TrainingMenuDetailViewModel.swift)
