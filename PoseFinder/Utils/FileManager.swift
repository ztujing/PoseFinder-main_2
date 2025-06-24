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
