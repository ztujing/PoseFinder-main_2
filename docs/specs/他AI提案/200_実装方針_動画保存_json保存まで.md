## 実装方針

- `prototype` ブランチから `mvp` ブランチ（例：`feature/mvp-record-session`）を切る
- `FileManager` で `Documents/Sessions/<sessionID>` フォルダを作成する処理を実装
- 録画開始時に新規セッションID（タイムスタンプ等）を生成し、上記フォルダを用意
- `AVAssetWriter`／`AVAssetWriterInput` をセットアップし、出力先を `…/video.mp4` に指定
- `VideoCapture` の `startCapturing()` 呼び出し直後に `AVAssetWriter.startWriting()` と `startSession(atSourceTime:)` を実行
- `videoCapture(_:didCaptureFrame:)` で受け取る `CMSampleBuffer`（または `CGImage`→`CVPixelBuffer`）を `AVAssetWriterInput.append(_:)` で書き込む
- 同じデリゲート内で、フレームの `CMTime` を取得し、現在の `Pose`（`Joint` 配列＋スコア）を構造体にまとめてメモリ上の配列に格納
- 録画停止時に `AVAssetWriterInput.markAsFinished()` → `AVAssetWriter.finishWriting(completionHandler:)` を呼び出し、`video.mp4` を確定
- 録画停止後にメモリ上のフレームデータ配列を `JSONEncoder` でエンコードし、`…/pose.json` として書き出す
- 保存完了後に、`Sessions/<sessionID>` フォルダ内に `video.mp4` と `pose.json` が存在することを確認
- 実機またはシミュレータで動作検証し、正しくファイルが生成されることをテスト
- 動作確認後、変更をコミットして `mvp` ブランチにプッシュ

