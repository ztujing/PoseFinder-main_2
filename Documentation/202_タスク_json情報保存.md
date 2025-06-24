# タスク: 動画保存

- `prototype` ブランチから `mvp` ブランチ（例：`feature/mvp-record-session`）を切る
- `FileManager` で `Documents/Sessions/<sessionID>` フォルダを作成する処理を実装
- 録画開始時に新規セッションID（タイムスタンプ等）を生成し、上記フォルダを用意
- `AVAssetWriter`／`AVAssetWriterInput` をセットアップし、出力先を `…/video.mp4` に指定
- `VideoCapture` の `startCapturing()` 呼び出し直後に `AVAssetWriter.startWriting()` と `startSession(atSourceTime:)` を実行
- `videoCapture(_:didCaptureFrame:)` で受け取る `CMSampleBuffer`（または `CGImage`→`CVPixelBuffer`）を `AVAssetWriterInput.append(_:)` で書き込む
- 録画停止時に `AVAssetWriterInput.markAsFinished()` → `AVAssetWriter.finishWriting(completionHandler:)` を呼び出し、`video.mp4` を確定
- 保存完了後に、`Sessions/<sessionID>` フォルダ内に `video.mp4` が存在することを確認
- 動作確認後、変更をコミットして `mvp` ブランチにプッシュ





- 同じデリゲート内で、フレームの `CMTime` を取得し、現在の `Pose`（`Joint` 配列＋スコア）を構造体にまとめてメモリ上の配列に格納
- 録画停止後にメモリ上のフレームデータ配列を `JSONEncoder` でエンコードし、`…/pose.json` として書き出す
- 保存完了後に、`Sessions/<sessionID>` フォルダ内に `pose.json` が存在することを確認
- 動作確認後、変更をコミットして `mvp` ブランチにプッシュ



import Foundation

/// セッションIDを「yyyyMMdd-HHmmss」形式で生成
private func makeSessionID() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
}

/// セッション用ディレクトリを作成し、その URL を返す
/// - Returns: 作成したセッションディレクトリの URL。失敗時は nil。
func createSessionDirectory() -> URL? {
    let fm = FileManager.default
    // ドキュメント直下の Sessions フォルダ
    guard let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("⚠️ ドキュメントディレクトリ取得失敗")
        return nil
    }
    let sessionsRoot = docsURL.appendingPathComponent("Sessions", isDirectory: true)

    do {
        // Sessions フォルダがなければ作成
        if !fm.fileExists(atPath: sessionsRoot.path) {
            try fm.createDirectory(at: sessionsRoot, withIntermediateDirectories: true, attributes: nil)
        }

        // 個別セッションフォルダを作成
        let sessionID = makeSessionID()
        let sessionDir = sessionsRoot.appendingPathComponent(sessionID, isDirectory: true)
        try fm.createDirectory(at: sessionDir, withIntermediateDirectories: true, attributes: nil)

        return sessionDir
    } catch {
        print("❌ セッションディレクトリ作成エラー: \(error)")
        return nil
    }
}


import UIKit
import AVFoundation

class ViewController: UIViewController {
    // VideoCapture 既存プロパティ
    private let videoCapture = VideoCapture()
    private var sessionDirectory: URL?

    // 追加：録画用の MovieFileOutput
    private let movieFileOutput = AVCaptureMovieFileOutput()

    override func viewDidLoad() {
        super.viewDidLoad()

        // セッションディレクトリ作成
        guard let dir = createSessionDirectory() else {
            fatalError("セッションディレクトリの作成に失敗しました")
        }
        sessionDirectory = dir

        // キャプチャ＆録画開始
        setupAndBeginCapturingVideoFrames()
    }

    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }

            // 1. VideoCapture のデリゲート設定
            self.videoCapture.delegate = self

            // 2. 録画出力をセッションに追加
            if let captureSession = self.videoCapture.captureSession,
               captureSession.canAddOutput(self.movieFileOutput) {
                captureSession.addOutput(self.movieFileOutput)
            }

            // 3. 録画ファイルの出力先 URL を生成
            if let sessionDir = self.sessionDirectory {
                let videoURL = sessionDir.appendingPathComponent("video.mp4")
                // 4. 録画開始
                self.movieFileOutput.startRecording(to: videoURL, recordingDelegate: self)
            }

            // 5. ライブキャプチャ開始
            self.videoCapture.startCapturing()
        }
    }
}

// MARK: - 録画完了ハンドリング
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("録画エラー: \(error)")
        } else {
            print("録画完了: \(outputFileURL.path)")
        }
        // ※JSON保存は録画停止後に行います（次ステップ）
    }
}

